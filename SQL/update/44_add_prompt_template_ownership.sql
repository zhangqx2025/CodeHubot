-- ============================================================================
-- 提示词模板权限隔离功能
-- 功能：添加 is_system 和 user_id 字段，实现系统模板和个人模板的权限隔离
-- 作者：AI Assistant
-- 日期：2025-01-XX
-- 说明：此脚本可重复执行
-- ============================================================================

-- 检查并添加 is_system 字段
SET @column_exists = (
    SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'llm_prompt_templates' 
    AND COLUMN_NAME = 'is_system'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `llm_prompt_templates` ADD COLUMN `is_system` TINYINT(1) NOT NULL DEFAULT 0 COMMENT ''是否系统模板'' AFTER `is_active`',
    'SELECT "Column is_system already exists" AS notice');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加 user_id 字段
SET @column_exists = (
    SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'llm_prompt_templates' 
    AND COLUMN_NAME = 'user_id'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `llm_prompt_templates` ADD COLUMN `user_id` INT(11) DEFAULT NULL COMMENT ''创建用户ID（系统模板为NULL）'' AFTER `is_system`',
    'SELECT "Column user_id already exists" AS notice');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加外键索引
SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'llm_prompt_templates' 
    AND INDEX_NAME = 'idx_user_id'
);

SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `llm_prompt_templates` ADD KEY `idx_user_id` (`user_id`)',
    'SELECT "Index idx_user_id already exists" AS notice');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 检查并添加外键约束
SET @fk_exists = (
    SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'llm_prompt_templates' 
    AND CONSTRAINT_NAME = 'fk_prompt_template_user'
);

SET @sql = IF(@fk_exists = 0,
    'ALTER TABLE `llm_prompt_templates` ADD CONSTRAINT `fk_prompt_template_user` FOREIGN KEY (`user_id`) REFERENCES `core_users` (`id`) ON DELETE SET NULL',
    'SELECT "Foreign key fk_prompt_template_user already exists" AS notice');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 将现有的所有模板标记为系统模板（如果没有user_id）
UPDATE `llm_prompt_templates` 
SET `is_system` = 1 
WHERE `user_id` IS NULL AND `is_system` = 0;

-- 完成提示
SELECT '✅ 提示词模板权限隔离功能添加完成！' AS result;
SELECT '📋 说明：' AS info;
SELECT '  - is_system=1: 系统模板，所有用户可见' AS detail1;
SELECT '  - is_system=0 且 user_id不为空: 个人模板，仅创建者可见' AS detail2;
SELECT '  - 现有模板已自动标记为系统模板' AS detail3;

