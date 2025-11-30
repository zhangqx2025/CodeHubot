-- ============================================================================
-- 文件名: 31_simplify_class_teacher_student.sql
-- 描述: 简化班级-教师关系和学生信息
-- 作者: AI Assistant
-- 创建日期: 2025-11-29
-- ============================================================================

USE `aiot_platform`;

-- ============================================================================
-- 1. 简化班级-教师关联表：移除科目和班主任字段
-- ============================================================================

-- 删除 subject 字段（如果存在）
SET @dbname = 'aiot_platform';
SET @tablename = 'aiot_class_teachers';
SET @columnname = 'subject';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  CONCAT('ALTER TABLE `', @tablename, '` DROP COLUMN `', @columnname, '`'),
  'SELECT 1'
));
PREPARE alterIfExists FROM @preparedStatement;
EXECUTE alterIfExists;
DEALLOCATE PREPARE alterIfExists;

-- 删除 is_primary 字段（如果存在）
SET @columnname = 'is_primary';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  CONCAT('ALTER TABLE `', @tablename, '` DROP COLUMN `', @columnname, '`'),
  'SELECT 1'
));
PREPARE alterIfExists FROM @preparedStatement;
EXECUTE alterIfExists;
DEALLOCATE PREPARE alterIfExists;

-- 删除旧的唯一索引（如果存在）
SET @indexname = 'uk_class_teacher';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE 
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (INDEX_NAME = @indexname)
  ) > 0,
  CONCAT('ALTER TABLE `', @tablename, '` DROP INDEX `', @indexname, '`'),
  'SELECT 1'
));
PREPARE alterIfExists FROM @preparedStatement;
EXECUTE alterIfExists;
DEALLOCATE PREPARE alterIfExists;

-- 重建唯一索引
ALTER TABLE `aiot_class_teachers`
  ADD UNIQUE KEY `uk_class_teacher` (`class_id`, `teacher_id`);

-- 添加注释
ALTER TABLE `aiot_class_teachers` 
  COMMENT='班级-教师关联表（多对多，简化版）';

-- ============================================================================
-- 2. 简化用户表：为学生添加性别字段
-- ============================================================================

-- 检查并添加 gender 字段
SET @dbname = 'aiot_platform';
SET @tablename = 'aiot_core_users';
SET @columnname = 'gender';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  'SELECT 1',
  CONCAT('ALTER TABLE `', @tablename, '` ADD COLUMN `', @columnname, '` ENUM(''male'', ''female'', ''other'') DEFAULT NULL COMMENT ''性别：male-男, female-女, other-其他'' AFTER `real_name`')
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- 更新字段注释，明确学生必填字段
ALTER TABLE `aiot_core_users` 
  MODIFY COLUMN `real_name` VARCHAR(100) NULL COMMENT '真实姓名（学生必填）',
  MODIFY COLUMN `student_number` VARCHAR(50) NULL COMMENT '学号（学生必填）',
  MODIFY COLUMN `class_id` INT NULL COMMENT '所属班级ID（学生必填）',
  MODIFY COLUMN `email` VARCHAR(255) NULL COMMENT '邮箱（学生非必填）',
  MODIFY COLUMN `phone` VARCHAR(20) NULL COMMENT '电话（学生非必填）';

-- ============================================================================
-- 3. 更新视图：移除科目和班主任相关字段
-- ============================================================================

-- 重建班级教师视图（简化版）
DROP VIEW IF EXISTS `v_class_teachers`;
CREATE VIEW `v_class_teachers` AS
SELECT 
  ct.id AS relation_id,
  ct.class_id,
  c.class_name,
  c.school_id,
  ct.teacher_id,
  u.username AS teacher_username,
  u.real_name AS teacher_real_name,
  u.phone AS teacher_phone,
  u.email AS teacher_email,
  ct.created_at,
  ct.deleted_at
FROM aiot_class_teachers ct
JOIN aiot_classes c ON ct.class_id = c.id AND c.deleted_at IS NULL
JOIN aiot_core_users u ON ct.teacher_id = u.id AND u.deleted_at IS NULL
WHERE ct.deleted_at IS NULL;

-- 重建班级统计视图（简化版）
DROP VIEW IF EXISTS `v_class_statistics`;
CREATE VIEW `v_class_statistics` AS
SELECT 
  c.id AS class_id,
  c.uuid AS class_uuid,
  c.school_id,
  c.class_name,
  c.academic_year,
  c.semester,
  c.is_active,
  COUNT(DISTINCT ct.teacher_id) AS teacher_count,
  c.student_count,
  COUNT(DISTINCT g.id) AS group_count,
  c.created_at,
  c.updated_at
FROM aiot_classes c
LEFT JOIN aiot_class_teachers ct ON c.id = ct.class_id AND ct.deleted_at IS NULL
LEFT JOIN aiot_groups g ON c.id = g.class_id AND g.deleted_at IS NULL
WHERE c.deleted_at IS NULL
GROUP BY c.id, c.uuid, c.school_id, c.class_name, c.academic_year, c.semester, 
         c.is_active, c.student_count, c.created_at, c.updated_at;

-- 重建教师班级视图（简化版）
DROP VIEW IF EXISTS `v_teacher_classes`;
CREATE VIEW `v_teacher_classes` AS
SELECT 
  u.id AS teacher_id,
  u.username AS teacher_username,
  u.real_name AS teacher_real_name,
  u.school_id,
  COUNT(DISTINCT ct.class_id) AS class_count,
  GROUP_CONCAT(DISTINCT c.class_name ORDER BY c.class_name SEPARATOR ', ') AS class_names
FROM aiot_core_users u
LEFT JOIN aiot_class_teachers ct ON u.id = ct.teacher_id AND ct.deleted_at IS NULL
LEFT JOIN aiot_classes c ON ct.class_id = c.id AND c.deleted_at IS NULL
WHERE u.deleted_at IS NULL 
  AND u.role = 'teacher'
GROUP BY u.id, u.username, u.real_name, u.school_id;

-- ============================================================================
-- 4. 创建学生信息视图（简化版）
-- ============================================================================

DROP VIEW IF EXISTS `v_students`;
CREATE VIEW `v_students` AS
SELECT 
  u.id AS student_id,
  u.username,
  u.real_name,
  u.gender,
  u.student_number,
  u.school_id,
  u.class_id,
  c.class_name,
  u.group_id,
  g.group_name,
  u.is_active,
  u.created_at,
  u.updated_at
FROM aiot_core_users u
LEFT JOIN aiot_classes c ON u.class_id = c.id AND c.deleted_at IS NULL
LEFT JOIN aiot_groups g ON u.group_id = g.id AND g.deleted_at IS NULL
WHERE u.deleted_at IS NULL 
  AND u.role = 'student';

-- ============================================================================
-- 执行完成
-- ============================================================================

SELECT '✅ 已简化班级-教师关系（移除科目和班主任）' AS status;
SELECT '✅ 已为学生添加性别字段' AS status;
SELECT '✅ 已简化学生信息（必填：学号、姓名、性别、班级）' AS status;
SELECT '✅ 已更新所有相关视图' AS status;

