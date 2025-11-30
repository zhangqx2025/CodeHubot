-- ============================================================================
-- 修复无效的日期时间值
-- 描述: 将数据库中所有 '0000-00-00 00:00:00' 的日期时间值更新为当前北京时间
-- 创建时间: 2024-01-XX
-- ============================================================================


-- ============================================================================
-- 1. 修复 aiot_schools 表
-- ============================================================================

-- 修复 created_at 字段（使用字符串比较避免严格模式错误）
UPDATE `aiot_schools` 
SET `created_at` = NOW()
WHERE CAST(`created_at` AS CHAR) = '0000-00-00 00:00:00' OR `created_at` IS NULL OR `created_at` < '1970-01-01';

-- 修复 updated_at 字段
UPDATE `aiot_schools` 
SET `updated_at` = NOW()
WHERE CAST(`updated_at` AS CHAR) = '0000-00-00 00:00:00' OR `updated_at` IS NULL OR `updated_at` < '1970-01-01';

-- 修复 license_expire_at 字段（设为1年后）
UPDATE `aiot_schools` 
SET `license_expire_at` = DATE_ADD(NOW(), INTERVAL 1 YEAR)
WHERE CAST(`license_expire_at` AS CHAR) = '0000-00-00' OR `license_expire_at` IS NULL OR `license_expire_at` < '1970-01-01';

-- 修复 max_teachers 字段
UPDATE `aiot_schools` 
SET `max_teachers` = 100
WHERE `max_teachers` IS NULL;

-- 修复 max_students 字段
UPDATE `aiot_schools` 
SET `max_students` = 1000
WHERE `max_students` IS NULL;

-- 修复 max_devices 字段
UPDATE `aiot_schools` 
SET `max_devices` = 500
WHERE `max_devices` IS NULL;

SELECT '✓ aiot_schools 表日期时间字段已修复' AS status;

-- ============================================================================
-- 2. 修复 aiot_core_users 表
-- ============================================================================

-- 修复 created_at 字段
UPDATE `aiot_core_users` 
SET `created_at` = NOW()
WHERE CAST(`created_at` AS CHAR) = '0000-00-00 00:00:00' OR `created_at` IS NULL OR `created_at` < '1970-01-01';

-- 修复 updated_at 字段
UPDATE `aiot_core_users` 
SET `updated_at` = NOW()
WHERE CAST(`updated_at` AS CHAR) = '0000-00-00 00:00:00' OR `updated_at` IS NULL OR `updated_at` < '1970-01-01';

-- 修复 deleted_at 字段（设为 NULL，因为这是软删除字段）
UPDATE `aiot_core_users` 
SET `deleted_at` = NULL
WHERE CAST(`deleted_at` AS CHAR) = '0000-00-00 00:00:00';

SELECT '✓ aiot_core_users 表日期时间字段已修复' AS status;

-- ============================================================================
-- 3. 修复 aiot_agents 表
-- ============================================================================

UPDATE `aiot_agents` 
SET `created_at` = NOW()
WHERE CAST(`created_at` AS CHAR) = '0000-00-00 00:00:00' OR `created_at` IS NULL OR `created_at` < '1970-01-01';

UPDATE `aiot_agents` 
SET `updated_at` = NOW()
WHERE CAST(`updated_at` AS CHAR) = '0000-00-00 00:00:00' OR `updated_at` IS NULL OR `updated_at` < '1970-01-01';

SELECT '✓ aiot_agents 表日期时间字段已修复' AS status;

-- ============================================================================
-- 4. 修复 aiot_core_devices 表
-- ============================================================================

UPDATE `aiot_core_devices` 
SET `created_at` = NOW()
WHERE CAST(`created_at` AS CHAR) = '0000-00-00 00:00:00' OR `created_at` IS NULL OR `created_at` < '1970-01-01';

UPDATE `aiot_core_devices` 
SET `updated_at` = NOW()
WHERE CAST(`updated_at` AS CHAR) = '0000-00-00 00:00:00' OR `updated_at` IS NULL OR `updated_at` < '1970-01-01';

SELECT '✓ aiot_core_devices 表日期时间字段已修复' AS status;

-- ============================================================================
-- 5. 修复 aiot_core_products 表
-- ============================================================================

UPDATE `aiot_core_products` 
SET `created_at` = NOW()
WHERE CAST(`created_at` AS CHAR) = '0000-00-00 00:00:00' OR `created_at` IS NULL OR `created_at` < '1970-01-01';

