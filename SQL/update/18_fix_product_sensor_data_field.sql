-- ============================================================================
-- 修复产品传感器配置缺少 data_field 字段的问题
-- ============================================================================
-- 说明：
-- 1. 检查所有产品的 sensor_types 配置
-- 2. 确保每个传感器配置都包含 data_field 字段
-- 3. 修复缺少 data_field 的配置
-- ============================================================================

-- 先查看当前所有产品的传感器配置
SELECT 
    id,
    product_code,
    name,
    sensor_types
FROM aiot_core_products
WHERE sensor_types IS NOT NULL
ORDER BY id;

-- ============================================================================
-- 标准传感器配置示例（包含 data_field 字段）
-- ============================================================================

-- DHT11传感器产品示例
UPDATE aiot_core_products 
SET sensor_types = JSON_OBJECT(
    'DHT11_temperature', JSON_OBJECT(
        'type', 'DHT11',
        'data_field', 'temperature',
        'name', '温度传感器',
        'unit', '°C',
        'range', JSON_OBJECT('min', -40, 'max', 80),
        'accuracy', 2.0,
        'enabled', true
    ),
    'DHT11_humidity', JSON_OBJECT(
        'type', 'DHT11',
        'data_field', 'humidity',
        'name', '湿度传感器',
        'unit', '%',
        'range', JSON_OBJECT('min', 0, 'max', 100),
        'accuracy', 5.0,
        'enabled', true
    )
)
WHERE product_code = 'ESP32-DHT11'  -- 替换为实际的产品代码
AND (
    sensor_types IS NULL 
    OR NOT JSON_CONTAINS_PATH(sensor_types, 'one', '$.DHT11_temperature.data_field')
);

-- ============================================================================
-- 通用修复脚本：为现有产品添加 data_field
-- ============================================================================

-- 注意：以下脚本需要根据实际情况手动执行
-- 因为需要知道具体的产品代码和传感器配置

-- 示例1：修复包含 DHT11 和 DS18B20 的产品
UPDATE aiot_core_products 
SET sensor_types = JSON_OBJECT(
    'DHT11_temperature', JSON_OBJECT(
        'type', 'DHT11',
        'data_field', 'temperature',
        'name', '温度传感器',
        'unit', '°C',
        'range', JSON_OBJECT('min', -40, 'max', 80),
        'accuracy', 2.0,
        'enabled', true
    ),
    'DHT11_humidity', JSON_OBJECT(
        'type', 'DHT11',
        'data_field', 'humidity',
        'name', '湿度传感器',
        'unit', '%',
        'range', JSON_OBJECT('min', 0, 'max', 100),
        'accuracy', 5.0,
        'enabled', true
    ),
    'DS18B20_temperature', JSON_OBJECT(
        'type', 'DS18B20',
        'data_field', 'temperature',
        'name', '防水温度传感器',
        'unit', '°C',
        'range', JSON_OBJECT('min', -55, 'max', 125),
        'accuracy', 0.5,
        'enabled', true
    ),
    'RAIN_SENSOR_is_raining', JSON_OBJECT(
        'type', 'RAIN_SENSOR',
        'data_field', 'is_raining',
        'name', '雨水传感器',
        'unit', '',
        'enabled', true
    )
)
WHERE product_code = 'ESP32-S3-MULTI-SENSOR';  -- 替换为实际的产品代码

-- ============================================================================
-- 验证修复结果
-- ============================================================================

-- 检查所有产品的 sensor_types 是否包含 data_field
SELECT 
    id,
    product_code,
    name,
    JSON_KEYS(sensor_types) as sensor_keys,
    sensor_types
FROM aiot_core_products
WHERE sensor_types IS NOT NULL
ORDER BY id;

-- ============================================================================
-- 说明：data_field 字段的作用
-- ============================================================================
-- data_field 用于从设备上报的原始数据中提取对应字段的值
-- 
-- 设备上报的数据格式：
-- {
--   "sensor": "DHT11",
--   "temperature": 30.4,
--   "humidity": 10,
--   "device_id": "AIOT-ESP32-2DAFB099",
--   "timestamp": 423
-- }
-- 
-- 产品配置：
-- {
--   "DHT11_temperature": {
--     "type": "DHT11",           // 匹配 sensor 字段
--     "data_field": "temperature" // 提取 temperature 字段的值
--   },
--   "DHT11_humidity": {
--     "type": "DHT11",           // 匹配 sensor 字段
--     "data_field": "humidity"   // 提取 humidity 字段的值
--   }
-- }
-- 
-- 最终输出：
-- {
--   "DHT11_temperature": 30.4,
--   "DHT11_humidity": 10
-- }
-- ============================================================================

