"""
AIOT 外部插件服务配置
支持从环境变量或.env文件加载配置
"""

import os
from typing import Optional

# 尝试加载 python-dotenv
try:
    from dotenv import load_dotenv
    # 加载.env文件
    load_dotenv()
    print("✅ 已加载 .env 配置文件")
except ImportError:
    print("ℹ️  未安装 python-dotenv，将使用默认配置")
except Exception as e:
    print(f"⚠️  加载 .env 文件失败: {e}")


class Config:
    """配置类"""
    
    # ==================== 服务配置 ====================
    
    # 服务端口
    PORT: int = int(os.getenv("PORT", "9000"))
    
    # 服务主机地址
    HOST: str = os.getenv("HOST", "0.0.0.0")
    
    # 日志级别
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO").upper()
    
    # 是否启用自动重载
    RELOAD: bool = os.getenv("RELOAD", "true").lower() == "true"
    
    # ==================== 后端服务配置 ====================
    
    # 后端API服务地址
    BACKEND_URL: str = os.getenv("BACKEND_URL", "http://localhost:8000")
    
    # 后端API密钥（可选）
    BACKEND_API_KEY: Optional[str] = os.getenv("BACKEND_API_KEY")
    
    # ==================== 安全配置 ====================
    
    # 是否启用CORS
    CORS_ENABLED: bool = os.getenv("CORS_ENABLED", "true").lower() == "true"
    
    # 允许的来源
    CORS_ORIGINS: str = os.getenv("CORS_ORIGINS", "*")
    
    # ==================== 其他配置 ====================
    
    # 请求超时时间（秒）
    REQUEST_TIMEOUT: int = int(os.getenv("REQUEST_TIMEOUT", "30"))
    
    # 调试模式
    DEBUG_MODE: bool = os.getenv("DEBUG_MODE", "true").lower() == "true"
    
    @classmethod
    def display(cls):
        """显示当前配置"""
        print("\n" + "=" * 60)
        print("  AIOT 外部插件服务配置")
        print("=" * 60)
        print(f"  服务地址: http://{cls.HOST}:{cls.PORT}")
        print(f"  后端地址: {cls.BACKEND_URL}")
        print(f"  日志级别: {cls.LOG_LEVEL}")
        print(f"  自动重载: {'启用' if cls.RELOAD else '禁用'}")
        print(f"  CORS: {'启用' if cls.CORS_ENABLED else '禁用'}")
        print(f"  调试模式: {'启用' if cls.DEBUG_MODE else '禁用'}")
        if cls.BACKEND_API_KEY:
            print(f"  API密钥: ***{cls.BACKEND_API_KEY[-4:]} ✅")
        else:
            print(f"  API密钥: ❌ 未配置（后端可能拒绝访问）")
        print("=" * 60 + "\n")


# 创建配置实例
config = Config()

