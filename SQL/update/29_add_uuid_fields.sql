-- ============================================================================
-- 添加UUID字段以增强安全性
-- 用途：防止ID遍历攻击，保护敏感业务数据
-- 作者：System
-- 日期：2025-11-29
-- ============================================================================

-- ============================================================================
-- 1. 为学校表添加UUID字段
-- ============================================================================

-- 检查并添加uuid字段
SET @dbname = DATABASE();
SET @tablename = 'aiot_schools';
SET @columnname = 'uuid';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  'SELECT 1',
  CONCAT('ALTER TABLE ', @tablename, ' ADD COLUMN ', @columnname, ' CHAR(36) NULL COMMENT ''UUID，用于外部API访问'' AFTER id')
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- 为现有记录生成UUID
UPDATE aiot_schools SET uuid = UUID() WHERE uuid IS NULL OR uuid = '';

-- 添加唯一索引
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE 
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (INDEX_NAME = 'idx_uuid')
  ) > 0,
  'SELECT 1',
  CONCAT('CREATE UNIQUE INDEX idx_uuid ON ', @tablename, ' (uuid)')
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- 设置为NOT NULL
ALTER TABLE aiot_schools MODIFY COLUMN uuid CHAR(36) NOT NULL COMMENT 'UUID，用于外部API访问';

-- ============================================================================
-- 2. 为班级表添加UUID字段
-- ============================================================================

SET @tablename = 'aiot_classes';
SET @columnname = 'uuid';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  'SELECT 1',
  CONCAT('ALTER TABLE ', @tablename, ' ADD COLUMN ', @columnname, ' CHAR(36) NULL COMMENT ''UUID，用于外部API访问'' AFTER id')
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- 为现有记录生成UUID
UPDATE aiot_classes SET uuid = UUID() WHERE uuid IS NULL OR uuid = '';

-- 添加唯一索引
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE 
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (INDEX_NAME = 'idx_uuid')
  ) > 0,
  'SELECT 1',
  CONCAT('CREATE UNIQUE INDEX idx_uuid ON ', @tablename, ' (uuid)')
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- 设置为NOT NULL
ALTER TABLE aiot_classes MODIFY COLUMN uuid CHAR(36) NOT NULL COMMENT 'UUID，用于外部API访问';

-- ============================================================================
-- 3. 为小组表添加UUID字段
-- ============================================================================

SET @tablename = 'aiot_groups';
SET @columnname = 'uuid';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  'SELECT 1',
  CONCAT('ALTER TABLE ', @tablename, ' ADD COLUMN ', @columnname, ' CHAR(36) NULL COMMENT ''UUID，用于外部API访问'' AFTER id')
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- 为现有记录生成UUID
UPDATE aiot_groups SET uuid = UUID() WHERE uuid IS NULL OR uuid = '';

-- 添加唯一索引
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE 
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (INDEX_NAME = 'idx_uuid')
  ) > 0,
  'SELECT 1',
  CONCAT('CREATE UNIQUE INDEX idx_uuid ON ', @tablename, ' (uuid)')
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- 设置为NOT NULL
ALTER TABLE aiot_groups MODIFY COLUMN uuid CHAR(36) NOT NULL COMMENT 'UUID，用于外部API访问';

-- ============================================================================
-- 验证UUID字段
-- ============================================================================

-- 查看学校表UUID
SELECT 'aiot_schools' as table_name, COUNT(*) as total_records, 
       COUNT(DISTINCT uuid) as unique_uuids,
       MIN(LENGTH(uuid)) as min_length,
       MAX(LENGTH(uuid)) as max_length
FROM aiot_schools;

-- 查看班级表UUID
SELECT 'aiot_classes' as table_name, COUNT(*) as total_records, 
       COUNT(DISTINCT uuid) as unique_uuids,
       MIN(LENGTH(uuid)) as min_length,
       MAX(LENGTH(uuid)) as max_length
FROM aiot_classes;

-- 查看小组表UUID
SELECT 'aiot_groups' as table_name, COUNT(*) as total_records, 
       COUNT(DISTINCT uuid) as unique_uuids,
       MIN(LENGTH(uuid)) as min_length,
       MAX(LENGTH(uuid)) as max_length
FROM aiot_groups;

-- ============================================================================
-- 说明
-- ============================================================================
-- 1. UUID字段用于外部API访问，防止ID遍历攻击
-- 2. ID字段保留用于内部数据库关联，保持性能
-- 3. UUID采用MySQL原生UUID()函数生成，格式为36字符（含连字符）
-- 4. 添加唯一索引确保UUID不重复且查询性能
-- 5. 脚本支持幂等执行，可以重复运行
-- ============================================================================

