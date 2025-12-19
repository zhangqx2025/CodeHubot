# 设备传感器数据上传与查询 API 文档

## 功能说明

系统现在支持存储每个设备的每个传感器的最后一次数据，包括：
- 传感器值
- 单位
- 时间戳
- 状态信息
- 位置信息

**注意：只存储最后一次上报的数据，不保留历史记录**

---

## 数据存储格式

数据存储在 `device_main` 表的 `last_report_data` 字段（JSON类型），格式如下：

```json
{
  "sensors": {
    "temperature": {
      "value": 25.5,
      "unit": "°C",
      "timestamp": "2025-12-19T14:30:00+08:00"
    },
    "humidity": {
      "value": 60,
      "unit": "%",
      "timestamp": "2025-12-19T14:30:00+08:00"
    },
    "light": {
      "value": 850,
      "unit": "lux",
      "timestamp": "2025-12-19T14:30:00+08:00"
    }
  },
  "status": {
    "ip_address": "192.168.1.100",
    "rssi": -50,
    "battery": 95
  },
  "location": {
    "latitude": 39.9042,
    "longitude": 116.4074
  },
  "upload_timestamp": "2025-12-19T14:30:00+08:00"
}
```

---

## API 接口

### 1. 上传传感器数据

**接口地址：** `POST /api/devices/data/upload`

**认证方式：** 设备认证（device_id + device_secret）

**请求体：**
```json
{
  "device_id": "AIOT-ESP32-XXXXXXXX",
  "device_secret": "your_device_secret",
  "timestamp": "2025-12-19T14:30:00+08:00",
  "sensors": [
    {
      "sensor_name": "temperature",
      "value": 25.5,
      "unit": "°C",
      "timestamp": "2025-12-19T14:30:00+08:00"
    },
    {
      "sensor_name": "humidity",
      "value": 60,
      "unit": "%",
      "timestamp": "2025-12-19T14:30:00+08:00"
    }
  ],
  "status": {
    "ip_address": "192.168.1.100",
    "rssi": -50,
    "battery": 95
  },
  "location": {
    "latitude": 39.9042,
    "longitude": 116.4074
  }
}
```

**响应示例：**
```json
{
  "code": 200,
  "message": "数据上传成功",
  "data": {
    "device_id": "AIOT-ESP32-XXXXXXXX",
    "device_name": "我的设备",
    "upload_timestamp": "2025-12-19T14:30:00+08:00",
    "sensors_count": 2,
    "sensors_uploaded": ["temperature", "humidity"]
  }
}
```

---

### 2. 获取传感器最后一次数据

**接口地址：** `GET /api/devices/{device_uuid}/sensor-data`

**认证方式：** JWT Token 或 内部API密钥

**请求头：**
```
Authorization: Bearer <your_jwt_token>
```
或
```
X-Internal-API-Key: <your_internal_api_key>
```

**响应示例：**
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "device_uuid": "xxx-xxx-xxx",
    "device_name": "我的设备",
    "upload_timestamp": "2025-12-19T14:30:00+08:00",
    "sensors": {
      "temperature": {
        "value": 25.5,
        "unit": "°C",
        "timestamp": "2025-12-19T14:30:00+08:00"
      },
      "humidity": {
        "value": 60,
        "unit": "%",
        "timestamp": "2025-12-19T14:30:00+08:00"
      }
    },
    "status": {
      "ip_address": "192.168.1.100",
      "rssi": -50,
      "battery": 95
    },
    "location": {
      "latitude": 39.9042,
      "longitude": 116.4074
    },
    "last_seen": "2025-12-19T14:30:00+08:00"
  }
}
```

**如果设备尚未上报数据：**
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "device_uuid": "xxx-xxx-xxx",
    "device_name": "我的设备",
    "upload_timestamp": null,
    "sensors": {},
    "status": {},
    "location": {},
    "message": "设备尚未上报数据"
  }
}
```

---

## 使用示例

### Python 示例

```python
import requests
from datetime import datetime

# 1. 上传传感器数据
url = "http://localhost:8000/api/devices/data/upload"
payload = {
    "device_id": "AIOT-ESP32-12345678",
    "device_secret": "your_device_secret",
    "sensors": [
        {
            "sensor_name": "temperature",
            "value": 25.5,
            "unit": "°C"
        },
        {
            "sensor_name": "humidity",
            "value": 60,
            "unit": "%"
        }
    ],
    "status": {
        "ip_address": "192.168.1.100"
    }
}

response = requests.post(url, json=payload)
print(response.json())

# 2. 获取传感器数据
device_uuid = "your-device-uuid"
url = f"http://localhost:8000/api/devices/{device_uuid}/sensor-data"
headers = {
    "Authorization": "Bearer your_jwt_token"
}

response = requests.get(url, headers=headers)
data = response.json()

if data["code"] == 200:
    sensors = data["data"]["sensors"]
    for sensor_name, sensor_data in sensors.items():
        print(f"{sensor_name}: {sensor_data['value']} {sensor_data['unit']}")
```

