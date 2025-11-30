from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError, HTTPException
from contextlib import asynccontextmanager
from app.api import api_router
from app.core.config import settings
from app.core.database import engine
from app.core.response import StandardResponse, ErrorResponse, success_response, error_response
from app.models import user, device, product, firmware
from app.services.mqtt_service import mqtt_service
import logging
import os
from datetime import datetime
from typing import Any

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 自定义JSONResponse类，确保datetime带有UTC标识
class CustomJSONResponse(JSONResponse):
    def render(self, content: Any) -> bytes:
        """重写render方法，自定义datetime序列化"""
        def custom_encoder(obj):
            if isinstance(obj, datetime):
                # 添加Z后缀表示UTC时间
                iso_str = obj.isoformat()
                return iso_str + 'Z' if not iso_str.endswith('Z') and '+' not in iso_str else iso_str
            return obj
        
        # 递归处理所有datetime对象
        def process_content(data):
            if isinstance(data, dict):
                return {k: process_content(v) for k, v in data.items()}
            elif isinstance(data, list):
                return [process_content(item) for item in data]
            elif isinstance(data, datetime):
                return custom_encoder(data)
            else:
                return data
        
        processed_content = process_content(content)
        return super().render(processed_content)

# 创建数据库表
# 注意：需要先导入所有模型，SQLAlchemy会自动处理外键依赖关系
from app.models import school, course_model, device_group, knowledge_base, document, kb_analytics  # 导入所有模型
user.Base.metadata.create_all(bind=engine)
device.Base.metadata.create_all(bind=engine)
product.Base.metadata.create_all(bind=engine)
firmware.Base.metadata.create_all(bind=engine)
school.Base.metadata.create_all(bind=engine)
course_model.Base.metadata.create_all(bind=engine)
device_group.Base.metadata.create_all(bind=engine)
knowledge_base.Base.metadata.create_all(bind=engine)
document.Base.metadata.create_all(bind=engine)
kb_analytics.Base.metadata.create_all(bind=engine)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # 应用启动时
    logger.info("🚀 启动物联网设备服务系统")
    
    # 启动MQTT客户端服务
    mqtt_service.start()
    
    yield
    
    # 应用关闭时
    logger.info("🛑 关闭物联网设备服务系统")
    mqtt_service.stop()

app = FastAPI(
    title="物联网设备服务系统",
    description="一个开源的物联网设备管理平台",
    version="1.0.0",
    lifespan=lifespan,
    default_response_class=CustomJSONResponse  # 使用自定义JSONResponse
    # 注意：FastAPI默认会自动处理尾部斜杠重定向
)

# CORS中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:3001"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 统一响应格式中间件
from starlette.responses import StreamingResponse
import json

@app.middleware("http")
async def response_middleware(request: Request, call_next):
    """统一响应格式中间件，自动包装所有响应"""
    # 跳过静态文件、文档和健康检查端点
    skip_paths = ["/static", "/docs", "/openapi.json", "/redoc"]
    if any(request.url.path.startswith(path) for path in skip_paths) or request.url.path in ["/", "/health"]:
        response = await call_next(request)
        return response
    
    response = await call_next(request)
    
    # 只处理成功的 JSON 响应（200-299）
    if 200 <= response.status_code < 300:
        # 检查 content-type 是否为 JSON
        content_type = response.headers.get("content-type", "")
        is_json = "application/json" in content_type or isinstance(response, JSONResponse)
        
        if is_json:
            # 读取响应体
            body = b""
            async for chunk in response.body_iterator:
                body += chunk
            
            try:
                # 解析 JSON
                data = json.loads(body.decode('utf-8'))
                
                # 准备新的响应头（移除 Content-Length，让 FastAPI 自动计算）
                new_headers = dict(response.headers)
                new_headers.pop("content-length", None)  # 移除旧的 Content-Length
                
                # 如果响应已经是标准格式（有 code 字段），直接返回
                if isinstance(data, dict) and "code" in data:
                    # 重新创建响应
                    return CustomJSONResponse(
                        content=data,
                        status_code=response.status_code,
                        headers=new_headers
                    )
                
                # 包装为标准格式
                wrapped_data = success_response(data=data, message="操作成功")
                return CustomJSONResponse(
                    content=wrapped_data,  # wrapped_data 已经是字典
                    status_code=response.status_code,
                    headers=new_headers
                )
            except (json.JSONDecodeError, UnicodeDecodeError, AttributeError) as e:
                # 如果不是 JSON 或解析失败，返回原响应
                logger.warning(f"响应解析失败: {e}, 路径: {request.url.path}")
                return response
    
    return response

# 全局异常处理器
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """HTTP 异常处理器，统一错误响应格式"""
    # 跳过文档和静态文件
    skip_paths = ["/static", "/docs", "/openapi.json", "/redoc"]
    if any(request.url.path.startswith(path) for path in skip_paths) or request.url.path in ["/", "/health"]:
        return JSONResponse(
            status_code=exc.status_code,
            content={"detail": exc.detail}
        )
    
    error_resp = error_response(
        code=exc.status_code,
        message=exc.detail if isinstance(exc.detail, str) else "请求失败",
        detail=str(exc.detail) if not isinstance(exc.detail, str) else None
    )
    return JSONResponse(
        status_code=exc.status_code,
        content=error_resp  # error_resp 已经是字典
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """请求验证异常处理器"""
    error_resp = error_response(
        code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        message="请求参数验证失败",
        detail=str(exc.errors())
    )
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content=error_resp  # error_resp 已经是字典
    )

# 注册路由
app.include_router(api_router, prefix="/api")

# 挂载静态文件服务
static_dir = os.path.join(os.path.dirname(__file__), "static")
if os.path.exists(static_dir):
    app.mount("/static", StaticFiles(directory=static_dir), name="static")

@app.get("/")
async def root():
    return {"message": "物联网设备服务系统 API"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
