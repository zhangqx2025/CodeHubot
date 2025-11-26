"""
AIOT 外部插件服务
简单的API接口，用于外部插件（如Coze、GPT等）调用
只需设备UUID即可，无需token认证
"""

from fastapi import FastAPI, HTTPException, Request, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
import httpx
import logging
from datetime import datetime
from config import config

# 配置日志
logging.basicConfig(
    level=getattr(logging, config.LOG_LEVEL),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# 显示配置信息
config.display()

# ============================================================
# 调试模式配置
# ============================================================
# 测试UUID：当device_uuid为此值时，返回模拟数据
TEST_UUID = "test"

def is_test_mode(uuid: str) -> bool:
    """判断是否为测试模式"""
    return uuid.lower() == TEST_UUID

# 创建FastAPI应用
app = FastAPI(
    title="AIOT 外部插件服务",
    description="简洁的IoT设备控制API，供外部插件调用",
    version="1.0.0",
    debug=config.DEBUG_MODE
)

# 配置CORS
if config.CORS_ENABLED:
    # 处理CORS_ORIGINS配置
    origins = config.CORS_ORIGINS
    if origins == "*":
        allow_origins = ["*"]
    else:
        allow_origins = [origin.strip() for origin in origins.split(",")]
    
    app.add_middleware(
        CORSMiddleware,
        allow_origins=allow_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    logger.info(f"✅ CORS已启用，允许的来源: {allow_origins}")

# 插件后端服务地址（从配置读取）
PLUGIN_BACKEND_URL = config.PLUGIN_BACKEND_URL
# 保留用于兼容
BACKEND_URL = config.BACKEND_URL

# ==================== 全局异常处理器 ====================

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """统一处理 HTTPException，返回标准格式"""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "code": exc.status_code,
            "msg": "失败" if exc.status_code >= 400 else "成功",
            "data": {
                "error": exc.detail
            }
        }
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """统一处理所有未捕获的异常"""
    logger.error(f"未捕获的异常: {str(exc)}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "code": 500,
            "msg": "失败",
            "data": {
                "error": "服务器内部错误" if not config.DEBUG_MODE else str(exc)
            }
        }
    )

# ==================== 数据模型 ====================

class SensorDataResponse(BaseModel):
    """传感器数据响应"""
    device_uuid: str = Field(..., description="设备UUID")
    sensor_name: str = Field(..., description="传感器名称")
    value: float = Field(..., description="传感器数值")
    unit: str = Field(..., description="数值单位")
    timestamp: str = Field(..., description="读取时间")


class ControlRequest(BaseModel):
    """端口控制请求"""
    device_uuid: str = Field(..., description="UUID", example="test")
    port_type: str = Field(..., description="led/relay/servo/pwm", example="led")
    port_id: int = Field(..., description="1-4", example=1)
    action: str = Field(..., description="on/off/set", example="on")
    value: Optional[int] = Field(None, description="角度/占空比", example=90)


class PresetRequest(BaseModel):
    """预设指令请求"""
    device_uuid: str = Field(..., description="UUID", example="test")
    preset_name: str = Field(..., description="预设名", example="led_blink")
    parameters: Optional[Dict[str, Any]] = Field(default_factory=dict, description="参数")


class ControlResponse(BaseModel):
    """端口控制响应"""
    device_uuid: str = Field(..., description="设备UUID")
    port_type: str = Field(..., description="端口类型")
    port_id: int = Field(..., description="端口ID")
    action: str = Field(..., description="执行的动作")
    value: Optional[int] = Field(None, description="设置值")
    status: str = Field(..., description="执行状态")
    message: str = Field(..., description="执行结果消息")
    timestamp: str = Field(..., description="执行时间")


class PresetResponse(BaseModel):
    """预设指令响应"""
    device_uuid: str = Field(..., description="设备UUID")
    preset_name: str = Field(..., description="预设名称")
    device_type: str = Field(..., description="设备类型")
    device_id: int = Field(..., description="设备ID")
    parameters: Dict[str, Any] = Field(..., description="预设参数")
    status: str = Field(..., description="执行状态")
    message: str = Field(..., description="执行结果消息")
    timestamp: str = Field(..., description="执行时间")