### Arduino/ESP32 示例

```cpp
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

const char* deviceId = "AIOT-ESP32-12345678";
const char* deviceSecret = "your_device_secret";
const char* serverUrl = "http://your-server.com/api/devices/data/upload";

void uploadSensorData(float temperature, float humidity) {
    HTTPClient http;
    http.begin(serverUrl);
    http.addHeader("Content-Type", "application/json");
    
    // 构建JSON数据
    StaticJsonDocument<512> doc;
    doc["device_id"] = deviceId;
    doc["device_secret"] = deviceSecret;
    
    JsonArray sensors = doc.createNestedArray("sensors");
    
    JsonObject sensor1 = sensors.createNestedObject();
    sensor1["sensor_name"] = "temperature";
    sensor1["value"] = temperature;
    sensor1["unit"] = "°C";
    
    JsonObject sensor2 = sensors.createNestedObject();
    sensor2["sensor_name"] = "humidity";
    sensor2["value"] = humidity;
    sensor2["unit"] = "%";
    
    JsonObject status = doc.createNestedObject("status");
    status["ip_address"] = WiFi.localIP().toString();
    status["rssi"] = WiFi.RSSI();
    
    String requestBody;
    serializeJson(doc, requestBody);
    
    int httpCode = http.POST(requestBody);
    
    if (httpCode > 0) {
        String response = http.getString();
        Serial.println("Response: " + response);
    }
    
    http.end();
}

void setup() {
    Serial.begin(115200);
    // WiFi连接代码...
}

void loop() {
    float temp = readTemperature();
    float hum = readHumidity();
    
    uploadSensorData(temp, hum);
    
    delay(60000); // 每分钟上传一次
}
```

### JavaScript/前端示例

```javascript
// 1. 获取传感器数据
async function getSensorData(deviceUuid) {
    const token = localStorage.getItem('token');
    
    const response = await fetch(
        `/api/devices/${deviceUuid}/sensor-data`,
        {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        }
    );
    
    const result = await response.json();
    
    if (result.code === 200) {
        const sensors = result.data.sensors;
        
        // 显示传感器数据
        for (const [name, data] of Object.entries(sensors)) {
            console.log(`${name}: ${data.value} ${data.unit}`);
            console.log(`更新时间: ${data.timestamp}`);
        }
        
        return sensors;
    }
}

// 2. 实时刷新传感器数据
function startRealtimeMonitor(deviceUuid) {
    setInterval(async () => {
        const sensors = await getSensorData(deviceUuid);
        updateUI(sensors);
    }, 5000); // 每5秒刷新一次
}
```

---

## 注意事项

1. **只保留最后一次数据**
   - 每次上传会覆盖之前的数据
   - 如需历史数据，请在应用层或前端缓存

2. **传感器命名规范**
   - 使用英文小写字母和下划线
   - 例如：`temperature`, `humidity`, `light_sensor_1`

3. **时间戳格式**
   - 使用 ISO 8601 格式
   - 建议包含时区信息：`2025-12-19T14:30:00+08:00`

4. **数据大小限制**
   - JSON 字段有大小限制（通常为 64KB）
   - 建议每个设备传感器数量不超过 20 个

5. **上传频率建议**
   - 根据实际需求调整
   - 建议间隔：30秒 ~ 5分钟
   - 避免过于频繁导致数据库压力

---

## 测试工具

项目提供了测试脚本：`backend/test_sensor_upload.py`

使用方法：
```bash
# 1. 修改脚本中的配置
DEVICE_ID = "your_device_id"
DEVICE_SECRET = "your_device_secret"

# 2. 运行测试
cd backend
python test_sensor_upload.py
```

---

## 常见问题

### Q1: 为什么只存最后一次数据？
A: 实时监控场景通常只需要最新状态，历史数据可以用时序数据库（如 InfluxDB）单独存储。

### Q2: 如何获取历史数据？
A: 当前版本不支持。如需历史数据，建议：
- 前端实时缓存数据
- 使用时序数据库（InfluxDB, TimescaleDB）
- 添加专门的历史数据表

### Q3: 多个传感器同时上传会丢失数据吗？
A: 不会。所有传感器数据在一次请求中上传，作为一个整体存储。

### Q4: 传感器数据支持什么类型？
A: 支持数值类型（int, float），可以添加单位说明。

---

## 更新日志

### 2025-12-19
- ✅ 实现传感器数据上传功能
- ✅ 支持多个传感器同时上传
- ✅ 每个传感器独立时间戳
- ✅ 新增 `/sensor-data` 查询接口
- ✅ 添加测试脚本和文档
