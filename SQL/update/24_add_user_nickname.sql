-- ============================================================================
-- 为用户表添加昵称字段
-- 文件: 24_add_user_nickname.sql
-- 日期: 2025-11-27
-- 说明: 添加nickname字段，用于在智能体卡片等地方显示更友好的用户名
-- ============================================================================

-- 添加昵称字段
ALTER TABLE `aiot_core_users` 
ADD COLUMN `nickname` VARCHAR(50) NULL COMMENT '用户昵称（可选，优先显示）' 
AFTER `username`;

-- 创建索引（可选，如果需要按昵称搜索）
-- CREATE INDEX idx_nickname ON aiot_core_users(nickname);

-- 说明：
-- 1. nickname字段为可选，如果用户没有设置昵称，则显示username
-- 2. 昵称长度限制为50个字符
-- 3. 昵称不需要唯一性约束，多个用户可以使用相同的昵称

