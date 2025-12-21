-- ================================================================
-- AI对话记录表 - 用于分析学生学习行为和AI交互情况
-- 创建时间: 2024-12-20
-- 说明: 
--   - pbl_ai_chat_sessions: 对话会话表，记录每次学习会话
--   - pbl_ai_chat_messages: 对话消息表，记录每条问答
-- 用途:
--   - 分析学生提问频率和类型
--   - 评估AI回复质量
--   - 发现常见问题和痛点
--   - 优化课程内容
-- ================================================================

-- ===== 1. AI对话会话表 =====
CREATE TABLE IF NOT EXISTS `pbl_ai_chat_sessions` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `uuid` VARCHAR(36) NOT NULL COMMENT '会话唯一标识',
  
  -- 关联信息
  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',
  `student_id` BIGINT(20) DEFAULT NULL COMMENT '学生ID（如果是学生）',
  `course_id` BIGINT(20) DEFAULT NULL COMMENT '课程ID',
  `course_uuid` VARCHAR(36) DEFAULT NULL COMMENT '课程UUID',
  `unit_id` BIGINT(20) DEFAULT NULL COMMENT '单元ID',
  `unit_uuid` VARCHAR(36) DEFAULT NULL COMMENT '单元UUID',
  
  -- 会话统计
  `message_count` INT(11) DEFAULT 0 COMMENT '消息总数',
  `user_message_count` INT(11) DEFAULT 0 COMMENT '用户消息数',
  `ai_message_count` INT(11) DEFAULT 0 COMMENT 'AI回复数',
  `helpful_count` INT(11) DEFAULT 0 COMMENT '有帮助的回复数（被点赞）',
  
  -- 会话时长
  `started_at` DATETIME NOT NULL COMMENT '会话开始时间',
  `ended_at` DATETIME DEFAULT NULL COMMENT '会话结束时间',
  `duration_seconds` INT(11) DEFAULT 0 COMMENT '会话时长（秒）',
  
  -- 会话状态
  `status` VARCHAR(20) DEFAULT 'active' COMMENT '会话状态: active-进行中, completed-已完成, abandoned-已放弃',
  `is_anonymous` TINYINT(1) DEFAULT 0 COMMENT '是否匿名（隐私模式）',
  
  -- 设备和环境信息
  `device_type` VARCHAR(50) DEFAULT NULL COMMENT '设备类型',
  `browser_type` VARCHAR(50) DEFAULT NULL COMMENT '浏览器类型',
  `ip_address` VARCHAR(50) DEFAULT NULL COMMENT 'IP地址',
  
  -- 通用字段
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_student_id` (`student_id`),
  KEY `idx_unit_uuid` (`unit_uuid`),
  KEY `idx_course_uuid` (`course_uuid`),
  KEY `idx_started_at` (`started_at`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL-AI对话会话表';

-- ===== 2. AI对话消息表 =====
CREATE TABLE IF NOT EXISTS `pbl_ai_chat_messages` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `uuid` VARCHAR(36) NOT NULL COMMENT '消息唯一标识',
  
  -- 关联信息
  `session_id` BIGINT(20) NOT NULL COMMENT '会话ID',
  `session_uuid` VARCHAR(36) NOT NULL COMMENT '会话UUID',
  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',
  `unit_uuid` VARCHAR(36) DEFAULT NULL COMMENT '单元UUID',
  
  -- 消息内容
  `message_type` VARCHAR(20) NOT NULL COMMENT '消息类型: user-用户消息, ai-AI回复, system-系统消息',
  `content` TEXT NOT NULL COMMENT '消息内容',
  `content_length` INT(11) DEFAULT 0 COMMENT '内容长度（字符数）',
  
  -- 消息顺序和时间
  `sequence_number` INT(11) NOT NULL COMMENT '消息序号（会话内）',
  `sent_at` DATETIME NOT NULL COMMENT '发送时间',
  `response_time_ms` INT(11) DEFAULT NULL COMMENT 'AI响应时长（毫秒）',
  
  -- AI相关信息（仅AI消息）
  `ai_model` VARCHAR(50) DEFAULT NULL COMMENT 'AI模型名称',
  `ai_provider` VARCHAR(50) DEFAULT NULL COMMENT 'AI服务提供商',
  `ai_tokens_used` INT(11) DEFAULT NULL COMMENT '使用的token数',
  `ai_confidence` DECIMAL(5,2) DEFAULT NULL COMMENT 'AI回复置信度',
  
  -- 用户反馈
  `is_helpful` TINYINT(1) DEFAULT NULL COMMENT '是否有帮助（用户点赞）',
  `feedback_at` DATETIME DEFAULT NULL COMMENT '反馈时间',
  
  -- 分类和标签
  `category` VARCHAR(50) DEFAULT NULL COMMENT '问题分类: concept-概念, task-任务, resource-资源, debug-调试, other-其他',
  `tags` VARCHAR(255) DEFAULT NULL COMMENT '标签（JSON数组或逗号分隔）',
  `intent` VARCHAR(50) DEFAULT NULL COMMENT '用户意图',
  
  -- 上下文信息
  `context_data` TEXT DEFAULT NULL COMMENT '上下文数据（JSON格式）',
  
  -- 通用字段
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_session_id` (`session_id`),
  KEY `idx_session_uuid` (`session_uuid`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_unit_uuid` (`unit_uuid`),
  KEY `idx_message_type` (`message_type`),
  KEY `idx_sent_at` (`sent_at`),
  KEY `idx_category` (`category`),
  KEY `idx_is_helpful` (`is_helpful`),
  KEY `idx_sequence` (`session_id`, `sequence_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL-AI对话消息表';

-- ===== 3. 添加外键约束（可选，视性能需求） =====
-- ALTER TABLE `pbl_ai_chat_messages` 
--   ADD CONSTRAINT `fk_chat_message_session` 
--   FOREIGN KEY (`session_id`) REFERENCES `pbl_ai_chat_sessions` (`id`) 
--   ON DELETE CASCADE;

-- ===== 4. 常用查询示例（替代视图） =====

-- 示例1：学生问题统计查询
-- SELECT 
--   u.id as user_id,
--   u.username,
--   u.full_name,
--   COUNT(DISTINCT s.id) as total_sessions,
--   COUNT(CASE WHEN m.message_type = 'user' THEN 1 END) as total_questions,
--   COUNT(CASE WHEN m.is_helpful = 1 THEN 1 END) as helpful_answers,
--   AVG(s.duration_seconds) as avg_session_duration,
--   MAX(s.started_at) as last_chat_time
-- FROM aiot_core_users u
-- LEFT JOIN pbl_ai_chat_sessions s ON u.id = s.user_id
-- LEFT JOIN pbl_ai_chat_messages m ON s.id = m.session_id
-- WHERE u.id = ?
-- GROUP BY u.id, u.username, u.full_name;

-- 示例2：单元热门问题查询
-- SELECT 
--   unit_uuid,
--   content as question,
--   COUNT(*) as ask_count,
--   AVG(CASE WHEN next_m.is_helpful = 1 THEN 1 ELSE 0 END) as helpful_rate
-- FROM pbl_ai_chat_messages m
-- LEFT JOIN pbl_ai_chat_messages next_m 
--   ON m.session_id = next_m.session_id 
--   AND m.sequence_number + 1 = next_m.sequence_number
-- WHERE m.message_type = 'user' AND m.unit_uuid = ?
-- GROUP BY unit_uuid, content
-- HAVING ask_count >= 3
-- ORDER BY ask_count DESC
-- LIMIT 10;

-- ===== 5. 插入测试数据说明 =====
-- 以下是示例数据，实际使用时由应用程序插入

-- 示例会话
-- INSERT INTO `pbl_ai_chat_sessions` 
-- (`uuid`, `user_id`, `unit_uuid`, `message_count`, `started_at`, `status`) 
-- VALUES 
-- (UUID(), 1, 'be980732-d4e4-11f0-a641-0242ac140002', 0, NOW(), 'active');

-- 示例消息
-- INSERT INTO `pbl_ai_chat_messages` 
-- (`uuid`, `session_id`, `session_uuid`, `user_id`, `unit_uuid`, 
--  `message_type`, `content`, `sequence_number`, `sent_at`) 
-- VALUES 
-- (UUID(), 1, 'session-uuid', 1, 'unit-uuid', 
--  'user', '什么是智能体？', 1, NOW());

-- ===== 执行说明 =====
-- 1. 此脚本创建两个核心表
-- 2. 可重复执行（使用 IF NOT EXISTS）
-- 3. 索引已优化，支持常见查询场景
-- 4. 不使用视图，所有统计通过API层查询实现
-- 5. 如需清理：
--    DROP TABLE IF EXISTS pbl_ai_chat_messages;
--    DROP TABLE IF EXISTS pbl_ai_chat_sessions;
