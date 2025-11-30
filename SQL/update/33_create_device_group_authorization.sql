-- ============================================================================
-- 设备分组和授权管理系统
-- 功能：学校管理员将设备分组，并授权给课程使用
-- 创建时间：2025-11-29
-- ============================================================================

USE `aiot_platform`;

-- ============================================================================
-- 1. 设备分组表
-- ============================================================================

CREATE TABLE IF NOT EXISTS `aiot_device_groups` (
  `id` INT PRIMARY KEY AUTO_INCREMENT COMMENT '分组ID',
  `uuid` CHAR(36) UNIQUE NOT NULL COMMENT 'UUID，用于外部API访问',
  `school_id` INT NOT NULL COMMENT '所属学校ID',
  `group_name` VARCHAR(100) NOT NULL COMMENT '设备组名称',
  `group_code` VARCHAR(50) COMMENT '设备组编号',
  `description` TEXT COMMENT '描述',
  `device_count` INT DEFAULT 0 COMMENT '设备数量',
  `is_active` BOOLEAN DEFAULT TRUE COMMENT '是否激活',
  `created_by` INT COMMENT '创建人ID',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME COMMENT '软删除时间',
  
  INDEX `idx_school_id` (`school_id`),
  INDEX `idx_uuid` (`uuid`),
  INDEX `idx_is_active` (`is_active`),
  INDEX `idx_deleted_at` (`deleted_at`),
  
  FOREIGN KEY (`school_id`) REFERENCES `aiot_schools`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`created_by`) REFERENCES `aiot_core_users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备分组表';

-- ============================================================================
-- 2. 设备分组成员表
-- ============================================================================

CREATE TABLE IF NOT EXISTS `aiot_device_group_members` (
  `id` INT PRIMARY KEY AUTO_INCREMENT COMMENT '记录ID',
  `group_id` INT NOT NULL COMMENT '设备组ID',
  `device_id` INT NOT NULL COMMENT '设备ID',
  `joined_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
  `left_at` DATETIME COMMENT '离开时间',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  
  INDEX `idx_group_id` (`group_id`),
  INDEX `idx_device_id` (`device_id`),
  INDEX `idx_left_at` (`left_at`),
  
  UNIQUE KEY `uk_group_device` (`group_id`, `device_id`, `left_at`),
  
  FOREIGN KEY (`group_id`) REFERENCES `aiot_device_groups`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`device_id`) REFERENCES `aiot_core_devices`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备分组成员表';

-- ============================================================================
-- 3. 课程设备授权表
-- ============================================================================

