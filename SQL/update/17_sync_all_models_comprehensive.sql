-- ============================================================================
-- 全面同步所有后端模型与数据库定义
-- ============================================================================
-- 说明：一次性修复所有模型与数据库之间的不一致问题
-- 执行前请备份数据库
-- ============================================================================

-- ===========================================
-- 1. 用户表 (aiot_core_users)
-- ===========================================
-- 数据库多了 name 字段，但后端模型中没有定义
-- 保留该字段以向后兼容，未来可能会使用

-- ===========================================
-- 2. 设备表 (aiot_core_devices)
-- ===========================================
-- 扩展 device_secret 字段长度（从 varchar(64) 到 varchar(255)）
ALTER TABLE `aiot_core_devices`
MODIFY COLUMN `device_secret` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '设备密钥';

-- 扩展 quality_grade 字段长度（从 varchar(20) 到兼容后续扩展）
-- 当前数据库定义已经是 varchar(20)，模型中是 String(10)
-- 保持数据库定义，模型需要更新

-- ===========================================
-- 3. 产品表 (aiot_core_products)
-- ===========================================
-- 扩展 product_code 字段长度（从 varchar(50) 到 varchar(64)）
ALTER TABLE `aiot_core_products`
MODIFY COLUMN `product_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '产品编码/产品标识符';

-- 确保 sensor_types 和 control_ports 字段不为 NULL（与模型定义一致）
UPDATE `aiot_core_products`
SET `sensor_types` = JSON_OBJECT()
WHERE `sensor_types` IS NULL;

UPDATE `aiot_core_products`
SET `control_ports` = JSON_OBJECT()
WHERE `control_ports` IS NULL;

ALTER TABLE `aiot_core_products`
MODIFY COLUMN `sensor_types` json NOT NULL COMMENT '传感器类型配置',
MODIFY COLUMN `control_ports` json NOT NULL COMMENT '控制端口配置';

-- 修改 power_requirements 为 JSON 类型（与模型定义一致）
ALTER TABLE `aiot_core_products`
MODIFY COLUMN `power_requirements` json DEFAULT NULL COMMENT '电源要求';

-- 修改 communication_protocols 确保为 JSON 类型
-- （数据库已经是 JSON，这里确认一致性）

-- ===========================================
-- 4. 固件版本表 (aiot_core_firmware_versions)
-- ===========================================
-- product_code: 模型要求 NOT NULL，但数据库允许 NULL
-- 保持数据库当前定义（允许 NULL），因为可能有通用固件不特定于某个产品

-- file_size 和 file_hash: 数据库要求 NOT NULL，但模型允许 NULL
-- 保持数据库定义（NOT NULL），确保数据完整性

-- 扩展 description 和 release_notes 字段类型（从 varchar(1024) 到 text）
ALTER TABLE `aiot_core_firmware_versions`
MODIFY COLUMN `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '描述',
MODIFY COLUMN `release_notes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '发布说明';

-- 扩展 firmware_url 字段长度（从 varchar(512) 到 varchar(500) - 数据库已更大，保持）
-- 当前数据库是 varchar(512)，无需修改

-- ===========================================
-- 5. LLM 模型表 (aiot_llm_models)
-- ===========================================
-- 已通过 15_add_llm_penalty_fields.sql 添加了缺失字段
-- frequency_penalty, presence_penalty, config

-- ===========================================
-- 6. 交互日志表 (aiot_interaction_logs)
-- ===========================================
-- 已通过 16_add_interaction_log_fields.sql 添加了缺失字段
-- user_agent, session_id

-- ===========================================
-- 7. 其他表检查
-- ===========================================
-- aiot_core_users: 数据库有额外的 name 字段，保留以向后兼容
-- aiot_llm_providers: 字段已同步
-- aiot_agents: 字段已同步
-- aiot_plugins: 字段已同步
-- aiot_device_binding_history: 字段已同步

-- ============================================================================
-- 数据验证和清理
-- ============================================================================

-- 确保所有产品的 sensor_types 和 control_ports 不为空
UPDATE `aiot_core_products`
SET `sensor_types` = JSON_OBJECT()
WHERE `sensor_types` IS NULL OR JSON_LENGTH(`sensor_types`) = 0;

UPDATE `aiot_core_products`
SET `control_ports` = JSON_OBJECT()
WHERE `control_ports` IS NULL OR JSON_LENGTH(`control_ports`) = 0;

-- 清理设备表中的异常状态值
UPDATE `aiot_core_devices`
SET `device_status` = 'pending'
WHERE `device_status` NOT IN ('pending', 'bound', 'active', 'offline', 'error');

-- ============================================================================
-- 完成提示
-- ============================================================================
SELECT '数据库同步完成！请重启后端服务以应用更改。' AS message;

