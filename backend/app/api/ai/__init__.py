"""
AI模块API路由
包含智能体、工作流、知识库、插件等AI功能的API
"""
from fastapi import APIRouter

# 导入AI相关的路由
from .agents import router as agents_router
from .workflows import router as workflows_router
from .knowledge_bases import router as knowledge_bases_router
from .kb_documents import router as kb_documents_router
from .kb_search import router as kb_search_router
from .plugins import router as plugins_router
from .chat import router as chat_router
from .llm_models import router as llm_models_router
from .prompt_templates import router as prompt_templates_router
from .dashboard import router as dashboard_router

# 创建AI模块的主路由
router = APIRouter()

# 注册子路由
router.include_router(dashboard_router, prefix="/dashboard", tags=["AI-仪表盘"])
router.include_router(agents_router, prefix="/agents", tags=["AI-智能体"])
router.include_router(workflows_router, prefix="/workflows", tags=["AI-工作流"])
router.include_router(knowledge_bases_router, prefix="/knowledge-bases", tags=["AI-知识库"])
router.include_router(kb_documents_router, prefix="/kb-documents", tags=["AI-知识库文档"])
router.include_router(kb_search_router, prefix="/kb-search", tags=["AI-知识库搜索"])
router.include_router(plugins_router, prefix="/plugins", tags=["AI-插件"])
router.include_router(chat_router, prefix="/chat", tags=["AI-对话"])
router.include_router(llm_models_router, prefix="/llm-models", tags=["AI-LLM模型"])
router.include_router(prompt_templates_router, prefix="/prompt-templates", tags=["AI-提示词模板"])
