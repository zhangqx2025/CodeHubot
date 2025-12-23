-- ==========================================================================================================
-- 调试：检查 AI 助手配置和所有公开配置
-- ==========================================================================================================

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

SELECT '========================================' AS '';
SELECT '1. 检查 enable_ai_assistant_in_unit 配置是否存在' AS '';
SELECT '========================================' AS '';

SELECT 
    id,
    config_key,
    config_value,
    config_type,
    is_public,
    category,
    description
FROM core_system_config 
WHERE config_key = 'enable_ai_assistant_in_unit';

SELECT '========================================' AS '';
SELECT '2. 检查所有公开配置（is_public = 1）' AS '';
SELECT '========================================' AS '';

SELECT 
    config_key,
    config_value,
    config_type,
    category,
    is_public
FROM core_system_config 
WHERE is_public = 1
ORDER BY config_key;

SELECT '========================================' AS '';
SELECT '3. 统计信息' AS '';
SELECT '========================================' AS '';

SELECT 
    COUNT(*) AS '总配置数',
    SUM(CASE WHEN is_public = 1 THEN 1 ELSE 0 END) AS '公开配置数',
    SUM(CASE WHEN is_public = 0 THEN 1 ELSE 0 END) AS '私有配置数'
FROM core_system_config;

SELECT '========================================' AS '';
SELECT '4. 如果上面没有 enable_ai_assistant_in_unit，请执行：' AS '';
SELECT '========================================' AS '';
SELECT 'mysql -u root -p数据库名 < SQL/update/38_2_fix_ai_assistant_config.sql' AS '执行命令';


