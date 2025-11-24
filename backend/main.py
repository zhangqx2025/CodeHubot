from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
from fastapi.encoders import jsonable_encoder
from contextlib import asynccontextmanager
from app.api import api_router
from app.core.config import settings
from app.core.database import engine
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
user.Base.metadata.create_all(bind=engine)
device.Base.metadata.create_all(bind=engine)
product.Base.metadata.create_all(bind=engine)
firmware.Base.metadata.create_all(bind=engine)

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
