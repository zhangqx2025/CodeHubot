#!/usr/bin/env python3
"""
测试传感器数据上传功能

使用方法：
1. 确保你有一个已注册的设备（device_id 和 device_secret）
2. 修改下面的配置信息
3. 运行: python test_sensor_upload.py
"""

import requests
import json
from datetime import datetime

# ====== 配置信息 ======
API_BASE_URL = "http://localhost:8000"  # 修改为你的后端地址
DEVICE_ID = "AIOT-ESP32-XXXXXXXX"  # 修改为你的设备ID
DEVICE_SECRET = "your_device_secret_here"  # 修改为你的设备密钥

# ====== 测试数据 ======
def test_upload_single_sensor():
    """测试上传单个传感器数据"""
    url = f"{API_BASE_URL}/api/devices/data/upload"
    
    payload = {
        "device_id": DEVICE_ID,
        "device_secret": DEVICE_SECRET,
        "timestamp": datetime.now().isoformat(),
        "sensors": [
            {
                "sensor_name": "temperature",
                "value": 25.5,
                "unit": "°C",
                "timestamp": datetime.now().isoformat()
            }
        ],
        "status": {
            "ip_address": "192.168.1.100",
            "rssi": -50,
            "battery": 95
        }
    }
    
    print("=" * 60)
    print("测试1: 上传单个传感器数据")
    print("=" * 60)
    print(f"请求URL: {url}")
    print(f"请求数据: {json.dumps(payload, indent=2, ensure_ascii=False)}")
    
    response = requests.post(url, json=payload)
    
    print(f"\n响应状态码: {response.status_code}")
    print(f"响应数据: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
    print()


def test_upload_multiple_sensors():
    """测试上传多个传感器数据"""
    url = f"{API_BASE_URL}/api/devices/data/upload"
    
    payload = {
        "device_id": DEVICE_ID,
        "device_secret": DEVICE_SECRET,
        "timestamp": datetime.now().isoformat(),
        "sensors": [
            {
                "sensor_name": "temperature",
                "value": 26.8,
                "unit": "°C",
                "timestamp": datetime.now().isoformat()
            },
            {
                "sensor_name": "humidity",
                "value": 65.5,
                "unit": "%",
                "timestamp": datetime.now().isoformat()
            },
            {
                "sensor_name": "light",
                "value": 850,
                "unit": "lux",
                "timestamp": datetime.now().isoformat()
            },
            {
                "sensor_name": "pressure",
                "value": 1013.25,
                "unit": "hPa",
                "timestamp": datetime.now().isoformat()
            }
        ],
        "status": {
            "ip_address": "192.168.1.100",
            "rssi": -48,
            "battery": 93
        },
        "location": {
            "latitude": 39.9042,
            "longitude": 116.4074
        }
    }
    
    print("=" * 60)
    print("测试2: 上传多个传感器数据")
    print("=" * 60)
    print(f"请求URL: {url}")
    print(f"请求数据: {json.dumps(payload, indent=2, ensure_ascii=False)}")
    
    response = requests.post(url, json=payload)
    
    print(f"\n响应状态码: {response.status_code}")
    print(f"响应数据: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
    print()


def test_get_sensor_data(device_uuid, token):
    """测试获取传感器数据"""
    url = f"{API_BASE_URL}/api/devices/{device_uuid}/sensor-data"
    
    headers = {
        "Authorization": f"Bearer {token}"
    }
    
    print("=" * 60)
    print("测试3: 获取传感器最后一次数据")
    print("=" * 60)
    print(f"请求URL: {url}")
    
    response = requests.get(url, headers=headers)
    
    print(f"\n响应状态码: {response.status_code}")
    print(f"响应数据: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
    print()


def login_and_get_token(username, password):
    """登录获取token"""
    url = f"{API_BASE_URL}/api/auth/login"
    
    payload = {
        "username": username,
        "password": password
    }
    
    response = requests.post(url, json=payload)
    
    if response.status_code == 200:
        data = response.json()
        if data.get("code") == 200:
            token = data.get("data", {}).get("access_token")
            print(f"✅ 登录成功，获取到token")
            return token
    
    print(f"❌ 登录失败: {response.text}")
    return None


if __name__ == "__main__":
    print("\n" + "=" * 60)
    print("开始测试传感器数据上传功能")
    print("=" * 60 + "\n")
    
    # 测试1: 上传单个传感器数据
    try:
        test_upload_single_sensor()
    except Exception as e:
        print(f"❌ 测试1失败: {e}\n")
    
    # 测试2: 上传多个传感器数据
    try:
        test_upload_multiple_sensors()
    except Exception as e:
        print(f"❌ 测试2失败: {e}\n")
    
    # 测试3: 获取传感器数据（需要先登录）
    print("\n如果需要测试获取传感器数据接口，请先配置用户名和密码：")
    print("username = 'your_username'")
    print("password = 'your_password'")
    print("device_uuid = 'your_device_uuid'")
    print("\n然后取消下面代码的注释：")
    print("""
    # username = "your_username"
    # password = "your_password"
    # device_uuid = "your_device_uuid"
    # 
    # token = login_and_get_token(username, password)
    # if token:
    #     test_get_sensor_data(device_uuid, token)
    """)
    
    print("\n" + "=" * 60)
    print("测试完成")
    print("=" * 60 + "\n")
