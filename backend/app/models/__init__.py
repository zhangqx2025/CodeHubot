from .user import User
from .product import Product
from .device import Device
from .agent import Agent
from .plugin import Plugin

# 确保所有模型都被导入，以便 SQLAlchemy 能够正确创建表结构
__all__ = ["User", "Product", "Device", "Agent", "Plugin"]