-- ============================================================================
-- 文件名: 32_refactor_to_course_system.sql
-- 描述: 将班级制改为选课制 - 学生可以选择多个课程
-- 作者: AI Assistant
-- 创建日期: 2025-11-29
-- ============================================================================

USE `aiot_platform`;

-- ============================================================================
-- 1. 重命名表：班级 → 课程
-- ============================================================================

-- 重命名主表
ALTER TABLE `aiot_classes` RENAME TO `aiot_courses`;

-- 重命名教师关联表
ALTER TABLE `aiot_class_teachers` RENAME TO `aiot_course_teachers`;

-- 重命名分组表（如果需要分组的话，分组也应该属于课程）
ALTER TABLE `aiot_groups` RENAME TO `aiot_course_groups`;

-- ============================================================================
-- 2. 调整 aiot_courses 表结构
-- ============================================================================

-- 2.1 修改字段名
ALTER TABLE `aiot_courses`
  CHANGE COLUMN `class_name` `course_name` VARCHAR(100) NOT NULL COMMENT '课程名称',
  CHANGE COLUMN `class_number` `course_code` VARCHAR(20) NULL COMMENT '课程编号';

-- 2.2 删除 teacher_id 字段（如果存在）
SET @dbname = 'aiot_platform';
SET @tablename = 'aiot_courses';
SET @columnname = 'teacher_id';
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

-- 2.3 删除 teacher_name 字段（如果存在）
SET @columnname = 'teacher_name';
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

-- 2.4 删除 grade 字段（如果存在）
SET @columnname = 'grade';
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

-- 2.5 修改现有字段
ALTER TABLE `aiot_courses`
  MODIFY COLUMN `academic_year` VARCHAR(20) NULL COMMENT '学年（可选）',
  MODIFY COLUMN `semester` ENUM('spring', 'fall') NULL COMMENT '学期：spring-春季, fall-秋季',
  MODIFY COLUMN `student_count` INT DEFAULT 0 COMMENT '选课学生人数',
  MODIFY COLUMN `description` TEXT NULL COMMENT '课程描述';

-- 2.6 添加新字段 max_students（如果不存在）
SET @columnname = 'max_students';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  'SELECT 1',
  CONCAT('ALTER TABLE `', @tablename, '` ADD COLUMN `', @columnname, '` INT DEFAULT 100 COMMENT ''最大学生人数'' AFTER `student_count`')
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- 2.7 添加新字段 teacher_count（如果不存在）
SET @columnname = 'teacher_count';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  'SELECT 1',
  CONCAT('ALTER TABLE `', @tablename, '` ADD COLUMN `', @columnname, '` INT DEFAULT 0 COMMENT ''授课教师人数'' AFTER `max_students`')
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- 2.8 添加新字段 credits（如果不存在）
SET @columnname = 'credits';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  'SELECT 1',
  CONCAT('ALTER TABLE `', @tablename, '` ADD COLUMN `', @columnname, '` DECIMAL(3,1) DEFAULT 0 COMMENT ''学分'' AFTER `teacher_count`')
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- 2.9 更新表注释
ALTER TABLE `aiot_courses` COMMENT='课程表';

-- ============================================================================
-- 3. 创建学生-课程关联表（多对多）
-- ============================================================================