class StandardResponse(BaseModel):
    """标准响应格式"""
    code: int = Field(..., description="状态码，200表示成功")
    msg: str = Field(..., description="响应消息")
    data: Any = Field(..., description="响应数据")


# ==================== 工具函数 ====================

def get_internal_headers() -> dict:
    """获取内部API调用的headers
    
    Returns:
        包含内部API密钥的headers字典
    """
    headers = {}
    if config.BACKEND_API_KEY:
        headers["X-Internal-API-Key"] = config.BACKEND_API_KEY
        logger.debug("🔑 使用内部API密钥")
    else:
        logger.warning("⚠️  未配置内部API密钥，后端可能拒绝访问")
    return headers


async def verify_device_exists(device_uuid: str) -> bool:
    """验证设备是否存在
    
    通过调用设备配置接口验证设备存在性
    该接口已支持内部API密钥认证
    """
    try:
        headers = get_internal_headers()
        url = f"{BACKEND_URL}/api/devices/{device_uuid}/config"
        logger.info(f"🔍 验证设备: {device_uuid}")
        logger.debug(f"🔗 请求URL: {url}")
        logger.debug(f"📋 请求头: {headers}")
        
        async with httpx.AsyncClient(timeout=10.0) as client:
            # 调用设备配置接口（已支持内部API密钥）
            response = await client.get(url, headers=headers)
            
            logger.info(f"📡 后端响应状态: {response.status_code}")
            
            # 200表示设备存在，404表示设备不存在
            if response.status_code == 200:
                logger.info(f"✅ 设备验证成功: {device_uuid}")
                return True
            elif response.status_code == 404:
                logger.warning(f"⚠️ 设备不存在(404): {device_uuid}")
                return False
            else:
                # 其他错误（如401认证失败）也返回False
                logger.error(f"❌ 验证设备时返回异常状态码 {response.status_code}: {response.text[:200]}")
                return False
    except httpx.TimeoutException as e:
        logger.error(f"❌ 验证设备超时: {e}, URL: {BACKEND_URL}")
        return False
    except httpx.ConnectError as e:
        logger.error(f"❌ 无法连接到后端服务: {e}, URL: {BACKEND_URL}")
        logger.error(f"💡 请检查: 1) 后端服务是否运行 2) BACKEND_URL配置是否正确")
                return False
    except Exception as e:
        logger.error(f"❌ 验证设备失败: {type(e).__name__}: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False


def map_sensor_key(sensor_name: str) -> str:
    """映射传感器名称到数据库键"""
    sensor_map = {
        "温度": "DHT11_temperature",
        "湿度": "DHT11_humidity",
        "temperature": "DHT11_temperature",
        "humidity": "DHT11_humidity",
        "DS18B20": "DS18B20_temperature",
        "DS18B20温度": "DS18B20_temperature",
        "雨水": "RAIN_SENSOR",
        "雨水传感器": "RAIN_SENSOR",
        "是否下雨": "RAIN_SENSOR",
        "rain": "RAIN_SENSOR",
        "雨水级别": "RAIN_SENSOR_level",
        "rain_level": "RAIN_SENSOR_level",
    }
    return sensor_map.get(sensor_name, sensor_name)


# ==================== API接口 ====================

@app.get("/", tags=["健康检查"])
async def root():
    """服务健康检查"""
    return {
        "service": "AIOT 外部插件服务",
        "version": "1.0.0",
        "status": "running",
        "timestamp": datetime.now().isoformat()
    }


@app.get("/plugin/device-aliases",
         response_model=StandardResponse,
         tags=["设备配置"],
         summary="获取设备别名配置")
async def get_device_aliases(
    uuid: str = Query(..., description="设备UUID")
):
    """获取设备别名配置"""
    logger.info(f"📋 获取设备别名配置: uuid={uuid}")
    
    # 🧪 测试模式：返回模拟别名配置
    if is_test_mode(uuid):
        logger.info(f"🧪 测试模式激活: 返回模拟别名配置")
        # 精简测试数据
        mock_aliases = {
            "control_aliases": {
                "客厅灯": {"port_type": "led", "port_id": 1},
                "卧室灯": {"port_type": "led", "port_id": 2},
                "风扇": {"port_type": "relay", "port_id": 1}
            },
            "preset_aliases": {
                "快速闪烁": {"preset_name": "led_blink", "parameters": {"count": 5}}
            }
        }
        
        return StandardResponse(
            code=200,
            msg="成功",
            data=mock_aliases
        )
    
    # 验证设备
    if not await verify_device_exists(uuid):
        logger.warning(f"❌ 设备不存在: {uuid}")
        raise HTTPException(status_code=404, detail=f"设备 {uuid} 不存在")
    
    try:
        # 调用后端API获取设备配置（使用内部API密钥）
        headers = get_internal_headers()
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(
                f"{BACKEND_URL}/api/devices/{uuid}/config",
                headers=headers
            )
            
            if response.status_code == 401 or response.status_code == 403:
                # 认证失败
                logger.error(f"❌ 后端API认证失败: {response.status_code}")
                raise HTTPException(
                    status_code=500, 
                    detail="后端API认证失败，请检查BACKEND_API_KEY配置"
                )
            
            if response.status_code != 200:
                raise HTTPException(status_code=500, detail="获取设备配置失败")
            
            response_data = response.json()
            
            # 后端使用统一响应格式，需要提取 data 字段
            config_data = response_data
            if isinstance(response_data, dict) and "data" in response_data:
                config_data = response_data.get("data", {})
                logger.info(f"📦 从统一响应格式中提取 config data")
            
            # 提取控制端口别名
            control_aliases = {}
            device_control_config = config_data.get("device_control_config", {})
            
            for port_key, port_config in device_control_config.items():
                if isinstance(port_config, dict) and port_config.get("alias"):
                    # 解析端口key，如 "led_1" -> {type: "led", id: 1}
                    parts = port_key.split("_")
                    if len(parts) >= 2:
                        port_type = parts[0]
                        try:
                            port_id = int(parts[1])
                            alias = port_config["alias"]
                            
                            control_aliases[alias] = {
                                "port_type": port_type,
                                "port_id": port_id
                            }
                        except (ValueError, IndexError):
                            continue
            
            # 提取预设指令别名
            preset_aliases = {}
            device_preset_commands = config_data.get("device_preset_commands", [])
            
            for preset in device_preset_commands:
                if preset.get("alias"):
                    alias = preset["alias"]
                    preset_aliases[alias] = {
                        "preset_name": preset.get("preset_name", ""),
                        "parameters": preset.get("parameters", {})
                    }
            
            logger.info(f"✅ 设备别名配置: {len(control_aliases)}个端口别名, {len(preset_aliases)}个预设别名")
            
            # 精简返回数据：只保留必要的映射信息
            simplified_control_aliases = {}
            for alias, config in control_aliases.items():
                simplified_control_aliases[alias] = {
                    "port_type": config["port_type"],
                    "port_id": config["port_id"]
                }
            
            simplified_preset_aliases = {}
            for alias, config in preset_aliases.items():
                simplified_preset_aliases[alias] = {
                    "preset_name": config["preset_name"],
                    "parameters": config.get("parameters", {})
                }
            
            return StandardResponse(
                code=200,
                msg="成功",
                data={
                    "control_aliases": simplified_control_aliases,
                    "preset_aliases": simplified_preset_aliases
                }
            )
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ 获取设备别名配置失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/plugin/sensor-data", 
         response_model=StandardResponse,
         tags=["传感器"],
         summary="获取传感器数据")
