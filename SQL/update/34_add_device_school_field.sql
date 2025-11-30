-- ============================================================================
-- 为设备表添加学校归属字段
-- 支持设备明确归属于学校，用于教学场景的设备管理
-- 创建时间: 2025-11-29
-- ============================================================================

USE `aiot_platform`;

-- ============================================================================
-- 1. 检查并添加school_id字段
-- ============================================================================

-- 检查school_id列是否存在
SET @col_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'aiot_platform' 
    AND TABLE_NAME = 'aiot_core_devices' 
    AND COLUMN_NAME = 'school_id'
);

-- 如果不存在则添加
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE `aiot_core_devices` 
     ADD COLUMN `school_id` INT NULL COMMENT ''所属学校ID（用于教学场景）'' AFTER `user_id`,
     ADD INDEX `idx_school_id` (`school_id`)',
    'SELECT ''school_id列已存在'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================================================
-- 2. 添加外键约束
-- ============================================================================

-- 检查外键是否存在
SET @fk_exists = (
    SELECT COUNT(*) 
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
    WHERE TABLE_SCHEMA = 'aiot_platform' 
    AND TABLE_NAME = 'aiot_core_devices' 
    AND CONSTRAINT_NAME = 'fk_device_school'
);

-- 如果不存在则添加
SET @sql = IF(@fk_exists = 0,
    'ALTER TABLE `aiot_core_devices` 
     ADD CONSTRAINT `fk_device_school` 
     FOREIGN KEY (`school_id`) 
     REFERENCES `aiot_schools`(`id`) 
     ON DELETE SET NULL',
    'SELECT ''外键fk_device_school已存在'' AS message'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================================================
-- 说明
-- ============================================================================

-- 字段说明：
-- - school_id: 设备所属学校ID，可为NULL
--   - NULL: 个人设备，不属于任何学校
--   - NOT NULL: 学校设备，可用于教学场景的分组和授权
-- 
-- 业务流程：
-- 1. 设备注册时默认为个人设备（school_id = NULL）
-- 2. 学校管理员可以将设备"设置为学校设备"（设置school_id）
-- 3. 只有school_id不为NULL的设备才能：
--    - 被添加到设备分组
--    - 被授权给课程使用
--    - 在学校设备列表中显示
-- 
-- 权限控制：
-- - 只有学校管理员可以设置设备为学校设备
-- - 设备所有者（user_id）可以将设备转为学校设备
-- - 学校管理员只能看到school_id = 自己学校ID的设备

SELECT '✅ 设备学校归属字段添加完成' AS status;

