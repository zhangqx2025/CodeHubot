"""
智能体对话 API 接口
"""

from typing import List, Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel, Field

from app.core.database import get_db
from app.models.agent import Agent
from app.models.plugin import Plugin
from app.models.llm_model import LLMModel
from app.models.device import Device
from app.api.auth import get_current_user
from app.models.user import User
from app.services.llm_service import create_llm_service
from app.services.plugin_service import PluginService

router = APIRouter()


# ============================================================================
# Pydantic Schemas
# ============================================================================

class ChatMessage(BaseModel):
    role: str = Field(..., description="角色: user, assistant, system")
    content: str = Field(..., description="消息内容")


class ChatRequest(BaseModel):
    agent_uuid: str = Field(..., description="智能体UUID")
    message: str = Field(..., description="用户消息")
    history: List[ChatMessage] = Field(default=[], description="历史消息")


class FunctionCall(BaseModel):
    name: str = Field(..., description="函数名称")
    arguments: Dict[str, Any] = Field(..., description="函数参数")


class PluginCallInfo(BaseModel):
    """插件调用信息"""
    plugin_name: str = Field(..., description="插件名称")
    function_name: str = Field(..., description="函数名称")
    arguments: Dict[str, Any] = Field(..., description="调用参数")
    result: str = Field(..., description="调用结果")


class TokenUsage(BaseModel):
    """Token使用量"""
    prompt_tokens: int = Field(..., description="输入Token数")
    completion_tokens: int = Field(..., description="输出Token数")
    total_tokens: int = Field(..., description="总Token数")


class ChatResponse(BaseModel):
    response: str = Field(..., description="智能体回复")
    function_call: Optional[FunctionCall] = None
    token_usage: Optional[TokenUsage] = Field(None, description="Token使用量")
    plugin_calls: Optional[List[PluginCallInfo]] = Field(default=[], description="插件调用信息")


class ChatDeviceResponse(BaseModel):
    """聊天页面设备响应模型（轻量级）"""
    uuid: str = Field(..., description="设备UUID")
    name: str = Field(..., description="设备名称")
    device_id: Optional[str] = Field(None, description="设备ID")
    is_online: bool = Field(..., description="是否在线")
    is_active: bool = Field(..., description="是否激活")
    
    class Config:
        from_attributes = True


# ============================================================================
# API Endpoints
# ============================================================================

