"""
LLM节点执行器
调用大模型生成文本
"""
import logging
import asyncio
from typing import Dict, Any, Callable, Optional
from sqlalchemy.orm import Session
from app.models.llm_model import LLMModel
from app.services.llm_service import LLMService

logger = logging.getLogger(__name__)


async def execute_llm_node(
    node_data: Dict[str, Any],
    execution_context: Dict[str, Any],
    replace_variables: Callable[[str], str],
    db_session: Optional[Session] = None
) -> Dict[str, Any]:
    """
    执行LLM节点
    
    Args:
        node_data: 节点配置数据，包含：
            - llmModel: 模型名称/ID
            - systemPrompt: 系统提示词
            - userPrompt: 用户提示词 (支持变量替换)
            - temperature: 温度参数
            - maxTokens: 最大Token数
            - topP: Top P
            - frequencyPenalty: 频率惩罚
            - presencePenalty: 存在惩罚
        execution_context: 执行上下文
        replace_variables: 变量替换函数
        db_session: 数据库会话
        
    Returns:
        Dict[str, Any]: 节点输出，包含：
            - response: 生成的文本
            - usage: Token使用量（如果有）
    """
    if not db_session:
        raise ValueError("LLM节点执行需要数据库会话")
    
    # 1. 获取并替换提示词
    system_prompt = node_data.get("systemPrompt", "")
    user_prompt = node_data.get("userPrompt", "")
    
    if not user_prompt:
        raise ValueError("LLM节点必须配置用户提示词")

    # 变量替换
    if system_prompt:
        system_prompt = replace_variables(system_prompt)
    user_prompt = replace_variables(user_prompt)

    # 2. 确定使用的模型配置
    llm_model_name = node_data.get("llmModel")
    
    llm_model = None
    if llm_model_name:
        # 指定了模型，查询特定模型
        llm_model = db_session.query(LLMModel).filter(
            (LLMModel.name == llm_model_name) | (LLMModel.uuid == llm_model_name)
        ).first()
        
        if not llm_model:
             raise ValueError(f"未找到指定的模型配置: {llm_model_name}，请确保在系统模型配置中已添加该模型")
    else:
        # 未指定模型，尝试使用系统默认模型
        logger.info("LLM节点未指定模型，尝试使用系统默认模型")
        # 1. 尝试获取设置了 is_default=1 的模型
        llm_model = db_session.query(LLMModel).filter(
            LLMModel.is_default == 1,
            LLMModel.is_active == 1
        ).first()
        
        # 2. 如果没有默认模型，获取第一个激活的模型作为兜底
        if not llm_model:
            llm_model = db_session.query(LLMModel).filter(
                LLMModel.is_active == 1
            ).order_by(LLMModel.sort_order.asc()).first()
            
        if not llm_model:
            raise ValueError("LLM节点未配置模型，且系统中无可用默认模型")
            
    logger.info(f"LLM节点使用模型: {llm_model.name} ({llm_model.display_name})")

    # 3. 构建消息
    messages = []
    if system_prompt:
        messages.append({"role": "system", "content": system_prompt})
    messages.append({"role": "user", "content": user_prompt})
    
    # 4. 准备调用参数 (覆盖模型默认参数)
    # 优先使用节点配置的参数，其次使用模型默认参数
    temp_temperature = node_data.get("temperature")
    temp_max_tokens = node_data.get("maxTokens")
    temp_top_p = node_data.get("topP")
    
    if temp_temperature is not None:
        llm_model.temperature = float(temp_temperature)
    if temp_max_tokens is not None:
        llm_model.max_tokens = int(temp_max_tokens)
    if temp_top_p is not None:
        llm_model.top_p = float(temp_top_p)
        
    # 5. 创建服务并调用
    llm_service = LLMService(llm_model)
    
    # 设置超时时间（默认60秒）
    timeout = node_data.get("timeout", 60)
    
    try:
        logger.info(f"正在执行LLM节点，使用模型: {llm_model.name}, Prompt长度: {len(user_prompt)}")
        
        # 调用LLM（使用asyncio.to_thread在异步环境中运行同步函数）
        result = await asyncio.wait_for(
            asyncio.to_thread(llm_service.chat, messages),
            timeout=timeout
        )
        
        output = {
            "response": result.get("response", ""),
            "usage": result.get("usage"),
            "function_call": result.get("function_call")
        }
        
        logger.info(f"LLM节点执行成功，生成文本长度: {len(output['response'])}")
        return output
        
    except asyncio.TimeoutError:
        raise TimeoutError(f"LLM节点执行超时（{timeout}秒）")
    except Exception as e:
        logger.error(f"LLM节点执行失败: {str(e)}", exc_info=True)
        raise
