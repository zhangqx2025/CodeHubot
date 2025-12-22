-- ==========================================================================================================
-- AI助手配置检查和修复脚本
-- ==========================================================================================================
-- 用于检查和修复 enable_ai_assistant_in_unit 配置项
-- ==========================================================================================================

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

SELECT '========================================' AS '';
SELECT '检查 AI 助手配置项...' AS '';
SELECT '========================================' AS '';

-- 1. 查看当前配置
SELECT 
    id AS 'ID',
    config_key AS '配置键',
    config_value AS '配置值',
    config_type AS '类型',
    description AS '描述',
    category AS '分类',
    is_public AS '是否公开',
    created_at AS '创建时间',
    updated_at AS '更新时间'
FROM `core_system_config` 
WHERE `config_key` = 'enable_ai_assistant_in_unit';

-- 2. 如果配置不存在，插入配置
INSERT IGNORE INTO `core_system_config` (
    `config_key`,
    `config_value`,
    `config_type`,
    `description`,
    `category`,
    `is_public`,
    `created_at`,
    `updated_at`
) VALUES (
    'enable_ai_assistant_in_unit',
    'true',
    'boolean',
    '是否在单元学习页面显示AI助手图标',
    'feature',
    1,
    NOW(),
    NOW()
);

SELECT '========================================' AS '';
SELECT '配置项状态（插入后）:' AS '';
SELECT '========================================' AS '';

SELECT 
    id AS 'ID',
    config_key AS '配置键',
    config_value AS '配置值',
    config_type AS '类型',
    description AS '描述',
    category AS '分类',
    is_public AS '是否公开'
FROM `core_system_config` 
WHERE `config_key` = 'enable_ai_assistant_in_unit';

SELECT '========================================' AS '';
SELECT '提示：如需禁用 AI 助手，请执行以下 SQL：' AS '';
SELECT '========================================' AS '';
SELECT "UPDATE core_system_config SET config_value = 'false' WHERE config_key = 'enable_ai_assistant_in_unit';" AS '禁用AI助手';
SELECT "UPDATE core_system_config SET config_value = 'true' WHERE config_key = 'enable_ai_assistant_in_unit';" AS '启用AI助手';

-- 3. 查看所有公开配置（用于调试）
SELECT '========================================' AS '';
SELECT '所有公开配置项：' AS '';
SELECT '========================================' AS '';

SELECT 
    config_key AS '配置键',
    config_value AS '配置值',
    config_type AS '类型',
    category AS '分类'
FROM `core_system_config` 
WHERE `is_public` = 1
ORDER BY category, config_key;

