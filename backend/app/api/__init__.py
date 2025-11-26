from fastapi import APIRouter
from app.api import auth, devices, users, products, dashboard, firmware, agents, plugins, llm_models, chat

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["认证"])
api_router.include_router(products.router, prefix="/products", tags=["产品管理"])
api_router.include_router(devices.router, prefix="/devices", tags=["设备管理"])
api_router.include_router(users.router, prefix="/users", tags=["用户管理"])
api_router.include_router(dashboard.router, prefix="/dashboard", tags=["仪表盘"])
api_router.include_router(firmware.router, prefix="/firmware", tags=["固件管理"])
api_router.include_router(agents.router, prefix="/agents", tags=["智能体管理"])
api_router.include_router(plugins.router, prefix="/plugins", tags=["插件管理"])
api_router.include_router(llm_models.router, prefix="/llm-models", tags=["模型配置"])
api_router.include_router(chat.router, prefix="/chat", tags=["智能体对话"])