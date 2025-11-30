-- ============================================================================
-- 文件名: 30_class_teacher_relation.sql
-- 描述: 调整班级-教师关系为多对多
-- 作者: AI Assistant
-- 创建日期: 2025-11-29
-- ============================================================================

USE `aiot_platform`;

-- ============================================================================
-- 1. 创建班级-教师关联表（多对多关系）
-- ============================================================================

CREATE TABLE IF NOT EXISTS `aiot_class_teachers` (
  `id` INT PRIMARY KEY AUTO_INCREMENT COMMENT '主键ID',
  `class_id` INT NOT NULL COMMENT '班级ID',
  `teacher_id` INT NOT NULL COMMENT '教师ID',
  `subject` VARCHAR(50) NULL COMMENT '教师在该班级教授的科目',
  `is_primary` TINYINT(1) DEFAULT 0 COMMENT '是否为班主任',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `deleted_at` DATETIME NULL COMMENT '删除时间（软删除）',
  UNIQUE KEY `uk_class_teacher` (`class_id`, `teacher_id`, `deleted_at`),
  KEY `idx_class_id` (`class_id`),
  KEY `idx_teacher_id` (`teacher_id`),
  CONSTRAINT `fk_ct_class` FOREIGN KEY (`class_id`) REFERENCES `aiot_classes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ct_teacher` FOREIGN KEY (`teacher_id`) REFERENCES `aiot_core_users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='班级-教师关联表（多对多）';

-- ============================================================================
-- 2. 迁移现有数据：从 aiot_classes.teacher_id 到关联表
-- ============================================================================

-- 将现有的班级教师关系迁移到关联表
INSERT INTO `aiot_class_teachers` (`class_id`, `teacher_id`, `is_primary`, `created_at`)
SELECT 
  `id` AS `class_id`,
  `teacher_id`,
  1 AS `is_primary`,  -- 现有教师设为班主任
  `created_at`
FROM `aiot_classes`
WHERE `teacher_id` IS NOT NULL 
  AND `deleted_at` IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM `aiot_class_teachers` 
    WHERE `class_id` = `aiot_classes`.`id` 
      AND `teacher_id` = `aiot_classes`.`teacher_id`
  );

-- ============================================================================
-- 3. 调整 aiot_classes 表结构
-- ============================================================================

-- 检查并删除 teacher_id 和 teacher_name 列（保留用于兼容，但不再使用）
-- 注意：不直接删除，而是标记为废弃，以保持向后兼容

-- 添加注释说明这些字段已废弃
ALTER TABLE `aiot_classes` 
  MODIFY COLUMN `teacher_id` INT NULL COMMENT '教师ID（已废弃，使用 aiot_class_teachers 表）',
  MODIFY COLUMN `teacher_name` VARCHAR(100) NULL COMMENT '教师姓名（已废弃，使用 aiot_class_teachers 表）';

-- ============================================================================
-- 4. 调整 aiot_core_users 表 - 学生必须有班级
-- ============================================================================

-- 为学生角色添加班级约束的说明（通过应用层控制，数据库层保持灵活）
-- 添加注释
ALTER TABLE `aiot_core_users` 
  MODIFY COLUMN `class_id` INT NULL COMMENT '所属班级ID（学生必填，教师可选）';

-- ============================================================================
-- 5. 创建视图：便捷查询班级教师信息
-- ============================================================================

-- 删除旧视图（如果存在）
DROP VIEW IF EXISTS `v_class_teachers`;

-- 创建班级教师视图
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
  ct.subject,
  ct.is_primary,
  ct.created_at,
  ct.deleted_at
FROM aiot_class_teachers ct
JOIN aiot_classes c ON ct.class_id = c.id AND c.deleted_at IS NULL
JOIN aiot_core_users u ON ct.teacher_id = u.id AND u.deleted_at IS NULL
WHERE ct.deleted_at IS NULL;

-- ============================================================================
-- 6. 创建视图：班级统计信息（包含教师数量）
-- ============================================================================

-- 删除旧视图（如果存在）
DROP VIEW IF EXISTS `v_class_statistics`;

-- 创建班级统计视图
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
  COUNT(DISTINCT CASE WHEN ct.is_primary = 1 THEN ct.teacher_id END) AS primary_teacher_count,
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

-- ============================================================================
-- 7. 创建视图：教师班级信息（教师维度）
-- ============================================================================

-- 删除旧视图（如果存在）
DROP VIEW IF EXISTS `v_teacher_classes`;

-- 创建教师班级视图
CREATE VIEW `v_teacher_classes` AS
SELECT 
  u.id AS teacher_id,
  u.username AS teacher_username,
  u.real_name AS teacher_real_name,
  u.school_id,
  COUNT(DISTINCT ct.class_id) AS class_count,
  COUNT(DISTINCT CASE WHEN ct.is_primary = 1 THEN ct.class_id END) AS primary_class_count,
  GROUP_CONCAT(DISTINCT c.class_name ORDER BY c.class_name SEPARATOR ', ') AS class_names
FROM aiot_core_users u
LEFT JOIN aiot_class_teachers ct ON u.id = ct.teacher_id AND ct.deleted_at IS NULL
LEFT JOIN aiot_classes c ON ct.class_id = c.id AND c.deleted_at IS NULL
WHERE u.deleted_at IS NULL 
  AND u.role = 'teacher'
GROUP BY u.id, u.username, u.real_name, u.school_id;

-- ============================================================================
-- 执行完成
-- ============================================================================

SELECT '✅ 班级-教师多对多关系表创建完成' AS status;
SELECT '✅ 已迁移现有班级教师数据到关联表' AS status;
SELECT '✅ 已创建便捷查询视图' AS status;
SELECT CONCAT('📊 当前班级-教师关联数: ', COUNT(*), '条') AS status FROM aiot_class_teachers WHERE deleted_at IS NULL;

