"""
AIOT 插件后端服务
专门为外部插件提供设备操作服务
直接访问数据库和MQTT，不依赖主backend服务
"""

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from contextlib import asynccontextmanager
import logging
from datetime import datetime
import json
from sqlalchemy import create_engine, desc, Column, Integer, String, DateTime, Boolean, Text, JSON, text
from sqlalchemy.orm import sessionmaker, Session, declarative_base
import paho.mqtt.client as mqtt
import os
from dotenv import load_dotenv

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ============================================================
# 加载环境变量
# ============================================================

# 加载 .env 文件
env_file = os.path.join(os.path.dirname(__file__), '.env')
if os.path.exists(env_file):
    load_dotenv(env_file)
    logger.info(f"✅ 已加载配置文件: {env_file}")
else:
    logger.warning(f"⚠️  配置文件不存在: {env_file}")
    logger.warning(f"⚠️  将使用默认配置，请复制 env.example 为 .env 并修改配置")

# ============================================================
# 配置
# ============================================================

# 数据库配置（支持两种方式）
# 方式1：使用完整的 DATABASE_URL
DATABASE_URL = os.getenv("DATABASE_URL")

# 方式2：使用单独的配置项（如果 DATABASE_URL 未设置）
if not DATABASE_URL:
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_PORT = os.getenv("DB_PORT", "3306")
    DB_NAME = os.getenv("DB_NAME", "aiot")
    DB_USER = os.getenv("DB_USER", "aiot_user")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "password")
    
    # 检查是否使用默认密码
    if DB_PASSWORD == "password":
        logger.warning("⚠️  警告：正在使用默认密码 'password'，这不安全！")
        logger.warning("⚠️  请在 .env 文件中设置正确的 DB_PASSWORD")
    
    # 构建 DATABASE_URL
    DATABASE_URL = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# MQTT配置
MQTT_BROKER = os.getenv("MQTT_BROKER", "localhost")
MQTT_PORT = int(os.getenv("MQTT_PORT", "1883"))
MQTT_USERNAME = os.getenv("MQTT_USERNAME", "")
MQTT_PASSWORD = os.getenv("MQTT_PASSWORD", "")

# 服务配置
SERVICE_PORT = int(os.getenv("SERVICE_PORT", "9002"))  # 默认 9002（9001 被 MQTT WebSocket 占用）
SERVICE_HOST = os.getenv("SERVICE_HOST", "0.0.0.0")

# 显示配置信息
logger.info("=" * 60)
logger.info("  AIOT 插件后端服务配置")
logger.info("=" * 60)
logger.info(f"  服务地址: http://{SERVICE_HOST}:{SERVICE_PORT}")
logger.info("")

# 详细的数据库配置信息
logger.info("  📊 数据库配置:")
if os.getenv("DATABASE_URL"):
    logger.info("    配置方式: DATABASE_URL（完整连接字符串）")
else:
    logger.info("    配置方式: 单独配置项")
    
    # 检查是否从 .env 读取到了配置
    db_password_from_env = os.getenv('DB_PASSWORD')
    if db_password_from_env:
        logger.info(f"    DB_HOST = {os.getenv('DB_HOST', 'localhost')}")
        logger.info(f"    DB_PORT = {os.getenv('DB_PORT', '3306')}")
        logger.info(f"    DB_NAME = {os.getenv('DB_NAME', 'aiot')}")
        logger.info(f"    DB_USER = {os.getenv('DB_USER', 'aiot_user')}")
        password = db_password_from_env
        logger.info(f"    DB_PASSWORD = {'*' * len(password)} ({len(password)}字符)")
    else:
        logger.warning("    ⚠️  未从 .env 读取到数据库配置，使用默认值")
        logger.warning(f"    DB_HOST = {os.getenv('DB_HOST', 'localhost')} (默认)")
        logger.warning(f"    DB_PORT = {os.getenv('DB_PORT', '3306')} (默认)")
        logger.warning(f"    DB_NAME = {os.getenv('DB_NAME', 'aiot')} (默认)")
        logger.warning(f"    DB_USER = {os.getenv('DB_USER', 'aiot_user')} (默认)")
        password = 'password'
        logger.warning(f"    DB_PASSWORD = {'*' * len(password)} ({len(password)}字符) (默认 - 不安全！)")

