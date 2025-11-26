"""
大模型调用服务
支持多种国产和国际大模型
"""

import json
import requests
from typing import List, Dict, Any, Optional
from app.models.llm_model import LLMModel


class LLMService:
    """大模型调用服务基类"""
    
    def __init__(self, model: LLMModel):
        self.model = model
        self.api_base = model.api_base
        self.api_key = model.api_key
        self.model_name = model.name
        self.temperature = float(model.temperature) if model.temperature else 0.7
        self.max_tokens = model.max_tokens or 4096
        self.top_p = float(model.top_p) if model.top_p else 0.9
    
    def chat(
        self,
        messages: List[Dict[str, str]],
        functions: Optional[List[Dict[str, Any]]] = None,
        function_call: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        发送聊天请求到大模型
        
        Args:
            messages: 消息列表 [{"role": "user/assistant/system", "content": "..."}]
            functions: 可用的函数列表（用于 Function Calling）
            function_call: 是否强制调用函数 ("auto", "none", {"name": "function_name"})
        
        Returns:
            {"response": "回复内容", "function_call": {...}}
        """
        provider = self.model.provider.lower()
        
        if provider == 'openai':
            return self._call_openai_api(messages, functions, function_call)
        elif provider == 'qwen':
            return self._call_qwen_api(messages, functions, function_call)
        elif provider == 'wenxin':
            return self._call_wenxin_api(messages, functions, function_call)
        elif provider == 'spark':
            return self._call_spark_api(messages, functions, function_call)
        elif provider == 'zhipu':
            return self._call_zhipu_api(messages, functions, function_call)
        elif provider == 'moonshot':
            return self._call_moonshot_api(messages, functions, function_call)
        elif provider == 'deepseek':
            return self._call_deepseek_api(messages, functions, function_call)
        elif provider == 'doubao':
            return self._call_doubao_api(messages, functions, function_call)
        else:
            raise ValueError(f"不支持的模型提供商: {provider}")
    
    def _call_openai_api(
        self,
        messages: List[Dict[str, str]],
        functions: Optional[List[Dict[str, Any]]] = None,
        function_call: Optional[str] = None
    ) -> Dict[str, Any]:
        """调用 OpenAI API"""
        url = f"{self.api_base}/chat/completions"
        
        payload = {
            "model": self.model_name,
            "messages": messages,
            "temperature": float(self.temperature) if self.temperature else 0.7,
            "max_tokens": int(self.max_tokens) if self.max_tokens else 2000,
            "top_p": float(self.top_p) if self.top_p else 0.9
        }
        
        if functions:
            payload["functions"] = functions
            payload["function_call"] = function_call or "auto"
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        response = requests.post(url, json=payload, headers=headers, timeout=60)
        response.raise_for_status()
        
        result = response.json()
        choice = result["choices"][0]
        message = choice["message"]
        
        output = {}
        if message.get("content"):
            output["response"] = message["content"]
        if message.get("function_call"):
            output["function_call"] = {
                "name": message["function_call"]["name"],
                "arguments": json.loads(message["function_call"]["arguments"])
            }
        
        return output
    
    def _call_qwen_api(
        self,
        messages: List[Dict[str, str]],
        functions: Optional[List[Dict[str, Any]]] = None,
        function_call: Optional[str] = None
    ) -> Dict[str, Any]:
        """调用阿里通义千问 API（兼容 OpenAI 格式）"""
        # 通义千问使用 DashScope SDK，这里使用 OpenAI 兼容接口
        # 自动修正旧的 API Base URL
        api_base = self.api_base or 'https://dashscope.aliyuncs.com/compatible-mode/v1'
        if 'dashscope.aliyuncs.com/api/' in api_base:
            # 自动替换为兼容模式
            api_base = 'https://dashscope.aliyuncs.com/compatible-mode/v1'
        url = f"{api_base}/chat/completions"
        
        payload = {
            "model": self.model_name,
            "messages": messages,
            "temperature": float(self.temperature) if self.temperature else 0.7,
            "max_tokens": int(self.max_tokens) if self.max_tokens else 2000,
            "top_p": float(self.top_p) if self.top_p else 0.9
        }
        
        if functions:
            # 通义千问支持 Function Calling
            payload["tools"] = [{"type": "function", "function": func} for func in functions]
            if function_call and function_call != "none":
                payload["tool_choice"] = "auto"
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        # 打印请求信息用于调试
        print(f"🔍 调用通义千问 API:")
        print(f"  URL: {url}")
        print(f"  Model: {self.model_name}")
        print(f"  Has Functions: {bool(functions)}")
        if functions:
            print(f"  Functions Count: {len(functions)}")
            import json
            print(f"  Functions: {json.dumps(functions, ensure_ascii=False, indent=2)}")
        
        response = requests.post(url, json=payload, headers=headers, timeout=60)
        
        # 如果请求失败，打印详细错误
        if response.status_code != 200:
            print(f"❌ API 调用失败:")
            print(f"  Status Code: {response.status_code}")
            print(f"  Response: {response.text}")
        
        response.raise_for_status()
        
        result = response.json()
        choice = result["choices"][0]
        message = choice["message"]
        
        output = {}
        if message.get("content"):
            output["response"] = message["content"]
        
        # 添加 token 使用量信息
        if "usage" in result:
            output["usage"] = result["usage"]
        
        if message.get("tool_calls"):
            # 转换为标准格式
            tool_call = message["tool_calls"][0]
            output["function_call"] = {
                "name": tool_call["function"]["name"],
                "arguments": json.loads(tool_call["function"]["arguments"])
            }
        
        return output
    
    def _call_wenxin_api(
        self,
        messages: List[Dict[str, str]],
        functions: Optional[List[Dict[str, Any]]] = None,
        function_call: Optional[str] = None
    ) -> Dict[str, Any]:
        """调用百度文心一言 API"""
        # 文心一言需要先获取 access_token
        # 简化实现：假设 api_key 是 access_token
        url = f"{self.api_base or 'https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat'}/{self.model_name}"
        
        payload = {
            "messages": messages,
            "temperature": float(self.temperature) if self.temperature else 0.7,
            "top_p": float(self.top_p) if self.top_p else 0.9
        }
        
        if functions:
            payload["functions"] = functions
        
        params = {"access_token": self.api_key}
        
        response = requests.post(url, json=payload, params=params, timeout=60)
        response.raise_for_status()
        
        result = response.json()
        
        output = {"response": result.get("result", "")}
        
        if result.get("function_call"):
            output["function_call"] = {
                "name": result["function_call"]["name"],
                "arguments": json.loads(result["function_call"]["arguments"])
            }
        
        return output
    
    def _call_spark_api(
        self,
        messages: List[Dict[str, str]],
        functions: Optional[List[Dict[str, Any]]] = None,
        function_call: Optional[str] = None
    ) -> Dict[str, Any]:
        """调用讯飞星火 API"""
        # 星火认知大模型需要 WebSocket 连接，这里简化实现
        # 实际使用应该使用官方 SDK
        raise NotImplementedError("讯飞星火 API 需要使用 WebSocket，请使用官方 SDK")
    
    def _call_zhipu_api(
        self,
        messages: List[Dict[str, str]],
        functions: Optional[List[Dict[str, Any]]] = None,
        function_call: Optional[str] = None
    ) -> Dict[str, Any]:
        """调用智谱 GLM API（兼容 OpenAI 格式）"""
        url = f"{self.api_base or 'https://open.bigmodel.cn/api/paas/v4'}/chat/completions"
        
        payload = {
            "model": self.model_name,
            "messages": messages,
            "temperature": float(self.temperature) if self.temperature else 0.7,
            "max_tokens": int(self.max_tokens) if self.max_tokens else 2000,
            "top_p": float(self.top_p) if self.top_p else 0.9
        }
        
        if functions:
            payload["tools"] = [{"type": "function", "function": func} for func in functions]
            if function_call and function_call != "none":
                payload["tool_choice"] = "auto"
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        response = requests.post(url, json=payload, headers=headers, timeout=60)
        response.raise_for_status()
        
        result = response.json()
        choice = result["choices"][0]
        message = choice["message"]
        
        output = {}
        if message.get("content"):
            output["response"] = message["content"]
        if message.get("tool_calls"):
            tool_call = message["tool_calls"][0]
            output["function_call"] = {
                "name": tool_call["function"]["name"],
                "arguments": json.loads(tool_call["function"]["arguments"])
            }
        
        return output
    
    def _call_moonshot_api(
        self,
        messages: List[Dict[str, str]],
        functions: Optional[List[Dict[str, Any]]] = None,
        function_call: Optional[str] = None
    ) -> Dict[str, Any]:
        """调用月之暗面 Kimi API（兼容 OpenAI 格式）"""
        return self._call_openai_api(messages, functions, function_call)
    
    def _call_deepseek_api(
        self,
        messages: List[Dict[str, str]],
        functions: Optional[List[Dict[str, Any]]] = None,
        function_call: Optional[str] = None
    ) -> Dict[str, Any]:
        """调用 DeepSeek API（兼容 OpenAI 格式）"""
        return self._call_openai_api(messages, functions, function_call)
    
    def _call_doubao_api(
        self,
        messages: List[Dict[str, str]],
        functions: Optional[List[Dict[str, Any]]] = None,
        function_call: Optional[str] = None
    ) -> Dict[str, Any]:
        """调用火山引擎豆包 API（OpenAI 兼容接口）"""
        # 火山引擎方舟平台使用 OpenAI 兼容的 API
        # API Base: https://ark.cn-beijing.volces.com/api/v3
        # 完整路径: https://ark.cn-beijing.volces.com/api/v3/chat/completions
        
        api_base = self.model.api_base or 'https://ark.cn-beijing.volces.com/api/v3'
        
        # 统一处理 API Base，确保没有尾部斜杠
        api_base = api_base.rstrip('/')
        
        # 构建完整 URL
        url = f"{api_base}/chat/completions"
        
        payload = {
            "model": self.model.name,
            "messages": messages,
            "temperature": float(self.model.temperature) if self.model.temperature else 0.7,
            "max_tokens": int(self.model.max_tokens) if self.model.max_tokens else 2000,
            "top_p": float(self.model.top_p) if self.model.top_p else 0.9
        }
        
        if functions:
            # 豆包支持 Function Calling，使用 tools 格式（OpenAI 新格式）
            payload["tools"] = [{"type": "function", "function": func} for func in functions]
            if function_call and function_call != "none":
                payload["tool_choice"] = "auto"
        
        headers = {
            "Authorization": f"Bearer {self.model.api_key}",
            "Content-Type": "application/json"
        }
        
        # 打印请求信息用于调试
        print(f"🔍 调用火山引擎豆包 API:")
        print(f"  原始 API Base: {self.model.api_base}")
        print(f"  处理后 API Base: {api_base}")
        print(f"  完整 URL: {url}")
        print(f"  Model Name: {self.model.name}")
        print(f"  API Key (前10位): {self.model.api_key[:10]}..." if self.model.api_key and len(self.model.api_key) > 10 else f"  API Key: {self.model.api_key}")
        print(f"  Messages Count: {len(messages)}")
        print(f"  Payload Model: {payload.get('model')}")
        if functions:
            print(f"  Functions Count: {len(functions)}")
        print(f"  完整 Payload: {json.dumps(payload, ensure_ascii=False, indent=2)}")
        
        try:
            response = requests.post(url, json=payload, headers=headers, timeout=60)
            
            # 如果请求失败，打印详细错误
            if response.status_code != 200:
                print(f"❌ API 调用失败:")
                print(f"  Status Code: {response.status_code}")
                print(f"  Response Headers: {dict(response.headers)}")
                print(f"  Response: {response.text}")
            
            response.raise_for_status()
            
            result = response.json()
            choice = result["choices"][0]
            message = choice["message"]
            
            output = {}
            if message.get("content"):
                output["response"] = message["content"]
            
            # 添加 token 使用量信息
            if "usage" in result:
                output["usage"] = result["usage"]
            
            if message.get("tool_calls"):
                # 转换为标准格式
                tool_call = message["tool_calls"][0]
                output["function_call"] = {
                    "name": tool_call["function"]["name"],
                    "arguments": json.loads(tool_call["function"]["arguments"])
                }
            
            return output
            
        except requests.exceptions.RequestException as e:
            print(f"❌ 请求异常:")
            print(f"  Error: {str(e)}")
            if hasattr(e, 'response') and e.response is not None:
                print(f"  Response Text: {e.response.text}")
            raise


def create_llm_service(model: LLMModel) -> LLMService:
    """创建 LLM 服务实例"""
    return LLMService(model)