@router.post("/", response_model=ChatResponse)
async def chat_with_agent(
    request: ChatRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    与智能体对话
    
    流程：
    1. 获取智能体配置（提示词、插件、模型）
    2. 解析插件为 Function Calling 格式
    3. 构建完整消息（系统提示词 + 历史消息 + 用户消息）
    4. 调用大模型获取回复
    5. 如果模型返回函数调用，执行函数并再次调用模型
    6. 返回最终回复
    """
    
    # 1. 获取智能体
    agent = db.query(Agent).filter(Agent.uuid == request.agent_uuid).first()
    if not agent:
        raise HTTPException(status_code=404, detail="智能体不存在")
    
    # 2. 获取智能体关联的插件
    plugins = []
    if agent.plugin_ids:
        try:
            plugin_ids = agent.plugin_ids if isinstance(agent.plugin_ids, list) else eval(agent.plugin_ids)
            plugins = db.query(Plugin).filter(
                Plugin.id.in_(plugin_ids),
                Plugin.is_active == 1
            ).all()
        except Exception as e:
            print(f"解析插件 ID 失败: {e}")
    
    # 3. 获取智能体关联的大模型
    llm_model = None
    if agent.llm_model_id:
        llm_model = db.query(LLMModel).filter(
            LLMModel.id == agent.llm_model_id,
            LLMModel.is_active == 1
        ).first()
    
    # 如果没有配置模型，使用默认模型
    if not llm_model:
        llm_model = db.query(LLMModel).filter(
            LLMModel.is_default == 1,
            LLMModel.is_active == 1
        ).first()
    
    if not llm_model:
        raise HTTPException(status_code=400, detail="未配置可用的大模型")
    
    # 4. 解析插件为 Function Calling 格式
    plugin_service = PluginService()
    functions = plugin_service.parse_openapi_to_functions(plugins)
    
    # 5. 构建消息列表
    messages = []
    
    # 添加系统提示词
    if agent.system_prompt:
        messages.append({
            "role": "system",
            "content": agent.system_prompt
        })
    
    # 添加插件能力说明
    if functions:
        function_descriptions = []
        for func in functions:
            func_desc = f"- {func['name']}: {func['description']}"
            function_descriptions.append(func_desc)
        
        plugin_prompt = (
            "\n\n你可以调用以下工具来帮助用户：\n" +
            "\n".join(function_descriptions) +
            "\n\n当需要使用工具时，请明确说明要调用哪个工具。"
        )
        
        if messages:
            messages[0]["content"] += plugin_prompt
        else:
            messages.append({
                "role": "system",
                "content": "你是一个智能助手。" + plugin_prompt
            })
    
    # 添加历史消息
    for msg in request.history:
        messages.append({
            "role": msg.role,
            "content": msg.content
        })
    
    # 添加当前用户消息
    messages.append({
        "role": "user",
        "content": request.message
    })
    
    # 6. 调用大模型
    llm_service = create_llm_service(llm_model)
    
    # 用于收集插件调用信息
    plugin_calls_info = []
    # 用于累计 token 使用量
    total_prompt_tokens = 0
    total_completion_tokens = 0
    total_tokens = 0
    
    try:
        # 首次调用
        result = llm_service.chat(
            messages=messages,
            functions=functions if functions else None,
            function_call="auto" if functions else None
        )
        
        # 累计第一次调用的 token
        if "usage" in result:
            usage = result["usage"]
            total_prompt_tokens += usage.get("prompt_tokens", 0)
            total_completion_tokens += usage.get("completion_tokens", 0)
            total_tokens += usage.get("total_tokens", 0)
        
        # 7. 处理函数调用
        if "function_call" in result:
            function_call = result["function_call"]
            function_name = function_call["name"]
            function_args = function_call["arguments"]
            
            # 查找插件名称
            plugin_name = "未知插件"
            for func in functions:
                if func.get("name") == function_name:
                    plugin_name = func.get("metadata", {}).get("plugin_name", "未知插件")
                    break
            
            # 执行函数
            function_result = plugin_service.call_function(
                function_name=function_name,
                arguments=function_args,
                functions=functions
            )
            
            # 记录插件调用信息
            plugin_calls_info.append(PluginCallInfo(
                plugin_name=plugin_name,
                function_name=function_name,
                arguments=function_args,
                result=plugin_service.format_function_result(function_result)
            ))
            
            # 将函数调用结果添加到消息历史
            # 注意：arguments 必须是 JSON 字符串，不能是对象
            import json
            messages.append({
                "role": "assistant",
                "content": None,
                "function_call": {
                    "name": function_name,
                    "arguments": json.dumps(function_args, ensure_ascii=False) if isinstance(function_args, dict) else function_args
                }
            })
            
            messages.append({
                "role": "function",
                "name": function_name,
                "content": plugin_service.format_function_result(function_result)
            })
            
            # 再次调用模型，让它基于函数结果生成回复
            result = llm_service.chat(messages=messages)
            
            # 累计第二次调用的 token
            if "usage" in result:
                usage = result["usage"]
                total_prompt_tokens += usage.get("prompt_tokens", 0)
                total_completion_tokens += usage.get("completion_tokens", 0)
                total_tokens += usage.get("total_tokens", 0)
        
        # 8. 返回回复
        token_usage = None
        if total_tokens > 0:
            token_usage = TokenUsage(
                prompt_tokens=total_prompt_tokens,
                completion_tokens=total_completion_tokens,
                total_tokens=total_tokens
            )
        
        response = ChatResponse(
            response=result.get("response", "抱歉，我现在无法回答这个问题。"),
            function_call=result.get("function_call"),
            token_usage=token_usage,
            plugin_calls=plugin_calls_info if plugin_calls_info else []
        )
        
        return response
    
    except Exception as e:
        print(f"调用大模型失败: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"调用大模型失败: {str(e)}"
        )


@router.get("/my-devices", response_model=List[ChatDeviceResponse])
async def get_my_devices(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    获取当前用户的设备列表（轻量级，专用于聊天页面）
    
    只返回必要的字段：uuid、name、device_id、is_online、is_active
    用于聊天页面的设备选择下拉框
    """
    try:
        # 直接从数据库查询用户的设备
        devices = db.query(Device).filter(
            Device.user_id == current_user.id,
            Device.is_active == True
        ).order_by(
            Device.is_online.desc(),  # 在线设备优先
            Device.name.asc()          # 按名称排序
        ).all()
        
        return devices
    except Exception as e:
        print(f"获取设备列表失败: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"获取设备列表失败: {str(e)}"
        )

