-- ============================================================================
-- 班级管理模块数据库表
-- 创建日期: 2025-11-29
-- 说明: 包含班级表、小组表、小组成员表
-- ============================================================================

-- ============================================================================
-- 1. 班级表 (aiot_classes)
-- ============================================================================
CREATE TABLE IF NOT EXISTS `aiot_classes` (
    `id` INT NOT NULL AUTO_INCREMENT COMMENT '班级ID',
    `school_id` INT NOT NULL COMMENT '所属学校ID',
    `class_name` VARCHAR(100) NOT NULL COMMENT '班级名称（如：三年级1班）',
    `grade` VARCHAR(50) COMMENT '年级（如：三年级）',
    `class_number` VARCHAR(20) COMMENT '班号（如：1班）',
    `teacher_id` INT COMMENT '班主任ID',
    `teacher_name` VARCHAR(100) COMMENT '班主任姓名（冗余字段）',
    `academic_year` VARCHAR(20) COMMENT '学年（如：2024-2025）',
    `semester` ENUM('spring', 'fall') COMMENT '学期（春季/秋季）',
    `student_count` INT DEFAULT 0 COMMENT '学生人数（冗余字段，便于统计）',
    `description` TEXT COMMENT '班级描述',
    `is_active` BOOLEAN DEFAULT TRUE COMMENT '是否激活',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at` DATETIME NULL COMMENT '删除时间（软删除）',
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_school_class` (`school_id`, `class_name`, `deleted_at`),
    INDEX `idx_school_id` (`school_id`),
    INDEX `idx_teacher_id` (`teacher_id`),
    INDEX `idx_is_active` (`is_active`),
    INDEX `idx_academic_year` (`academic_year`),
    
    FOREIGN KEY (`school_id`) REFERENCES `aiot_schools`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`teacher_id`) REFERENCES `aiot_core_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='班级表';

-- ============================================================================
-- 2. 小组表 (aiot_groups)
-- ============================================================================
CREATE TABLE IF NOT EXISTS `aiot_groups` (
    `id` INT NOT NULL AUTO_INCREMENT COMMENT '小组ID',
    `class_id` INT NOT NULL COMMENT '所属班级ID',
    `school_id` INT NOT NULL COMMENT '所属学校ID（冗余，便于查询）',
    `group_name` VARCHAR(100) NOT NULL COMMENT '小组名称（如：小组A）',
    `group_number` INT COMMENT '小组编号（班级内序号）',
    `leader_id` INT COMMENT '组长ID',
    `leader_name` VARCHAR(100) COMMENT '组长姓名（冗余字段）',
    `member_count` INT DEFAULT 0 COMMENT '成员人数（冗余字段）',
    `description` TEXT COMMENT '小组描述',
    `is_active` BOOLEAN DEFAULT TRUE COMMENT '是否激活',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted_at` DATETIME NULL COMMENT '删除时间（软删除）',
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_class_group` (`class_id`, `group_name`, `deleted_at`),
    INDEX `idx_class_id` (`class_id`),
    INDEX `idx_school_id` (`school_id`),
    INDEX `idx_leader_id` (`leader_id`),
    INDEX `idx_is_active` (`is_active`),
    
    FOREIGN KEY (`class_id`) REFERENCES `aiot_classes`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`school_id`) REFERENCES `aiot_schools`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`leader_id`) REFERENCES `aiot_core_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='小组表';

-- ============================================================================
-- 3. 小组成员表 (aiot_group_members)
-- ============================================================================
CREATE TABLE IF NOT EXISTS `aiot_group_members` (
    `id` INT NOT NULL AUTO_INCREMENT COMMENT '记录ID',
    `group_id` INT NOT NULL COMMENT '小组ID',
    `class_id` INT NOT NULL COMMENT '班级ID（冗余，便于查询）',
    `school_id` INT NOT NULL COMMENT '学校ID（冗余，便于查询）',
    `student_id` INT NOT NULL COMMENT '学生ID',
    `student_name` VARCHAR(100) COMMENT '学生姓名（冗余字段）',
    `student_number` VARCHAR(50) COMMENT '学号（冗余字段）',
    `is_leader` BOOLEAN DEFAULT FALSE COMMENT '是否为组长',
    `joined_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
    `left_at` DATETIME NULL COMMENT '离开时间（软删除/转组）',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_group_student` (`group_id`, `student_id`, `left_at`),
    INDEX `idx_group_id` (`group_id`),
    INDEX `idx_class_id` (`class_id`),
    INDEX `idx_school_id` (`school_id`),
    INDEX `idx_student_id` (`student_id`),
    INDEX `idx_is_leader` (`is_leader`),
    
    FOREIGN KEY (`group_id`) REFERENCES `aiot_groups`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`class_id`) REFERENCES `aiot_classes`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`school_id`) REFERENCES `aiot_schools`(`id`) ON DELETE CASCADE,
    FOREIGN KEY (`student_id`) REFERENCES `aiot_core_users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='小组成员表';

-- ============================================================================
-- 4. 扩展用户表 - 添加班级和小组字段
-- ============================================================================
-- 注意：如果字段已存在，请忽略错误或手动注释掉相应的语句

-- 检查并添加 class_id 字段
SET @dbname = DATABASE();
SET @tablename = 'aiot_core_users';
SET @columnname = 'class_id';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      TABLE_SCHEMA = @dbname
      AND TABLE_NAME = @tablename
      AND COLUMN_NAME = @columnname
  ) > 0,
  'SELECT ''Column class_id already exists.'' AS message;',
  'ALTER TABLE `aiot_core_users` ADD COLUMN `class_id` INT NULL COMMENT ''所属班级ID（学生）'' AFTER `school_id`;'
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- 检查并添加 group_id 字段
SET @columnname = 'group_id';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      TABLE_SCHEMA = @dbname
      AND TABLE_NAME = @tablename
      AND COLUMN_NAME = @columnname
  ) > 0,
  'SELECT ''Column group_id already exists.'' AS message;',
  'ALTER TABLE `aiot_core_users` ADD COLUMN `group_id` INT NULL COMMENT ''所属小组ID（学生）'' AFTER `class_id`;'
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- 添加索引
-- 检查并添加 idx_class_id 索引
SET @indexname = 'idx_class_id';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE
      TABLE_SCHEMA = @dbname
      AND TABLE_NAME = @tablename
      AND INDEX_NAME = @indexname
  ) > 0,
  'SELECT ''Index idx_class_id already exists.'' AS message;',
  'ALTER TABLE `aiot_core_users` ADD INDEX `idx_class_id` (`class_id`);'
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- 检查并添加 idx_group_id 索引
SET @indexname = 'idx_group_id';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE
      TABLE_SCHEMA = @dbname
      AND TABLE_NAME = @tablename
      AND INDEX_NAME = @indexname
  ) > 0,
  'SELECT ''Index idx_group_id already exists.'' AS message;',
  'ALTER TABLE `aiot_core_users` ADD INDEX `idx_group_id` (`group_id`);'
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- ============================================================================
-- 5. 初始化数据（示例）
-- ============================================================================
-- 注意：这里只是示例，实际数据需要通过API创建

-- 示例：为示例学校创建一个班级
INSERT INTO `aiot_classes` 
    (`school_id`, `class_name`, `grade`, `class_number`, `academic_year`, `semester`, `description`)
VALUES 
    (1, '三年级1班', '三年级', '1班', '2024-2025', 'fall', '示例班级')
ON DUPLICATE KEY UPDATE `updated_at` = CURRENT_TIMESTAMP;

-- ============================================================================
-- 完成
-- ============================================================================