async def get_sensor_data(
    uuid: str = Query(..., description="UUID"),
    sensor: str = Query(..., description="温度/湿度/DS18B20/雨水/雨水级别"),
    raw_request: Request = None
):
    """获取传感器数据。sensor: 温度/湿度/DS18B20/雨水/雨水级别"""
    # 打印详细的请求信息
    logger.info("=" * 80)
    logger.info("📥 插件服务接收到传感器查询请求")
    logger.info(f"🔹 请求URL: {raw_request.url if raw_request else 'N/A'}")
    logger.info(f"🔹 请求方法: {raw_request.method if raw_request else 'GET'}")
    logger.info(f"🔹 客户端IP: {raw_request.client.host if raw_request and raw_request.client else 'Unknown'}")
    logger.info(f"🔹 User-Agent: {raw_request.headers.get('user-agent', 'Unknown') if raw_request else 'Unknown'}")
    logger.info(f"🔹 查询参数:")
    logger.info(f"   - uuid: {uuid}")
    logger.info(f"   - sensor: {sensor}")
    logger.info(f"🔹 当前 BACKEND_URL: {BACKEND_URL}")
    logger.info(f"🔹 时间戳: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    logger.info("=" * 80)
    
    logger.info(f"📊 获取传感器数据: uuid={uuid}, sensor={sensor}")
    
    # 🧪 测试模式：返回模拟数据
    if is_test_mode(uuid):
        logger.info(f"🧪 测试模式激活: 返回模拟传感器数据")
        # 模拟传感器数据
        mock_values = {
            "温度": 24.5,
            "temperature": 24.5,
            "湿度": 65.0,
            "humidity": 65.0,
            "DS18B20": 23.8,
            "DS18B20温度": 23.8,
            "雨水": False,
            "雨水传感器": False,
            "是否下雨": False,
            "rain": False,
            "雨水级别": 120,
            "rain_level": 120
        }
        
        value = mock_values.get(sensor, 25.0)
        # 确定单位
        if "温度" in sensor or "temperature" in sensor.lower() or "DS18B20" in sensor:
            unit = "°C"
        elif "湿度" in sensor or "humidity" in sensor.lower():
            unit = "%"
        elif "级别" in sensor or "level" in sensor.lower():
            unit = "级"
        elif "雨水" in sensor or "rain" in sensor.lower():
            unit = ""
        else:
            unit = "%"
        
        result = SensorDataResponse(
            device_uuid=uuid,
            sensor_name=sensor,
            value=value,
            unit=unit,
            timestamp=datetime.now().strftime("%Y-%m-%dT%H:%M:%S+08:00")
        )
        
        # 精简返回：只返回核心数据
        return StandardResponse(
            code=200,
            msg="成功",
            data={
                "value": result.value,
                "unit": result.unit
            }
        )
    
    try:
        # 调用插件后端服务获取传感器数据
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(
                f"{PLUGIN_BACKEND_URL}/api/sensor-data",
                params={"device_uuid": uuid, "sensor": sensor}
            )
            
            if response.status_code == 404:
                raise HTTPException(status_code=404, detail="设备不存在或暂无传感器数据")
            
            if response.status_code != 200:
                error_msg = response.text if response.text else "获取传感器数据失败"
                raise HTTPException(status_code=response.status_code, detail=error_msg)
            
            response_data = response.json()
            
            # plugin-backend-service 返回格式：
            # {"code": 200, "msg": "成功", "data": {"value": 30.4, "unit": "°C"}}
            
            if not isinstance(response_data, dict):
                logger.error(f"❌ 未知的响应格式: {type(response_data)}")
                raise HTTPException(status_code=500, detail="后端返回数据格式错误")
            
            # 提取数据
            data = response_data.get("data", {})
            value = data.get("value")
            unit = data.get("unit", "")
            
            if value is None:
                raise HTTPException(status_code=404, detail=f"未找到传感器 '{sensor}' 的数据")
            
            logger.info(f"✅ 传感器数据: {sensor}={value}{unit}")
            
            # 精简返回：只返回核心数据
            return StandardResponse(
                code=200,
                msg="成功",
                data={
                    "value": value,
                    "unit": unit
                }
            )
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ 获取传感器数据失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/plugin/control",
          response_model=StandardResponse,
          tags=["控制"],
          summary="控制设备端口")