UPDATE `aiot_core_products` 
SET `updated_at` = NOW()
WHERE CAST(`updated_at` AS CHAR) = '0000-00-00 00:00:00' OR `updated_at` IS NULL OR `updated_at` < '1970-01-01';

SELECT '✓ aiot_core_products 表日期时间字段已修复' AS status;

-- ============================================================================
-- 6. 修复 aiot_plugins 表
-- ============================================================================

UPDATE `aiot_plugins` 
SET `created_at` = NOW()
WHERE CAST(`created_at` AS CHAR) = '0000-00-00 00:00:00' OR `created_at` IS NULL OR `created_at` < '1970-01-01';

UPDATE `aiot_plugins` 
SET `updated_at` = NOW()
WHERE CAST(`updated_at` AS CHAR) = '0000-00-00 00:00:00' OR `updated_at` IS NULL OR `updated_at` < '1970-01-01';

SELECT '✓ aiot_plugins 表日期时间字段已修复' AS status;

-- ============================================================================
-- 7. 修复 aiot_llm_models 表
-- ============================================================================

UPDATE `aiot_llm_models` 
SET `created_at` = NOW()
WHERE CAST(`created_at` AS CHAR) = '0000-00-00 00:00:00' OR `created_at` IS NULL OR `created_at` < '1970-01-01';

UPDATE `aiot_llm_models` 
SET `updated_at` = NOW()
WHERE CAST(`updated_at` AS CHAR) = '0000-00-00 00:00:00' OR `updated_at` IS NULL OR `updated_at` < '1970-01-01';

SELECT '✓ aiot_llm_models 表日期时间字段已修复' AS status;

-- ============================================================================
-- 8. 修复 aiot_llm_providers 表
-- ============================================================================

UPDATE `aiot_llm_providers` 
SET `created_at` = NOW()
WHERE CAST(`created_at` AS CHAR) = '0000-00-00 00:00:00' OR `created_at` IS NULL OR `created_at` < '1970-01-01';

UPDATE `aiot_llm_providers` 
SET `updated_at` = NOW()
WHERE CAST(`updated_at` AS CHAR) = '0000-00-00 00:00:00' OR `updated_at` IS NULL OR `updated_at` < '1970-01-01';

SELECT '✓ aiot_llm_providers 表日期时间字段已修复' AS status;

-- ============================================================================
-- 9. 修复 aiot_core_firmware_versions 表
-- ============================================================================

UPDATE `aiot_core_firmware_versions` 
SET `created_at` = NOW()
WHERE CAST(`created_at` AS CHAR) = '0000-00-00 00:00:00' OR `created_at` IS NULL OR `created_at` < '1970-01-01';

UPDATE `aiot_core_firmware_versions` 
SET `updated_at` = NOW()
WHERE CAST(`updated_at` AS CHAR) = '0000-00-00 00:00:00' OR `updated_at` IS NULL OR `updated_at` < '1970-01-01';

SELECT '✓ aiot_core_firmware_versions 表日期时间字段已修复' AS status;

-- ============================================================================
-- 10. 修复 aiot_device_binding_history 表
-- ============================================================================

UPDATE `aiot_device_binding_history` 
SET `action_time` = NOW()
WHERE CAST(`action_time` AS CHAR) = '0000-00-00 00:00:00' OR `action_time` IS NULL OR `action_time` < '1970-01-01';

UPDATE `aiot_device_binding_history` 
SET `created_at` = NOW()
WHERE CAST(`created_at` AS CHAR) = '0000-00-00 00:00:00' OR `created_at` IS NULL OR `created_at` < '1970-01-01';

SELECT '✓ aiot_device_binding_history 表日期时间字段已修复' AS status;

-- ============================================================================
-- 11. 修复 aiot_interaction_logs 表
-- ============================================================================

UPDATE `aiot_interaction_logs` 
SET `created_at` = NOW()
WHERE CAST(`created_at` AS CHAR) = '0000-00-00 00:00:00' OR `created_at` IS NULL OR `created_at` < '1970-01-01';

-- 修复 timestamp 字段（此表没有 updated_at）
UPDATE `aiot_interaction_logs` 
SET `timestamp` = NOW()
WHERE CAST(`timestamp` AS CHAR) = '0000-00-00 00:00:00' OR `timestamp` IS NULL OR `timestamp` < '1970-01-01';

SELECT '✓ aiot_interaction_logs 表日期时间字段已修复' AS status;

-- ============================================================================
-- 完成
-- ============================================================================

SELECT '===============================================' AS '';
SELECT '✅ 所有表的无效日期时间值已修复' AS '';
SELECT '===============================================' AS '';

