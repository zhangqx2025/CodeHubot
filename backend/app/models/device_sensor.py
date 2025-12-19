"""
设备传感器数据模型
"""
from sqlalchemy import Column, BigInteger, String, DateTime, Index
from sqlalchemy.sql import func
from app.core.database import Base


class DeviceSensor(Base):
    """设备传感器数据表"""
    __tablename__ = "device_sensors"
    
    id = Column(BigInteger, primary_key=True, autoincrement=True, comment="主键ID")
    device_uuid = Column(String(36), nullable=False, index=True, comment="设备UUID")
    sensor_name = Column(String(50), nullable=False, index=True, comment="传感器名称")
    sensor_value = Column(String(255), nullable=False, comment="传感器值")
    sensor_unit = Column(String(20), default="", comment="单位")
    sensor_type = Column(String(50), default="", comment="传感器类型")
    timestamp = Column(DateTime, nullable=False, index=True, comment="数据上报时间")
    created_at = Column(DateTime, server_default=func.now(), comment="记录创建时间")
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now(), comment="记录更新时间")
    
    # 唯一约束：device_uuid + sensor_name
    __table_args__ = (
        Index('uk_device_sensor', 'device_uuid', 'sensor_name', unique=True),
        {'comment': '设备传感器数据表'}
    )
    
    def to_dict(self):
        """转换为字典"""
        return {
            "id": self.id,
            "device_uuid": self.device_uuid,
            "sensor_name": self.sensor_name,
            "sensor_value": self.sensor_value,
            "sensor_unit": self.sensor_unit,
            "sensor_type": self.sensor_type,
            "timestamp": self.timestamp.isoformat() if self.timestamp else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None
        }