# 显示最终的连接信息（隐藏密码）
if '@' in DATABASE_URL:
    db_info = DATABASE_URL.split('@')[1]  # 显示 host:port/db
    db_user = DATABASE_URL.split('://')[1].split(':')[0]  # 提取用户名
    logger.info(f"    连接地址: {db_user}@{db_info}")
else:
    logger.info("    状态: 未配置")

logger.info("")
logger.info(f"  📡 MQTT配置: {MQTT_BROKER}:{MQTT_PORT}")
if MQTT_USERNAME:
    logger.info(f"    认证模式: 用户名密码")
else:
    logger.info(f"    认证模式: 匿名访问")
logger.info("=" * 60 + "\n")

# ============================================================
# 数据库模型（简化版，只包含必要字段）
# ============================================================

Base = declarative_base()

class Device(Base):
    __tablename__ = "aiot_core_devices"
    
    id = Column(Integer, primary_key=True)
    uuid = Column(String(36), unique=True, nullable=False)
    device_id = Column(String(100), unique=True, nullable=False)
    name = Column(String(100))
    device_status = Column(String(50))
    is_online = Column(Boolean)
    is_active = Column(Boolean)

class InteractionLog(Base):
    __tablename__ = "aiot_interaction_logs"
    
    id = Column(Integer, primary_key=True)
    device_id = Column(String(100))
    interaction_type = Column(String(50))
    request_data = Column(JSON)
    response_data = Column(JSON)
    timestamp = Column(DateTime)

# ============================================================
# 数据库连接
# ============================================================

logger.info("🔄 正在连接数据库...")
try:
    engine = create_engine(DATABASE_URL, pool_pre_ping=True, pool_recycle=3600)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    
    # 测试连接
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
    
    logger.info("✅ 数据库连接成功")
except Exception as e:
    logger.error("=" * 60)
    logger.error("❌ 数据库连接失败")
    logger.error("=" * 60)
    logger.error(f"错误类型: {type(e).__name__}")
    logger.error(f"错误信息: {str(e)}")
    logger.error("")
    logger.error("💡 常见原因和解决方案：")
    logger.error("  1. 密码错误 → 检查 .env 中的 DB_PASSWORD")
    logger.error("  2. 数据库不存在 → 检查 DB_NAME 是否正确")
    logger.error("  3. 用户不存在 → 检查 DB_USER 是否正确")
    logger.error("  4. MySQL未运行 → 执行: sudo systemctl start mysql")
    logger.error("  5. 主机错误 → 检查 DB_HOST (Docker环境用容器名)")
    logger.error("")
    logger.error("🔍 快速诊断命令：")
    if not os.getenv("DATABASE_URL"):
        db_host = os.getenv('DB_HOST', 'localhost')
        db_port = os.getenv('DB_PORT', '3306')
        db_user = os.getenv('DB_USER', 'aiot_user')
        db_name = os.getenv('DB_NAME', 'aiot')
        logger.error(f"  mysql -h {db_host} -P {db_port} -u {db_user} -p {db_name}")
    logger.error("=" * 60)
    SessionLocal = None

def get_db():
    """获取数据库会话"""
    if SessionLocal is None:
        raise HTTPException(status_code=500, detail="数据库未连接")
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ============================================================
# MQTT 客户端
# ============================================================