CREATE TABLE IF NOT EXISTS `aiot_course_students` (
  `id` INT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
  `course_id` INT NOT NULL COMMENT '课程ID',
  `student_id` INT NOT NULL COMMENT '学生ID',
  `enrolled_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '选课时间',
  `status` ENUM('enrolled', 'completed', 'dropped') DEFAULT 'enrolled' COMMENT '状态：enrolled-在读, completed-已完成, dropped-已退课',
  `score` DECIMAL(5,2) NULL COMMENT '成绩',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `deleted_at` DATETIME NULL COMMENT '删除时间（软删除）',
  UNIQUE KEY `uk_course_student` (`course_id`, `student_id`),
  KEY `idx_course_id` (`course_id`),
  KEY `idx_student_id` (`student_id`),
  KEY `idx_status` (`status`),
  CONSTRAINT `fk_cs_course` FOREIGN KEY (`course_id`) REFERENCES `aiot_courses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_cs_student` FOREIGN KEY (`student_id`) REFERENCES `aiot_core_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='学生-课程关联表（选课记录）';

-- ============================================================================
-- 4. 调整教师-课程关联表
-- ============================================================================

-- 4.1 删除旧的外键约束 fk_ct_class（如果存在）
SET @dbname = 'aiot_platform';
SET @tablename = 'aiot_course_teachers';
SET @constraintname = 'fk_ct_class';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE 
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (CONSTRAINT_NAME = @constraintname)
  ) > 0,
  CONCAT('ALTER TABLE `', @tablename, '` DROP FOREIGN KEY `', @constraintname, '`'),
  'SELECT 1'
));
PREPARE alterIfExists FROM @preparedStatement;
EXECUTE alterIfExists;
DEALLOCATE PREPARE alterIfExists;

-- 4.2 删除旧的外键约束 fk_ct_teacher（如果存在）
SET @constraintname = 'fk_ct_teacher';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE 
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (CONSTRAINT_NAME = @constraintname)
  ) > 0,
  CONCAT('ALTER TABLE `', @tablename, '` DROP FOREIGN KEY `', @constraintname, '`'),
  'SELECT 1'
));
PREPARE alterIfExists FROM @preparedStatement;
EXECUTE alterIfExists;
DEALLOCATE PREPARE alterIfExists;

-- 4.3 重命名字段 class_id → course_id
ALTER TABLE `aiot_course_teachers`
  CHANGE COLUMN `class_id` `course_id` INT NOT NULL COMMENT '课程ID';

-- 4.4 重新添加外键约束
ALTER TABLE `aiot_course_teachers`
  ADD CONSTRAINT `fk_ct_course` FOREIGN KEY (`course_id`) REFERENCES `aiot_courses` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_ct_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `aiot_core_users` (`id`) ON DELETE CASCADE;

-- 4.5 更新表注释
ALTER TABLE `aiot_course_teachers` COMMENT='教师-课程关联表（多对多）';

-- ============================================================================
-- 5. 调整分组表结构
-- ============================================================================

-- 5.1 删除旧外键 aiot_groups_ibfk_1（如果存在）
SET @dbname = 'aiot_platform';
SET @tablename = 'aiot_course_groups';
SET @constraintname = 'aiot_groups_ibfk_1';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE 
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (CONSTRAINT_NAME = @constraintname)
  ) > 0,
  CONCAT('ALTER TABLE `', @tablename, '` DROP FOREIGN KEY `', @constraintname, '`'),
  'SELECT 1'
));
PREPARE alterIfExists FROM @preparedStatement;
EXECUTE alterIfExists;
DEALLOCATE PREPARE alterIfExists;

-- 5.2 修改字段名 class_id → course_id
ALTER TABLE `aiot_course_groups`
  CHANGE COLUMN `class_id` `course_id` INT NOT NULL COMMENT '所属课程ID';

-- 5.3 添加新外键约束
ALTER TABLE `aiot_course_groups`
  ADD CONSTRAINT `fk_cg_course` FOREIGN KEY (`course_id`) REFERENCES `aiot_courses` (`id`) ON DELETE CASCADE;

-- 5.4 更新表注释
ALTER TABLE `aiot_course_groups` COMMENT='课程分组表';

-- ============================================================================
-- 6. 调整分组成员表结构
-- ============================================================================

-- 6.1 删除旧外键 aiot_group_members_ibfk_2（如果存在）
SET @dbname = 'aiot_platform';
SET @tablename = 'aiot_group_members';
SET @constraintname = 'aiot_group_members_ibfk_2';
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE 
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (CONSTRAINT_NAME = @constraintname)
  ) > 0,
  CONCAT('ALTER TABLE `', @tablename, '` DROP FOREIGN KEY `', @constraintname, '`'),
  'SELECT 1'
));
PREPARE alterIfExists FROM @preparedStatement;
EXECUTE alterIfExists;
DEALLOCATE PREPARE alterIfExists;

