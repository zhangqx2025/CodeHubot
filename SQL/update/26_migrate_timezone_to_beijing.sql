-- ============================================================================
-- 时区数据迁移脚本 - 将UTC时间转换为北京时间（UTC+8）
-- ============================================================================
-- 版本: V1.0
-- 创建日期: 2025-11-29
-- 说明: 将数据库中所有时间字段从UTC时间转换为北京时间
--       执行前建议备份数据库
-- 
-- 使用方法:
-- mysql -u username -p database_name < 26_migrate_timezone_to_beijing.sql
-- ============================================================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

-- ============================================================================
-- 1. 用户表 (aiot_core_users)
-- ============================================================================

UPDATE `aiot_core_users`
SET 
    `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR),
    `updated_at` = DATE_ADD(`updated_at`, INTERVAL 8 HOUR),
    `last_login` = IF(`last_login` IS NOT NULL, DATE_ADD(`last_login`, INTERVAL 8 HOUR), NULL),
    `deleted_at` = IF(`deleted_at` IS NOT NULL, DATE_ADD(`deleted_at`, INTERVAL 8 HOUR), NULL)
WHERE 
    `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR);  -- 只更新明显是UTC时间的记录

SELECT CONCAT('✓ 用户表已更新: ', ROW_COUNT(), ' 条记录') AS status;

-- ============================================================================
-- 2. 学校表 (aiot_schools)
-- ============================================================================

UPDATE `aiot_schools`
SET 
    `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR),
    `updated_at` = DATE_ADD(`updated_at`, INTERVAL 8 HOUR)
WHERE 
    `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR);

SELECT CONCAT('✓ 学校表已更新: ', ROW_COUNT(), ' 条记录') AS status;

-- ============================================================================
-- 3. 智能体表 (aiot_agents)
-- ============================================================================

UPDATE `aiot_agents`
SET 
    `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR),
    `updated_at` = DATE_ADD(`updated_at`, INTERVAL 8 HOUR)
WHERE 
    `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR);

SELECT CONCAT('✓ 智能体表已更新: ', ROW_COUNT(), ' 条记录') AS status;

-- ============================================================================
-- 4. 设备表 (aiot_core_devices)
-- ============================================================================

UPDATE `aiot_core_devices`
SET 
    `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR),
    `updated_at` = DATE_ADD(`updated_at`, INTERVAL 8 HOUR)
WHERE 
    `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR);

SELECT CONCAT('✓ 设备表已更新: ', ROW_COUNT(), ' 条记录') AS status;

-- ============================================================================
-- 5. 产品表 (aiot_core_products)
-- ============================================================================

UPDATE `aiot_core_products`
SET 
    `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR),
    `updated_at` = DATE_ADD(`updated_at`, INTERVAL 8 HOUR)
WHERE 
    `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR);

SELECT CONCAT('✓ 产品表已更新: ', ROW_COUNT(), ' 条记录') AS status;

-- ============================================================================
-- 6. 固件版本表 (aiot_core_firmware_versions)
-- ============================================================================

UPDATE `aiot_core_firmware_versions`
SET 
    `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR),
    `updated_at` = DATE_ADD(`updated_at`, INTERVAL 8 HOUR)
WHERE 
    `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR);

SELECT CONCAT('✓ 固件版本表已更新: ', ROW_COUNT(), ' 条记录') AS status;

-- ============================================================================
-- 7. 插件表 (aiot_plugins)
-- ============================================================================

UPDATE `aiot_plugins`
SET 
    `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR),
    `updated_at` = DATE_ADD(`updated_at`, INTERVAL 8 HOUR)
WHERE 
    `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR);

SELECT CONCAT('✓ 插件表已更新: ', ROW_COUNT(), ' 条记录') AS status;

-- ============================================================================
-- 8. 大模型表 (aiot_llm_models)
-- ============================================================================

UPDATE `aiot_llm_models`
SET 
    `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR),
    `updated_at` = DATE_ADD(`updated_at`, INTERVAL 8 HOUR)
WHERE 
    `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR);

SELECT CONCAT('✓ 大模型表已更新: ', ROW_COUNT(), ' 条记录') AS status;

-- ============================================================================
-- 9. 模型提供商表 (aiot_llm_providers)
-- ============================================================================

UPDATE `aiot_llm_providers`
SET 
    `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR),
    `updated_at` = DATE_ADD(`updated_at`, INTERVAL 8 HOUR)
WHERE 
    `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR);

SELECT CONCAT('✓ 模型提供商表已更新: ', ROW_COUNT(), ' 条记录') AS status;

-- ============================================================================
-- 10. 设备绑定历史表 (aiot_device_binding_history)
-- ============================================================================

UPDATE `aiot_device_binding_history`
SET 
    `action_time` = DATE_ADD(`action_time`, INTERVAL 8 HOUR),
    `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR)
WHERE 
    `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR);

SELECT CONCAT('✓ 设备绑定历史表已更新: ', ROW_COUNT(), ' 条记录') AS status;

-- ============================================================================
-- 11. 交互日志表 (aiot_interaction_logs) - 如果存在
-- ============================================================================

-- 检查表是否存在
SET @table_exists = (
    SELECT COUNT(*) 
    FROM information_schema.TABLES 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'aiot_interaction_logs'
);

-- 如果表存在，则更新
SET @sql = IF(@table_exists > 0,
    'UPDATE `aiot_interaction_logs`
     SET `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR)
     WHERE `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR)',
    'SELECT "⚠ 交互日志表不存在，跳过" AS status'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================================================
-- 12. 提示词模板表 (aiot_prompt_templates) - 如果存在
-- ============================================================================

SET @table_exists = (
    SELECT COUNT(*) 
    FROM information_schema.TABLES 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'aiot_prompt_templates'
);

SET @sql = IF(@table_exists > 0,
    'UPDATE `aiot_prompt_templates`
     SET `created_at` = DATE_ADD(`created_at`, INTERVAL 8 HOUR),
         `updated_at` = DATE_ADD(`updated_at`, INTERVAL 8 HOUR)
     WHERE `created_at` < DATE_SUB(NOW(), INTERVAL 7 HOUR)',
    'SELECT "⚠ 提示词模板表不存在，跳过" AS status'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================================================
-- 完成
-- ============================================================================

COMMIT;

SELECT '========================================' AS '';
SELECT '✓ 时区数据迁移完成！' AS status;
SELECT '  所有时间字段已从UTC时间转换为北京时间（UTC+8）' AS info;
SELECT '========================================' AS '';

-- 显示各表的时间范围（验证）
SELECT 
    'aiot_core_users' AS table_name,
    MIN(created_at) AS earliest_time,
    MAX(created_at) AS latest_time,
    COUNT(*) AS record_count
FROM aiot_core_users

UNION ALL

SELECT 
    'aiot_agents',
    MIN(created_at),
    MAX(created_at),
    COUNT(*)
FROM aiot_agents

UNION ALL

SELECT 
    'aiot_core_devices',
    MIN(created_at),
    MAX(created_at),
    COUNT(*)
FROM aiot_core_devices

UNION ALL

SELECT 
    'aiot_core_products',
    MIN(created_at),
    MAX(created_at),
    COUNT(*)
FROM aiot_core_products;

-- ============================================================================
-- 注意事项：
-- 1. 此脚本只更新 created_at < NOW() - 7小时 的记录，避免重复更新
-- 2. 执行前请务必备份数据库
-- 3. 建议在测试环境先执行验证
-- 4. 执行后新创建的记录会自动使用北京时间
-- ============================================================================