class MQTTClient:
    def __init__(self):
        self.client = None
        self.connected = False
        
    def connect(self):
        """连接到MQTT服务器"""
        try:
            self.client = mqtt.Client()
            
            # 如果配置了用户名和密码，则使用认证；否则使用匿名访问
            if MQTT_USERNAME and MQTT_PASSWORD:
                self.client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
                logger.info("🔐 MQTT使用用户名密码认证")
            else:
                logger.info("🔓 MQTT使用匿名访问")
            
            self.client.on_connect = self._on_connect
            self.client.on_disconnect = self._on_disconnect
            
            self.client.connect(MQTT_BROKER, MQTT_PORT, 60)
            self.client.loop_start()
            
            logger.info("✅ MQTT连接成功")
        except Exception as e:
            logger.error(f"❌ MQTT连接失败: {e}")
    
    def _on_connect(self, client, userdata, flags, rc):
        if rc == 0:
            self.connected = True
            logger.info("MQTT已连接")
        else:
            logger.error(f"MQTT连接失败，代码: {rc}")
    
    def _on_disconnect(self, client, userdata, rc):
        self.connected = False
        logger.warning("MQTT连接断开")
    
    def publish(self, topic: str, payload: dict):
        """发布MQTT消息"""
        if not self.connected:
            raise Exception("MQTT未连接")
        
        message = json.dumps(payload)
        result = self.client.publish(topic, message, qos=1)
        
        if result.rc != mqtt.MQTT_ERR_SUCCESS:
            raise Exception(f"MQTT发布失败: {result.rc}")
        
        logger.info(f"📤 MQTT发布成功: {topic}")
        return True

mqtt_client = MQTTClient()

# ============================================================
# 生命周期管理
# ============================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    # 启动时
    logger.info("🚀 启动服务，连接 MQTT...")
    mqtt_client.connect()
    yield
    # 关闭时
    logger.info("👋 关闭服务，断开 MQTT...")
    if mqtt_client.client:
        mqtt_client.client.loop_stop()
        mqtt_client.client.disconnect()

# ============================================================
# FastAPI 应用
# ============================================================

app = FastAPI(
    title="AIOT 插件后端服务",
    description="为外部插件提供设备操作服务",
    version="1.0.0",
    lifespan=lifespan
)

# CORS配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================
# 数据模型
# ============================================================

class SensorDataRequest(BaseModel):
    device_uuid: str
    sensor: str

class ControlRequest(BaseModel):
    device_uuid: str
    port_type: str
    port_id: int
    action: str
    value: Optional[int] = None

class StandardResponse(BaseModel):
    code: int
    msg: str
    data: Any

# ============================================================
# API 接口
# ============================================================

@app.get("/")
async def root():
    return {
        "service": "AIOT 插件后端服务",
        "version": "1.0.0",
        "status": "running",
        "mqtt_connected": mqtt_client.connected
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "database": SessionLocal is not None,
        "mqtt": mqtt_client.connected
    }