-- 6.2 修改字段名 class_id → course_id
ALTER TABLE `aiot_group_members`
  CHANGE COLUMN `class_id` `course_id` INT NOT NULL COMMENT '课程ID';

-- 6.3 添加新外键约束
ALTER TABLE `aiot_group_members`
  ADD CONSTRAINT `fk_gm_course` FOREIGN KEY (`course_id`) REFERENCES `aiot_courses` (`id`) ON DELETE CASCADE;

-- ============================================================================
-- 7. 调整用户表：移除 class_id（学生可选多门课程）
-- ============================================================================

-- 7.1 删除 class_id 字段（如果存在）
SET @dbname = 'aiot_platform';
SET @tablename = 'aiot_core_users';
SET @columnname = 'class_id';
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

-- 7.2 删除 group_id 字段（如果存在）
SET @columnname = 'group_id';
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

-- ============================================================================
-- 8. 迁移现有数据：从班级学生关系到选课记录
-- ============================================================================

-- 注意：如果 aiot_core_users 已经删除了 class_id，这部分可能需要手动处理
-- 这里假设还有旧数据需要迁移

-- 如果有备份的 class_id 数据，可以这样迁移：
-- INSERT INTO `aiot_course_students` (`course_id`, `student_id`, `status`)
-- SELECT 
--   u.class_id AS course_id,
--   u.id AS student_id,
--   'enrolled' AS status
-- FROM aiot_core_users u
-- WHERE u.class_id IS NOT NULL 
--   AND u.role = 'student'
--   AND u.deleted_at IS NULL
--   AND NOT EXISTS (
--     SELECT 1 FROM aiot_course_students cs
--     WHERE cs.course_id = u.class_id AND cs.student_id = u.id
--   );

-- ============================================================================
-- 9. 创建视图：课程教师信息
-- ============================================================================

DROP VIEW IF EXISTS `v_course_teachers`;
CREATE VIEW `v_course_teachers` AS
SELECT 
  ct.id AS relation_id,
  ct.course_id,
  c.course_name,
  c.school_id,
  ct.teacher_id,
  u.username AS teacher_username,
  u.real_name AS teacher_real_name,
  u.phone AS teacher_phone,
  u.email AS teacher_email,
  ct.created_at,
  ct.deleted_at
FROM aiot_course_teachers ct
JOIN aiot_courses c ON ct.course_id = c.id AND c.deleted_at IS NULL
JOIN aiot_core_users u ON ct.teacher_id = u.id AND u.deleted_at IS NULL
WHERE ct.deleted_at IS NULL;

-- ============================================================================
-- 10. 创建视图：课程学生信息
-- ============================================================================

DROP VIEW IF EXISTS `v_course_students`;
CREATE VIEW `v_course_students` AS
SELECT 
  cs.id AS relation_id,
  cs.course_id,
  c.course_name,
  c.school_id,
  cs.student_id,
  u.username AS student_username,
  u.real_name AS student_real_name,
  u.gender AS student_gender,
  u.student_number,
  cs.status,
  cs.score,
  cs.enrolled_at,
  cs.created_at,
  cs.deleted_at
FROM aiot_course_students cs
JOIN aiot_courses c ON cs.course_id = c.id AND c.deleted_at IS NULL
JOIN aiot_core_users u ON cs.student_id = u.id AND u.deleted_at IS NULL
WHERE cs.deleted_at IS NULL;

-- ============================================================================
-- 11. 创建视图：课程统计信息
-- ============================================================================

DROP VIEW IF EXISTS `v_course_statistics`;
CREATE VIEW `v_course_statistics` AS
SELECT 
  c.id AS course_id,
  c.uuid AS course_uuid,
  c.school_id,
  c.course_name,
  c.course_code,
  c.academic_year,
  c.semester,
  c.credits,
  c.is_active,
  COUNT(DISTINCT ct.teacher_id) AS teacher_count,
  COUNT(DISTINCT cs.student_id) AS student_count,
  COUNT(DISTINCT g.id) AS group_count,
  c.created_at,
  c.updated_at
