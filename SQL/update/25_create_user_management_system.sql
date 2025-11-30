-- ============================================================================
-- 用户管理模块数据库更新脚本
-- ============================================================================
-- 版本: V1.0
-- 创建日期: 2025-11-29
-- 说明: 实现用户管理模块的数据库结构
--       包含学校表、用户表扩展、角色定义等
-- ============================================================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

-- ============================================================================
-- 1. 创建学校表
-- ============================================================================

CREATE TABLE IF NOT EXISTS `aiot_schools` (
    `id` INT PRIMARY KEY AUTO_INCREMENT,
    `school_code` VARCHAR(50) UNIQUE NOT NULL COMMENT '学校代码（如 BJ-YCZX）',
    `school_name` VARCHAR(200) NOT NULL COMMENT '学校名称',
    `province` VARCHAR(50) COMMENT '省份',
    `city` VARCHAR(50) COMMENT '城市',
    `district` VARCHAR(50) COMMENT '区/县',
    `address` VARCHAR(500) COMMENT '详细地址',
    `contact_person` VARCHAR(100) COMMENT '联系人',
    `contact_phone` VARCHAR(20) COMMENT '联系电话',
    `contact_email` VARCHAR(255) COMMENT '联系邮箱',
    
    -- 状态
    `is_active` BOOLEAN DEFAULT TRUE COMMENT '是否激活',
    `license_expire_at` DATE COMMENT '授权到期时间',
    `max_teachers` INT DEFAULT 100 COMMENT '最大教师数',
    `max_students` INT DEFAULT 1000 COMMENT '最大学生数',
    `max_devices` INT DEFAULT 500 COMMENT '最大设备数',
    
    -- 时间戳
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- 索引
    UNIQUE KEY `uk_school_code` (`school_code`),
    INDEX `idx_province_city` (`province`, `city`),
    INDEX `idx_is_active` (`is_active`)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='学校表';

-- ============================================================================
-- 2. 扩展用户表字段
-- ============================================================================

-- 使用存储过程来安全地添加列（避免重复添加报错）
DELIMITER $$

-- 添加真实姓名字段
DROP PROCEDURE IF EXISTS add_real_name_column$$
CREATE PROCEDURE add_real_name_column()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'aiot_core_users' 
        AND COLUMN_NAME = 'real_name'
    ) THEN
        ALTER TABLE `aiot_core_users` 
        ADD COLUMN `real_name` VARCHAR(100) COMMENT '真实姓名' AFTER `name`;
    END IF;
END$$

-- 添加手机号字段
DROP PROCEDURE IF EXISTS add_phone_column$$
CREATE PROCEDURE add_phone_column()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'aiot_core_users' 
        AND COLUMN_NAME = 'phone'
    ) THEN
        ALTER TABLE `aiot_core_users` 
        ADD COLUMN `phone` VARCHAR(20) COMMENT '手机号' AFTER `email`;
    END IF;
END$$

-- 添加学校ID字段
DROP PROCEDURE IF EXISTS add_school_id_column$$
CREATE PROCEDURE add_school_id_column()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'aiot_core_users' 
        AND COLUMN_NAME = 'school_id'
    ) THEN
        ALTER TABLE `aiot_core_users` 
        ADD COLUMN `school_id` INT NULL COMMENT '所属学校ID（独立用户为NULL）' AFTER `role`;
    END IF;
END$$

-- 添加学校名称字段
DROP PROCEDURE IF EXISTS add_school_name_column$$
CREATE PROCEDURE add_school_name_column()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'aiot_core_users' 
        AND COLUMN_NAME = 'school_name'
    ) THEN
        ALTER TABLE `aiot_core_users` 
        ADD COLUMN `school_name` VARCHAR(200) COMMENT '学校名称（冗余字段，便于查询）' AFTER `school_id`;
    END IF;
END$$

-- 添加教师工号字段
DROP PROCEDURE IF EXISTS add_teacher_number_column$$
CREATE PROCEDURE add_teacher_number_column()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'aiot_core_users' 
        AND COLUMN_NAME = 'teacher_number'
    ) THEN
        ALTER TABLE `aiot_core_users` 
        ADD COLUMN `teacher_number` VARCHAR(50) COMMENT '教师工号（仅教师/学校管理员有）' AFTER `school_name`;
    END IF;
END$$

-- 添加学生学号字段
DROP PROCEDURE IF EXISTS add_student_number_column$$
CREATE PROCEDURE add_student_number_column()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'aiot_core_users' 
        AND COLUMN_NAME = 'student_number'
    ) THEN
        ALTER TABLE `aiot_core_users` 
        ADD COLUMN `student_number` VARCHAR(50) COMMENT '学生学号（仅学生有）' AFTER `teacher_number`;
    END IF;
END$$

-- 添加学科字段
DROP PROCEDURE IF EXISTS add_subject_column$$
CREATE PROCEDURE add_subject_column()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'aiot_core_users' 
        AND COLUMN_NAME = 'subject'
    ) THEN
        ALTER TABLE `aiot_core_users` 
        ADD COLUMN `subject` VARCHAR(50) COMMENT '教师学科' AFTER `student_number`;
    END IF;
END$$

-- 添加需要修改密码字段
DROP PROCEDURE IF EXISTS add_need_change_password_column$$
CREATE PROCEDURE add_need_change_password_column()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'aiot_core_users' 
        AND COLUMN_NAME = 'need_change_password'
    ) THEN
        ALTER TABLE `aiot_core_users` 
        ADD COLUMN `need_change_password` BOOLEAN DEFAULT FALSE COMMENT '首次登录需修改密码' AFTER `is_active`;
    END IF;
END$$