async def control_device(request: ControlRequest, raw_request: Request):
    """控制设备。port_type: led/relay/servo/pwm, action: on/off/set"""
    # 打印详细的请求信息
    logger.info("=" * 80)
    logger.info("📥 插件服务接收到控制请求")
    logger.info(f"🔹 请求URL: {raw_request.url}")
    logger.info(f"🔹 请求方法: {raw_request.method}")
    logger.info(f"🔹 客户端IP: {raw_request.client.host if raw_request.client else 'Unknown'}")
    logger.info(f"🔹 User-Agent: {raw_request.headers.get('user-agent', 'Unknown')}")
    logger.info(f"🔹 Content-Type: {raw_request.headers.get('content-type', 'Unknown')}")
    logger.info(f"🔹 请求体参数:")
    logger.info(f"   - device_uuid: {request.device_uuid}")
    logger.info(f"   - port_type: {request.port_type}")
    logger.info(f"   - port_id: {request.port_id}")
    logger.info(f"   - action: {request.action}")
    logger.info(f"   - value: {request.value}")
    logger.info(f"🔹 当前 BACKEND_URL: {BACKEND_URL}")
    logger.info(f"🔹 时间戳: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    logger.info("=" * 80)
    
    logger.info(f"🎮 控制设备: uuid={request.device_uuid}, "
                f"port={request.port_type}{request.port_id}, action={request.action}")
    
    # 🧪 测试模式：返回模拟成功响应
    if is_test_mode(request.device_uuid):
        logger.info(f"🧪 测试模式激活: 模拟控制设备成功")
        result = ControlResponse(
            device_uuid=request.device_uuid,
            port_type=request.port_type,
            port_id=request.port_id,
            action=request.action,
            value=request.value,
            status="success",
            message=f"测试模式：{request.port_type}{request.port_id}已{request.action}",
            timestamp=datetime.now().strftime("%Y-%m-%dT%H:%M:%S+08:00")
        )
        
        # 精简返回：只返回结果
        return StandardResponse(
            code=200,
            msg="成功",
            data={"result": "success"}
        )
    
    try:
        # 调用插件后端服务控制设备
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(
                f"{PLUGIN_BACKEND_URL}/api/control",
                json={
                    "device_uuid": request.device_uuid,
                    "port_type": request.port_type,
                    "port_id": request.port_id,
                    "action": request.action,
                    "value": request.value
                }
            )
            
            if response.status_code == 404:
                raise HTTPException(status_code=404, detail="设备不存在")
            
            if response.status_code != 200:
                error_detail = response.text if response.text else "控制失败"
                raise HTTPException(status_code=response.status_code, detail=error_detail)
            
            logger.info(f"✅ 控制成功: {request.port_type}{request.port_id} -> {request.action}")
            
            # 精简返回：只返回结果
            return StandardResponse(
                code=200,
                msg="成功",
                data={"result": "success"}
            )
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ 控制失败: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/plugin/preset",
          response_model=StandardResponse,
          tags=["预设"],
          summary="执行预设指令")
