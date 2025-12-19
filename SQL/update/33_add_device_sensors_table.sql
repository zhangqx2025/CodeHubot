-- ============================================================================
-- 创建设备传感器数据表
-- 用途：存储每个设备每个传感器的最新数据，替代 JSON 解析
-- 版本：v1.1 (使用 device_uuid 代替 device_id)
-- 日期：2025-12-19
-- 可重复执行：是
-- ============================================================================

-- 创建设备传感器数据表
CREATE TABLE IF NOT EXISTS `device_sensors` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `device_uuid` VARCHAR(36) NOT NULL COMMENT '设备UUID（关联 device_main.uuid）',
  `sensor_name` VARCHAR(50) NOT NULL COMMENT '传感器名称（如 temperature, humidity, rain）',
  `sensor_value` VARCHAR(255) NOT NULL COMMENT '传感器值（存储字符串，支持数字、布尔值等）',
  `sensor_unit` VARCHAR(20) DEFAULT '' COMMENT '单位（如 °C, %, 空字符串）',
  `sensor_type` VARCHAR(50) DEFAULT '' COMMENT '传感器类型（如 DHT11, DS18B20, RAIN_SENSOR）',
  `timestamp` DATETIME NOT NULL COMMENT '数据上报时间',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '记录更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_device_sensor` (`device_uuid`, `sensor_name`) COMMENT '设备UUID+传感器唯一约束',
  KEY `idx_device_uuid` (`device_uuid`) COMMENT '设备UUID索引',
  KEY `idx_timestamp` (`timestamp`) COMMENT '时间戳索引',
  KEY `idx_sensor_name` (`sensor_name`) COMMENT '传感器名称索引'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='设备传感器数据表';

-- ============================================================================
-- 说明：
-- 1. 使用 device_uuid 而不是 device_id，查询时无需JOIN device_main表
-- 2. sensor_value 使用 VARCHAR 存储，可以保存数字、布尔值、字符串等
-- 3. 唯一键 uk_device_sensor 确保每个设备的每个传感器只有一条最新记录
-- 4. 当新数据到达时，使用 INSERT ... ON DUPLICATE KEY UPDATE 更新现有记录
-- 5. 查询某个设备的某个传感器数据非常快速，不需要解析 JSON
-- ============================================================================

-- 示例：插入或更新传感器数据
-- INSERT INTO `device_sensors` 
-- (`device_uuid`, `sensor_name`, `sensor_value`, `sensor_unit`, `sensor_type`, `timestamp`)
-- VALUES 
-- ('1577241d-26d6-49cc-a7f6-51b4c6f0f901', 'temperature', '25.5', '°C', 'DHT11', NOW())
-- ON DUPLICATE KEY UPDATE 
--   `sensor_value` = VALUES(`sensor_value`),
--   `sensor_unit` = VALUES(`sensor_unit`),
--   `timestamp` = VALUES(`timestamp`);
