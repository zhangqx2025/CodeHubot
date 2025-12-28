-- ============================================================================
-- 文件: 46_add_uuid_and_soft_delete_to_prompt_templates.sql
-- 说明: 为提示词模板表添加UUID字段和软删除支持
-- 作者: AI Assistant
-- 日期: 2024-12-28
-- 可重复执行: 是（使用动态SQL检查）
-- ============================================================================

-- 添加 uuid 字段
SET @column_exists = (
    SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'llm_prompt_templates' 
    AND COLUMN_NAME = 'uuid'
);
SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `llm_prompt_templates` ADD COLUMN `uuid` VARCHAR(36) NOT NULL COMMENT \'唯一标识符\' AFTER `id`',
    'SELECT "uuid column already exists" AS notice');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加 is_deleted 字段
SET @column_exists = (
    SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'llm_prompt_templates' 
    AND COLUMN_NAME = 'is_deleted'
);
SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `llm_prompt_templates` ADD COLUMN `is_deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT \'是否删除（软删除）\' AFTER `is_active`',
    'SELECT "is_deleted column already exists" AS notice');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 为现有记录生成UUID（如果uuid字段为空）
UPDATE `llm_prompt_templates` 
SET `uuid` = UUID() 
WHERE `uuid` IS NULL OR `uuid` = '';

-- 添加uuid唯一索引
SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'llm_prompt_templates' 
    AND INDEX_NAME = 'uk_uuid'
);
SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `llm_prompt_templates` ADD UNIQUE KEY `uk_uuid` (`uuid`)',
    'SELECT "uk_uuid index already exists" AS notice');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 添加is_deleted索引
SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'llm_prompt_templates' 
    AND INDEX_NAME = 'idx_is_deleted'
);
SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `llm_prompt_templates` ADD KEY `idx_is_deleted` (`is_deleted`)',
    'SELECT "idx_is_deleted index already exists" AS notice');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 完成
SELECT 'Prompt templates table updated with uuid and soft delete support' AS result;