@app.get("/api/sensor-data")
async def get_sensor_data(device_uuid: str, sensor: str):
    """获取传感器数据
    
    直接从数据库的 interaction_logs 表读取最新传感器数据
    """
    logger.info(f"📊 查询传感器数据: device_uuid={device_uuid}, sensor={sensor}")
    
    if SessionLocal is None:
        raise HTTPException(status_code=500, detail="数据库未连接")
    
    db = SessionLocal()
    try:
        # 查询设备
        device = db.query(Device).filter(Device.uuid == device_uuid).first()
        if not device:
            raise HTTPException(status_code=404, detail="设备不存在")
        
        # 从 interaction_logs 获取最新传感器数据
        logs = db.query(InteractionLog).filter(
            InteractionLog.device_id == device.device_id,
            InteractionLog.interaction_type == "data_upload"
        ).order_by(desc(InteractionLog.timestamp)).limit(20).all()
        
        if not logs:
            raise HTTPException(status_code=404, detail="暂无传感器数据")
        
        # 提取传感器数据
        sensor_data = {}
        for log in logs:
            if log.request_data:
                raw_data = log.request_data
                sensor_type = raw_data.get("sensor")
                
                if sensor_type == "DHT11":
                    if "DHT11_temperature" not in sensor_data and "temperature" in raw_data:
                        sensor_data["DHT11_temperature"] = raw_data["temperature"]
                    if "DHT11_humidity" not in sensor_data and "humidity" in raw_data:
                        sensor_data["DHT11_humidity"] = raw_data["humidity"]
                elif sensor_type == "DS18B20":
                    if "DS18B20_temperature" not in sensor_data and "temperature" in raw_data:
                        sensor_data["DS18B20_temperature"] = raw_data["temperature"]
                elif sensor_type == "RAIN_SENSOR":
                    if "RAIN_SENSOR" not in sensor_data and "is_raining" in raw_data:
                        sensor_data["RAIN_SENSOR"] = raw_data["is_raining"]
        
        # 映射传感器名称
        sensor_map = {
            "温度": "DHT11_temperature",
            "temperature": "DHT11_temperature",
            "湿度": "DHT11_humidity",
            "humidity": "DHT11_humidity",
            "DS18B20": "DS18B20_temperature",
            "雨水": "RAIN_SENSOR"
        }
        
        actual_key = sensor_map.get(sensor, sensor)
        value = sensor_data.get(actual_key)
        
        if value is None:
            raise HTTPException(
                status_code=404,
                detail=f"未找到传感器 '{sensor}' 的数据"
            )
        
        # 确定单位
        unit = ""
        if "temperature" in actual_key.lower():
            unit = "°C"
        elif "humidity" in actual_key.lower():
            unit = "%"
        
        logger.info(f"✅ 传感器数据: {sensor}={value}{unit}")
        
        return StandardResponse(
            code=200,
            msg="成功",
            data={"value": value, "unit": unit}
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ 查询传感器数据失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()

@app.post("/api/control")
async def control_device(request: ControlRequest):
    """控制设备
    
    通过MQTT发送控制命令到设备
    """
    logger.info(f"🎮 控制设备: uuid={request.device_uuid}, "
                f"port={request.port_type}{request.port_id}, action={request.action}")
    
    if SessionLocal is None:
        raise HTTPException(status_code=500, detail="数据库未连接")
    
    if not mqtt_client.connected:
        raise HTTPException(status_code=500, detail="MQTT未连接")
    
    db = SessionLocal()
    try:
        # 查询设备
        device = db.query(Device).filter(Device.uuid == request.device_uuid).first()
        if not device:
            raise HTTPException(status_code=404, detail="设备不存在")
        
        # 打印设备信息
        logger.info(f"📱 查询到设备信息:")
        logger.info(f"   UUID: {device.uuid}")
        logger.info(f"   Device ID: {device.device_id}")
        logger.info(f"   名称: {device.name}")
        logger.info(f"   在线状态: {device.is_online}")
        
        # 构造控制命令
        port_type_lower = request.port_type.lower()
        
        if port_type_lower == "led":
            control_cmd = {
                "cmd": "led",
                "device_id": request.port_id,
                "action": request.action
            }
        elif port_type_lower == "relay":
            control_cmd = {
                "cmd": "relay",
                "device_id": request.port_id,
                "action": request.action
            }
        elif port_type_lower == "servo":
            if request.action == "set" and request.value is not None:
                control_cmd = {
                    "cmd": "servo",
                    "device_id": request.port_id,
                    "action": "set",
                    "angle": request.value
                }
            else:
                raise HTTPException(status_code=400, detail="舵机控制需要指定angle值")
        elif port_type_lower == "pwm":
            if request.action == "set" and request.value is not None:
                control_cmd = {
                    "cmd": "pwm",
                    "device_id": request.port_id,
                    "action": "set",
                    "duty_cycle": request.value,
                    "frequency": 5000
                }
            else:
                raise HTTPException(status_code=400, detail="PWM控制需要指定duty_cycle值")
        else:
            raise HTTPException(status_code=400, detail=f"不支持的端口类型: {request.port_type}")
        
        # 发送MQTT命令
        topic = f"device/{device.device_id}/control"
        mqtt_client.publish(topic, control_cmd)
        
        logger.info(f"✅ 控制成功: {request.port_type}{request.port_id} -> {request.action}")
        
        return StandardResponse(
            code=200,
            msg="成功",
            data={"result": "success"}
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ 控制设备失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=SERVICE_HOST, port=SERVICE_PORT)