CREATE TABLE IF NOT EXISTS `aiot_course_device_authorizations` (
  `id` INT PRIMARY KEY AUTO_INCREMENT COMMENT '授权ID',
  `uuid` CHAR(36) UNIQUE NOT NULL COMMENT 'UUID',
  `course_id` INT NOT NULL COMMENT '课程ID',
  `device_group_id` INT NOT NULL COMMENT '设备组ID',
  `authorized_by` INT NOT NULL COMMENT '授权人ID（学校管理员）',
  `authorized_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '授权时间',
  `expires_at` DATETIME COMMENT '过期时间',
  `is_active` BOOLEAN DEFAULT TRUE COMMENT '是否激活',
  `notes` TEXT COMMENT '备注',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  
  INDEX `idx_course_id` (`course_id`),
  INDEX `idx_device_group_id` (`device_group_id`),
  INDEX `idx_uuid` (`uuid`),
  INDEX `idx_authorized_by` (`authorized_by`),
  INDEX `idx_expires_at` (`expires_at`),
  INDEX `idx_is_active` (`is_active`),
  
  -- 同一课程可以授权同一设备组多次（但有效期不重叠）
  UNIQUE KEY `uk_course_group` (`course_id`, `device_group_id`, `expires_at`),
  
  FOREIGN KEY (`course_id`) REFERENCES `aiot_courses`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`device_group_id`) REFERENCES `aiot_device_groups`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`authorized_by`) REFERENCES `aiot_core_users`(`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='课程设备授权表';

-- ============================================================================
-- 4. 创建统计视图
-- ============================================================================

-- 4.1 设备组统计视图
CREATE OR REPLACE VIEW `v_device_group_statistics` AS
SELECT 
  dg.id AS group_id,
  dg.uuid AS group_uuid,
  dg.school_id,
  dg.group_name,
  dg.device_count,
  COUNT(DISTINCT dgm.device_id) AS actual_device_count,
  COUNT(DISTINCT cda.course_id) AS authorized_course_count,
  dg.is_active,
  dg.created_at
FROM `aiot_device_groups` dg
LEFT JOIN `aiot_device_group_members` dgm 
  ON dg.id = dgm.group_id AND dgm.left_at IS NULL
LEFT JOIN `aiot_course_device_authorizations` cda 
  ON dg.id = cda.device_group_id AND cda.is_active = TRUE
WHERE dg.deleted_at IS NULL
GROUP BY dg.id;

-- 4.2 课程授权设备视图
CREATE OR REPLACE VIEW `v_course_authorized_devices` AS
SELECT 
  c.id AS course_id,
  c.uuid AS course_uuid,
  c.course_name,
  dg.id AS device_group_id,
  dg.uuid AS device_group_uuid,
  dg.group_name AS device_group_name,
  cda.authorized_at,
  cda.expires_at,
  cda.is_active AS authorization_active,
  COUNT(DISTINCT dgm.device_id) AS device_count
FROM `aiot_courses` c
INNER JOIN `aiot_course_device_authorizations` cda ON c.id = cda.course_id
INNER JOIN `aiot_device_groups` dg ON cda.device_group_id = dg.id
LEFT JOIN `aiot_device_group_members` dgm 
  ON dg.id = dgm.group_id AND dgm.left_at IS NULL
WHERE c.deleted_at IS NULL 
  AND dg.deleted_at IS NULL
  AND cda.is_active = TRUE
GROUP BY c.id, dg.id, cda.id;

-- ============================================================================
-- 5. 初始化示例数据（可选）
-- ============================================================================

-- 为示例学校创建一个设备组
INSERT INTO `aiot_device_groups` 
  (`uuid`, `school_id`, `group_name`, `group_code`, `description`, `created_by`) 
SELECT 
  UUID(),
  s.id,
  '默认设备组',
  'DEFAULT-001',
  '学校默认设备组，包含所有可用设备',
  u.id
FROM `aiot_schools` s
INNER JOIN `aiot_core_users` u 
  ON s.id = u.school_id AND u.role = 'school_admin'
WHERE s.school_code = 'BJ-DEMO'
  AND NOT EXISTS (
    SELECT 1 FROM `aiot_device_groups` dg 
    WHERE dg.school_id = s.id AND dg.group_name = '默认设备组'
  )
LIMIT 1;

-- ============================================================================
-- 6. 添加注释说明
-- ============================================================================

/*
使用说明：
1. 设备分组：学校管理员可以创建多个设备组，将设备分类管理
2. 设备成员：一个设备可以属于多个设备组
3. 授权管理：学校管理员将设备组授权给课程使用
4. 时间限制：授权可以设置有效期（expires_at）
5. 多次授权：同一设备组可以授权给多个课程

业务流程：
1. 学校管理员创建设备组
2. 学校管理员添加设备到设备组
3. 教师创建课程
4. 学校管理员将设备组授权给课程
5. 教师和学生在课程中使用授权的设备

权限设计：
- 学校管理员：可以管理本校所有设备组和授权
- 教师：可以查看自己课程被授权的设备
- 学生：可以查看自己所在课程被授权的设备
*/

-- ============================================================================
-- SQL脚本执行完成
-- ============================================================================

SELECT '设备分组和授权管理系统创建成功！' AS message;

