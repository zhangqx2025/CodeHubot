-- ============================================================================
-- 为AI模块核心表添加软删除字段
-- 文件: SQL/update/48_add_soft_delete_to_ai_models.sql
-- 说明: 为Agent、Workflow、Plugin、LLM Model、KnowledgeBase表添加is_deleted字段，实现软删除功能
-- 兼容性: MySQL 5.7-8.0
-- 可重复执行: 是（使用动态SQL检查列是否存在）
-- ============================================================================

-- ============================================
-- 1. 为 agent_main 表添加 is_deleted 字段
-- ============================================
SET @column_exists = (
    SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'agent_main' 
    AND COLUMN_NAME = 'is_deleted'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `agent_main` ADD COLUMN `is_deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT ''是否删除（0=未删除，1=已删除，软删除）'' AFTER `is_system`',
    'SELECT "Column agent_main.is_deleted already exists" AS notice');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================
-- 2. 为 workflow_main 表添加 is_deleted 字段
-- ============================================
SET @column_exists = (
    SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'workflow_main' 
    AND COLUMN_NAME = 'is_deleted'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `workflow_main` ADD COLUMN `is_deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT ''是否删除（0=未删除，1=已删除，软删除）'' AFTER `is_public`',
    'SELECT "Column workflow_main.is_deleted already exists" AS notice');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================
-- 3. 为 plugin_main 表添加 is_deleted 字段
-- ============================================
SET @column_exists = (
    SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'plugin_main' 
    AND COLUMN_NAME = 'is_deleted'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `plugin_main` ADD COLUMN `is_deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT ''是否删除（0=未删除，1=已删除，软删除）'' AFTER `is_system`',
    'SELECT "Column plugin_main.is_deleted already exists" AS notice');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================
-- 4. 为 llm_models 表添加 is_deleted 字段
-- ============================================
SET @column_exists = (
    SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'llm_models' 
    AND COLUMN_NAME = 'is_deleted'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `llm_models` ADD COLUMN `is_deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT ''是否删除（0=未删除，1=已删除，软删除）'' AFTER `is_system`',
    'SELECT "Column llm_models.is_deleted already exists" AS notice');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================
-- 5. 为 kb_main 表添加 is_deleted 字段
-- ============================================
SET @column_exists = (
    SELECT COUNT(*) FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'kb_main' 
    AND COLUMN_NAME = 'is_deleted'
);

SET @sql = IF(@column_exists = 0,
    'ALTER TABLE `kb_main` ADD COLUMN `is_deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT ''是否删除（0=未删除，1=已删除，软删除）'' AFTER `is_system`',
    'SELECT "Column kb_main.is_deleted already exists" AS notice');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================
-- 6. 为已删除数据创建索引（可选，提升查询性能）
-- ============================================

-- Agent 索引
SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'agent_main' 
    AND INDEX_NAME = 'idx_is_deleted'
);

SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `agent_main` ADD INDEX `idx_is_deleted` (`is_deleted`)',
    'SELECT "Index agent_main.idx_is_deleted already exists" AS notice');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Workflow 索引
SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'workflow_main' 
    AND INDEX_NAME = 'idx_is_deleted'
);

SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `workflow_main` ADD INDEX `idx_is_deleted` (`is_deleted`)',
    'SELECT "Index workflow_main.idx_is_deleted already exists" AS notice');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Plugin 索引
SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'plugin_main' 
    AND INDEX_NAME = 'idx_is_deleted'
);

SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `plugin_main` ADD INDEX `idx_is_deleted` (`is_deleted`)',
    'SELECT "Index plugin_main.idx_is_deleted already exists" AS notice');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- LLM Model 索引
SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'llm_models' 
    AND INDEX_NAME = 'idx_is_deleted'
);

SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `llm_models` ADD INDEX `idx_is_deleted` (`is_deleted`)',
    'SELECT "Index llm_models.idx_is_deleted already exists" AS notice');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- KnowledgeBase 索引
SET @index_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'kb_main' 
    AND INDEX_NAME = 'idx_is_deleted'
);

SET @sql = IF(@index_exists = 0,
    'ALTER TABLE `kb_main` ADD INDEX `idx_is_deleted` (`is_deleted`)',
    'SELECT "Index kb_main.idx_is_deleted already exists" AS notice');

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================
-- 完成
-- ============================================
SELECT '✅ AI模块软删除字段添加完成！' AS result;