FROM aiot_courses c
LEFT JOIN aiot_course_teachers ct ON c.id = ct.course_id AND ct.deleted_at IS NULL
LEFT JOIN aiot_course_students cs ON c.id = cs.course_id AND cs.deleted_at IS NULL AND cs.status = 'enrolled'
LEFT JOIN aiot_course_groups g ON c.id = g.course_id AND g.deleted_at IS NULL
WHERE c.deleted_at IS NULL
GROUP BY c.id, c.uuid, c.school_id, c.course_name, c.course_code, c.academic_year, 
         c.semester, c.credits, c.is_active, c.created_at, c.updated_at;

-- ============================================================================
-- 12. 创建视图：教师课程信息
-- ============================================================================

DROP VIEW IF EXISTS `v_teacher_courses`;
CREATE VIEW `v_teacher_courses` AS
SELECT 
  u.id AS teacher_id,
  u.username AS teacher_username,
  u.real_name AS teacher_real_name,
  u.school_id,
  COUNT(DISTINCT ct.course_id) AS course_count,
  GROUP_CONCAT(DISTINCT c.course_name ORDER BY c.course_name SEPARATOR ', ') AS course_names
FROM aiot_core_users u
LEFT JOIN aiot_course_teachers ct ON u.id = ct.teacher_id AND ct.deleted_at IS NULL
LEFT JOIN aiot_courses c ON ct.course_id = c.id AND c.deleted_at IS NULL
WHERE u.deleted_at IS NULL 
  AND u.role = 'teacher'
GROUP BY u.id, u.username, u.real_name, u.school_id;

-- ============================================================================
-- 13. 创建视图：学生课程信息
-- ============================================================================

DROP VIEW IF EXISTS `v_student_courses`;
CREATE VIEW `v_student_courses` AS
SELECT 
  u.id AS student_id,
  u.username AS student_username,
  u.real_name AS student_real_name,
  u.gender,
  u.student_number,
  u.school_id,
  COUNT(DISTINCT cs.course_id) AS course_count,
  COUNT(DISTINCT CASE WHEN cs.status = 'enrolled' THEN cs.course_id END) AS enrolled_count,
  COUNT(DISTINCT CASE WHEN cs.status = 'completed' THEN cs.course_id END) AS completed_count,
  SUM(CASE WHEN cs.status = 'completed' AND c.credits IS NOT NULL THEN c.credits ELSE 0 END) AS total_credits,
  GROUP_CONCAT(DISTINCT c.course_name ORDER BY c.course_name SEPARATOR ', ') AS course_names
FROM aiot_core_users u
LEFT JOIN aiot_course_students cs ON u.id = cs.student_id AND cs.deleted_at IS NULL
LEFT JOIN aiot_courses c ON cs.course_id = c.id AND c.deleted_at IS NULL
WHERE u.deleted_at IS NULL 
  AND u.role = 'student'
GROUP BY u.id, u.username, u.real_name, u.gender, u.student_number, u.school_id;

-- ============================================================================
-- 执行完成
-- ============================================================================

SELECT '✅ 已重命名：班级(classes) → 课程(courses)' AS status;
SELECT '✅ 已创建：学生-课程关联表（多对多选课）' AS status;
SELECT '✅ 已调整：教师-课程关联表' AS status;
SELECT '✅ 已移除：用户表的 class_id（学生可选多门课）' AS status;
SELECT '✅ 已创建：5个课程管理视图' AS status;
SELECT CONCAT('📊 当前课程数: ', COUNT(*), '门') AS status FROM aiot_courses WHERE deleted_at IS NULL;
SELECT CONCAT('📊 当前选课记录: ', COUNT(*), '条') AS status FROM aiot_course_students WHERE deleted_at IS NULL;