-- 添加最后登录IP字段
DROP PROCEDURE IF EXISTS add_last_login_ip_column$$
CREATE PROCEDURE add_last_login_ip_column()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'aiot_core_users' 
        AND COLUMN_NAME = 'last_login_ip'
    ) THEN
        ALTER TABLE `aiot_core_users` 
        ADD COLUMN `last_login_ip` VARCHAR(50) COMMENT '最后登录IP' AFTER `last_login`;
    END IF;
END$$

-- 添加软删除字段
DROP PROCEDURE IF EXISTS add_deleted_at_column$$
CREATE PROCEDURE add_deleted_at_column()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 'aiot_core_users' 
        AND COLUMN_NAME = 'deleted_at'
    ) THEN
        ALTER TABLE `aiot_core_users` 
        ADD COLUMN `deleted_at` DATETIME COMMENT '软删除时间' AFTER `updated_at`;
    END IF;
END$$

DELIMITER ;

-- 执行所有存储过程
CALL add_real_name_column();
CALL add_phone_column();
CALL add_school_id_column();
CALL add_school_name_column();
CALL add_teacher_number_column();
CALL add_student_number_column();
CALL add_subject_column();
CALL add_need_change_password_column();
CALL add_last_login_ip_column();
CALL add_deleted_at_column();

-- 删除存储过程
DROP PROCEDURE IF EXISTS add_real_name_column;
DROP PROCEDURE IF EXISTS add_phone_column;
DROP PROCEDURE IF EXISTS add_school_id_column;
DROP PROCEDURE IF EXISTS add_school_name_column;
DROP PROCEDURE IF EXISTS add_teacher_number_column;
DROP PROCEDURE IF EXISTS add_student_number_column;
DROP PROCEDURE IF EXISTS add_subject_column;
DROP PROCEDURE IF EXISTS add_need_change_password_column;
DROP PROCEDURE IF EXISTS add_last_login_ip_column;
DROP PROCEDURE IF EXISTS add_deleted_at_column;

-- ============================================================================
-- 3. 修改role字段（支持新角色）
-- ============================================================================

-- 先删除旧的role字段的约束（如果有）
ALTER TABLE `aiot_core_users` 
MODIFY COLUMN `role` VARCHAR(50) NOT NULL DEFAULT 'individual' 
COMMENT '用户角色：individual/platform_admin/school_admin/teacher/student';

-- ============================================================================
-- 4. 添加外键约束
-- ============================================================================

-- 添加学校外键约束
ALTER TABLE `aiot_core_users` 
ADD CONSTRAINT `fk_users_school` 
FOREIGN KEY (`school_id`) REFERENCES `aiot_schools`(`id`) ON DELETE SET NULL;

-- ============================================================================
-- 5. 添加唯一性约束
-- ============================================================================

-- 学校内工号唯一
ALTER TABLE `aiot_core_users` 
ADD UNIQUE KEY `uk_school_teacher_number` (`school_id`, `teacher_number`);

-- 学校内学号唯一
ALTER TABLE `aiot_core_users` 
ADD UNIQUE KEY `uk_school_student_number` (`school_id`, `student_number`);

-- ============================================================================
-- 6. 添加索引优化查询
-- ============================================================================

ALTER TABLE `aiot_core_users` 
ADD INDEX `idx_school_id` (`school_id`),
ADD INDEX `idx_teacher_number` (`teacher_number`),
ADD INDEX `idx_student_number` (`student_number`),
ADD INDEX `idx_real_name` (`real_name`),
ADD INDEX `idx_deleted_at` (`deleted_at`);

-- ============================================================================
-- 7. 更新现有数据（将现有用户设置为独立用户）
-- ============================================================================

-- 将现有的普通用户(role='user')更新为独立用户
UPDATE `aiot_core_users` 
SET `role` = 'individual' 
WHERE `role` = 'user' AND `school_id` IS NULL;

-- 将现有的管理员(role='admin')更新为平台管理员
UPDATE `aiot_core_users` 
SET `role` = 'platform_admin' 
WHERE `role` = 'admin';

-- 设置name字段为real_name（如果real_name为空）
UPDATE `aiot_core_users` 
SET `real_name` = `name` 
WHERE `real_name` IS NULL AND `name` IS NOT NULL;

-- ============================================================================
-- 8. 插入示例数据（可选）
-- ============================================================================

-- 插入示例学校
INSERT INTO `aiot_schools` 
    (`school_code`, `school_name`, `province`, `city`, `district`, `address`, 
     `contact_person`, `contact_phone`, `is_active`) 
VALUES 
    ('BJ-DEMO', '示例学校', '北京市', '北京市', '海淀区', 
     '海淀区示例路1号', '张校长', '010-12345678', TRUE)
ON DUPLICATE KEY UPDATE `school_name` = `school_name`;

-- ============================================================================
-- 9. 数据库表关系说明
-- ============================================================================

-- 用户表 (aiot_core_users) 与学校表 (aiot_schools) 的关系：
-- - 独立用户: school_id = NULL, role = 'individual'
-- - 平台管理员: school_id = NULL, role = 'platform_admin'
-- - 学校管理员: school_id = 学校ID, role = 'school_admin'
-- - 教师: school_id = 学校ID, role = 'teacher'
-- - 学生: school_id = 学校ID, role = 'student'

-- ============================================================================
-- 完成
-- ============================================================================

COMMIT;

-- 查看修改后的表结构
SHOW CREATE TABLE aiot_core_users;
SHOW CREATE TABLE aiot_schools;

-- 查看用户统计
SELECT 
    role,
    COUNT(*) as user_count,
    COUNT(DISTINCT school_id) as school_count
FROM aiot_core_users
WHERE deleted_at IS NULL
GROUP BY role;