async def execute_preset(request: PresetRequest, raw_request: Request):
    """执行预设。通过preset_key执行用户自定义的预设指令"""
    # 打印详细的请求信息
    logger.info("=" * 80)
    logger.info("📥 插件服务接收到预设执行请求")
    logger.info(f"🔹 请求URL: {raw_request.url}")
    logger.info(f"🔹 请求方法: {raw_request.method}")
    logger.info(f"🔹 客户端IP: {raw_request.client.host if raw_request.client else 'Unknown'}")
    logger.info(f"🔹 User-Agent: {raw_request.headers.get('user-agent', 'Unknown')}")
    logger.info(f"🔹 请求体参数:")
    logger.info(f"   - device_uuid: {request.device_uuid}")
    logger.info(f"   - preset_name: {request.preset_name}")
    logger.info(f"   - parameters: {request.parameters}")
    logger.info(f"🔹 当前 BACKEND_URL: {BACKEND_URL}")
    logger.info(f"🔹 时间戳: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    logger.info("=" * 80)
    logger.info(f"🎯 执行预设: uuid={request.device_uuid}, preset={request.preset_name}")
    
    # 🧪 测试模式：返回模拟成功响应
    if is_test_mode(request.device_uuid):
        logger.info(f"🧪 测试模式激活: 模拟预设指令执行成功")
        
        # 从preset_name推断device_type
        device_type_map = {
            "led_blink": "led",
            "led_wave": "led",
            "relay_timed": "relay",
            "servo_rotate": "servo",
            "servo_swing": "servo",
            "pwm_fade": "pwm",
            "pwm_breathe": "pwm",
            "pwm_pulse": "pwm"
        }
        
        device_type = device_type_map.get(request.preset_name, "unknown")
        device_id = request.parameters.get("led_id") or request.parameters.get("servo_id") or \
                     request.parameters.get("pwm_id") or request.parameters.get("relay_id") or 1
        
        result = PresetResponse(
            device_uuid=request.device_uuid,
            preset_name=request.preset_name,
            device_type=device_type,
            device_id=device_id,
            parameters=request.parameters or {},
            status="success",
            message=f"测试模式：预设指令{request.preset_name}执行成功",
            timestamp=datetime.now().strftime("%Y-%m-%dT%H:%M:%S+08:00")
        )
        
        # 精简返回：只返回结果
        return StandardResponse(
            code=200,
            msg="成功",
            data={"result": "success"}
        )
    
    # 验证设备
    if not await verify_device_exists(request.device_uuid):
        logger.warning(f"❌ 设备不存在: {request.device_uuid}")
        raise HTTPException(status_code=404, detail=f"设备 {request.device_uuid} 不存在")
    
    try:
        # 方式1：通过preset_key执行（推荐）
        # 直接将preset_key发送到后端，由后端查找并执行对应的预设
        logger.info(f"📤 通过preset_key执行预设: {request.preset_name}")
        
        # 调用后端API（使用内部API密钥）
        headers = get_internal_headers()
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{BACKEND_URL}/api/devices/{request.device_uuid}/control",
                json={"preset_key": request.preset_name},  # preset_name其实是preset_key
                headers=headers
            )
            
            if response.status_code == 401 or response.status_code == 403:
                logger.error(f"❌ 后端API认证失败: {response.status_code}")
                raise HTTPException(
                    status_code=500, 
                    detail="后端API认证失败，请检查BACKEND_API_KEY配置"
                )
            
            if response.status_code == 404:
                raise HTTPException(
                    status_code=404,
                    detail=f"未找到预设指令: {request.preset_name}"
                )
            
            if response.status_code != 200:
                error_detail = response.json() if response.text else "预设执行失败"
                raise HTTPException(status_code=500, detail=error_detail)
            
            logger.info(f"✅ 预设执行成功: {request.preset_name}")
            
            # 精简返回：只返回结果
            return StandardResponse(
                code=200,
                msg="成功",
                data={"result": "success"}
            )
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ 执行预设失败: {e}")
        # 如果通过preset_key执行失败，尝试使用旧的映射方式（兼容性）
        logger.info(f"⚠️  尝试使用旧的预设映射方式...")
        
        # 方式2：旧的预设指令映射（向后兼容）
        preset_map = {
            # LED预设
            "led_blink": {
                "device_type": "led",
                "preset_type": "blink",
                "default_params": {"count": 3, "on_time": 500, "off_time": 500}
            },
            "led_wave": {
                "device_type": "led",
                "preset_type": "wave",
                "default_params": {"interval_ms": 200, "cycles": 3, "reverse": False}
            },
            
            # 继电器预设
            "relay_timed": {
                "device_type": "relay",
                "preset_type": "timed_switch",
                "default_params": {"duration_ms": 5000}
            },
            
            # 舵机预设
            "servo_rotate": {
                "device_type": "servo",
                "preset_type": "rotate",
                "default_params": {"start_angle": 0, "end_angle": 180, "duration_ms": 2000}
            },
            "servo_swing": {
                "device_type": "servo",
                "preset_type": "swing",
                "default_params": {"center_angle": 90, "swing_range": 30, "speed": 100, "cycles": 5}
            },
            
            # PWM预设
            "pwm_fade": {
                "device_type": "pwm",
                "preset_type": "fade",
                "default_params": {"start_duty": 0, "end_duty": 100, "duration_ms": 2000, "frequency": 5000}
            },
            "pwm_breathe": {
                "device_type": "pwm",
                "preset_type": "breathe",
                "default_params": {"min_duty": 0, "max_duty": 100, "period_ms": 2000, "cycles": 3, "frequency": 5000}
            },
            "pwm_pulse": {
                "device_type": "pwm",
                "preset_type": "pulse",
                "default_params": {"duty_high": 100, "duty_low": 0, "high_time_ms": 100, "low_time_ms": 100, "cycles": 5, "frequency": 5000}
            },
        }
        
        if request.preset_name not in preset_map:
            raise HTTPException(
                status_code=400, 
                detail=f"不支持的预设指令: {request.preset_name}"
            )
        
        preset_config = preset_map[request.preset_name]
        
        # 合并默认参数和用户参数
        parameters = preset_config["default_params"].copy()
        if request.parameters:
            parameters.update(request.parameters)
        
        # 提取device_id（如果用户提供）
        device_id = parameters.pop("led_id", None) or \
                   parameters.pop("servo_id", None) or \
                   parameters.pop("pwm_id", None) or \
                   parameters.pop("relay_id", None) or 1
        
        # 构造预设命令
        preset_cmd = {
            "cmd": "preset",
            "device_type": preset_config["device_type"],
            "device_id": device_id,
            "preset_type": preset_config["preset_type"],
            "parameters": parameters
        }
        
        # 调用后端API发送预设命令（使用内部API密钥）
        headers = get_internal_headers()
        async with httpx.AsyncClient(timeout=30.0) as client:  # 预设可能需要更长时间
            response = await client.post(
                f"{BACKEND_URL}/api/devices/{request.device_uuid}/control",
                json=preset_cmd,
                headers=headers
            )
            
            if response.status_code == 401 or response.status_code == 403:
                logger.error(f"❌ 后端API认证失败: {response.status_code}")
                raise HTTPException(
                    status_code=500, 
                    detail="后端API认证失败，请检查BACKEND_API_KEY配置"
                )
            
            if response.status_code != 200:
                error_detail = response.json() if response.text else "预设执行失败"
                raise HTTPException(status_code=500, detail=error_detail)
            
            logger.info(f"✅ 预设执行成功: {request.preset_name}")
            
            # 精简返回：只返回结果
            return StandardResponse(
                code=200,
                msg="成功",
                data={"result": "success"}
            )


# ==================== 启动配置 ====================

if __name__ == "__main__":
    import uvicorn
    
    print(f"""
    ╔═══════════════════════════════════════════════════╗
    ║     AIOT 外部插件服务                             ║
    ║     版本: 1.0.0                                   ║
    ║     端口: {config.PORT}                                    ║
    ╚═══════════════════════════════════════════════════╝
    
    📖 API文档: http://localhost:{config.PORT}/docs
    🔍 健康检查: http://localhost:{config.PORT}/
    
    🌐 API接口:
      - GET  /plugin/sensor-data?uuid={{uuid}}&sensor={{name}}
      - POST /plugin/control
      - POST /plugin/preset
    
    🚀 服务启动中...
    """)
    
    uvicorn.run(
        "main:app",
        host=config.HOST,
        port=config.PORT,
        reload=config.RELOAD,
        log_level=config.LOG_LEVEL.lower()
    )

