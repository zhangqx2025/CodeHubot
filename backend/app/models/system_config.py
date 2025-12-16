"""
系统配置模型
用于管理系统级别的配置项，包括模块启用状态等
"""
from sqlalchemy import Column, Integer, String, Boolean, Text, TIMESTAMP
from sqlalchemy.sql import func
from app.db.base_class import Base


class SystemConfig(Base):
    """系统配置表"""
    __tablename__ = "core_system_config"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True, comment="配置ID")
    config_key = Column(String(100), unique=True, nullable=False, index=True, comment="配置键")
    config_value = Column(Text, nullable=True, comment="配置值")
    config_type = Column(String(20), nullable=False, default="string", comment="配置类型: string, boolean, integer, json")
    description = Column(String(500), nullable=True, comment="配置描述")
    category = Column(String(50), nullable=False, default="system", comment="配置分类: system, module, feature等")
    is_public = Column(Boolean, nullable=False, default=False, comment="是否公开（前端可见）")
    created_at = Column(TIMESTAMP, nullable=False, server_default=func.now(), comment="创建时间")
    updated_at = Column(TIMESTAMP, nullable=False, server_default=func.now(), onupdate=func.now(), comment="更新时间")
    
    def __repr__(self):
        return f"<SystemConfig(key={self.config_key}, value={self.config_value})>"
