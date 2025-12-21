-- ================================================================
-- 单元知识库表 - 支持RAG检索增强生成
-- 创建时间: 2024-12-20
-- 说明: 
--   - pbl_unit_knowledge_base: 单元知识库表
--   - pbl_knowledge_embeddings: 知识向量表（可选，用于向量检索）
-- 用途:
--   - 存储单元相关的知识点、文档、FAQ
--   - 支持关键词检索和向量检索
--   - AI回答时检索相关知识作为上下文
-- ================================================================

-- ===== 1. 单元知识库表 =====
CREATE TABLE IF NOT EXISTS `pbl_unit_knowledge_base` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `uuid` VARCHAR(36) NOT NULL COMMENT '知识点唯一标识',
  
  -- 关联信息
  `unit_id` BIGINT(20) DEFAULT NULL COMMENT '单元ID',
  `unit_uuid` VARCHAR(36) NOT NULL COMMENT '单元UUID',
  `course_id` BIGINT(20) DEFAULT NULL COMMENT '课程ID',
  `course_uuid` VARCHAR(36) DEFAULT NULL COMMENT '课程UUID',
  
  -- 知识内容
  `title` VARCHAR(255) NOT NULL COMMENT '知识点标题',
  `content` TEXT NOT NULL COMMENT '知识点内容',
  `content_type` VARCHAR(50) DEFAULT 'text' COMMENT '内容类型: text-文本, markdown-Markdown, code-代码, faq-FAQ',
  `summary` VARCHAR(500) DEFAULT NULL COMMENT '内容摘要',
  
  -- 分类和标签
  `category` VARCHAR(50) DEFAULT NULL COMMENT '知识分类: concept-概念, task-任务, resource-资源, example-案例, faq-常见问题',
  `tags` VARCHAR(255) DEFAULT NULL COMMENT '标签（逗号分隔或JSON）',
  `keywords` TEXT DEFAULT NULL COMMENT '关键词（用于检索，逗号分隔）',
  
  -- 来源信息
  `source_type` VARCHAR(50) DEFAULT NULL COMMENT '来源类型: lesson-课程, video-视频, document-文档, manual-人工编写',
  `source_id` BIGINT(20) DEFAULT NULL COMMENT '来源ID',
  `source_url` VARCHAR(500) DEFAULT NULL COMMENT '来源URL',
  
  -- 优先级和质量
  `priority` INT(11) DEFAULT 0 COMMENT '优先级（用于排序，数值越大越优先）',
  `quality_score` DECIMAL(5,2) DEFAULT 0.00 COMMENT '质量评分（0-100）',
  `usage_count` INT(11) DEFAULT 0 COMMENT '使用次数',
  `helpful_count` INT(11) DEFAULT 0 COMMENT '有帮助次数',
  
  -- 状态管理
  `status` VARCHAR(20) DEFAULT 'active' COMMENT '状态: active-启用, draft-草稿, archived-归档',
  `is_public` TINYINT(1) DEFAULT 1 COMMENT '是否公开',
  
  -- 扩展信息
  `extra_metadata` TEXT DEFAULT NULL COMMENT '元数据（JSON格式）',
  
  -- 创建和更新
  `created_by` BIGINT(20) DEFAULT NULL COMMENT '创建人ID',
  `updated_by` BIGINT(20) DEFAULT NULL COMMENT '更新人ID',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_unit_uuid` (`unit_uuid`),
  KEY `idx_course_uuid` (`course_uuid`),
  KEY `idx_category` (`category`),
  KEY `idx_status` (`status`),
  KEY `idx_priority` (`priority`),
  KEY `idx_quality_score` (`quality_score`),
  KEY `idx_created_at` (`created_at`),
  FULLTEXT KEY `ft_content` (`content`),
  FULLTEXT KEY `ft_title_keywords` (`title`, `keywords`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL-单元知识库表';

-- ===== 2. 知识向量表（可选，用于语义检索） =====
CREATE TABLE IF NOT EXISTS `pbl_knowledge_embeddings` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `knowledge_id` BIGINT(20) NOT NULL COMMENT '知识点ID',
  `knowledge_uuid` VARCHAR(36) NOT NULL COMMENT '知识点UUID',
  
  -- 向量信息
  `embedding_model` VARCHAR(50) NOT NULL COMMENT '向量模型名称: text-embedding-ada-002, m3e-base等',
  `embedding_dimension` INT(11) NOT NULL COMMENT '向量维度',
  `embedding_data` TEXT NOT NULL COMMENT '向量数据（JSON数组或Base64编码）',
  
  -- 文本信息
  `text_chunk` TEXT NOT NULL COMMENT '文本块（用于生成向量的原始文本）',
  `chunk_index` INT(11) DEFAULT 0 COMMENT '文本块索引（如果知识点被分块）',
  
  -- 元数据
  `metadata` TEXT DEFAULT NULL COMMENT '元数据（JSON格式）',
  
  -- 时间戳
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  
  PRIMARY KEY (`id`),
  KEY `idx_knowledge_id` (`knowledge_id`),
  KEY `idx_knowledge_uuid` (`knowledge_uuid`),
  KEY `idx_embedding_model` (`embedding_model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL-知识向量表';

-- ===== 3. 知识点使用记录表 =====
CREATE TABLE IF NOT EXISTS `pbl_knowledge_usage_logs` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  
  -- 关联信息
  `knowledge_id` BIGINT(20) NOT NULL COMMENT '知识点ID',
  `knowledge_uuid` VARCHAR(36) NOT NULL COMMENT '知识点UUID',
  `message_id` BIGINT(20) DEFAULT NULL COMMENT '消息ID',
  `message_uuid` VARCHAR(36) DEFAULT NULL COMMENT '消息UUID',
  `session_id` BIGINT(20) DEFAULT NULL COMMENT '会话ID',
  `user_id` BIGINT(20) NOT NULL COMMENT '用户ID',
  
  -- 检索信息
  `query_text` VARCHAR(500) DEFAULT NULL COMMENT '查询文本',
  `relevance_score` DECIMAL(5,2) DEFAULT NULL COMMENT '相关度评分（0-100）',
  `match_type` VARCHAR(50) DEFAULT NULL COMMENT '匹配类型: keyword-关键词, semantic-语义, exact-精确',
  
  -- 反馈信息
  `is_helpful` TINYINT(1) DEFAULT NULL COMMENT '是否有帮助',
  `feedback_at` DATETIME DEFAULT NULL COMMENT '反馈时间',
  
  -- 时间戳
  `used_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '使用时间',
  
  PRIMARY KEY (`id`),
  KEY `idx_knowledge_id` (`knowledge_id`),
  KEY `idx_message_id` (`message_id`),
  KEY `idx_session_id` (`session_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_used_at` (`used_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='PBL-知识点使用记录表';

-- ===== 4. 更新 pbl_ai_chat_messages 表，增加知识来源字段 =====
-- 检查列是否存在，不存在才添加
SET @column_exists = (
  SELECT COUNT(*) FROM information_schema.COLUMNS 
  WHERE TABLE_SCHEMA = DATABASE() 
  AND TABLE_NAME = 'pbl_ai_chat_messages' 
  AND COLUMN_NAME = 'knowledge_sources'
);

SET @sql = IF(@column_exists = 0,
  'ALTER TABLE `pbl_ai_chat_messages` ADD COLUMN `knowledge_sources` TEXT DEFAULT NULL COMMENT ''引用的知识点UUID列表（JSON数组）'' AFTER `context_data`',
  'SELECT "Column already exists" AS notice'
);

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ===== 5. 示例数据插入 =====

-- 示例：为某个单元插入知识点
-- INSERT INTO `pbl_unit_knowledge_base` 
-- (`uuid`, `unit_uuid`, `title`, `content`, `content_type`, `category`, `keywords`, `priority`, `status`) 
-- VALUES 
-- (UUID(), 'unit-uuid-here', '什么是智能体', 
--  '智能体（Agent）是一个能够感知环境、自主决策并采取行动以实现特定目标的实体...', 
--  'text', 'concept', '智能体,Agent,概念,定义', 10, 'active');

-- ===== 6. 常用查询示例 =====

-- 查询1：关键词检索单元知识库
-- SELECT * FROM pbl_unit_knowledge_base
-- WHERE unit_uuid = ?
--   AND status = 'active'
--   AND (
--     MATCH(title, keywords) AGAINST(? IN BOOLEAN MODE)
--     OR MATCH(content) AGAINST(? IN BOOLEAN MODE)
--   )
-- ORDER BY priority DESC, quality_score DESC
-- LIMIT 5;

-- 查询2：获取单元热门知识点
-- SELECT 
--   k.title,
--   k.usage_count,
--   k.helpful_count,
--   (k.helpful_count / NULLIF(k.usage_count, 0) * 100) as helpful_rate
-- FROM pbl_unit_knowledge_base k
-- WHERE k.unit_uuid = ?
--   AND k.status = 'active'
-- ORDER BY k.usage_count DESC
-- LIMIT 10;

-- 查询3：知识点使用统计
-- SELECT 
--   k.title,
--   COUNT(l.id) as usage_count,
--   AVG(l.relevance_score) as avg_relevance,
--   SUM(CASE WHEN l.is_helpful = 1 THEN 1 ELSE 0 END) as helpful_count
-- FROM pbl_unit_knowledge_base k
-- LEFT JOIN pbl_knowledge_usage_logs l ON k.id = l.knowledge_id
-- WHERE k.unit_uuid = ?
-- GROUP BY k.id, k.title
-- ORDER BY usage_count DESC;

-- ===== 7. 性能优化建议 =====

-- 7.1 定期分析表，更新统计信息
-- ANALYZE TABLE pbl_unit_knowledge_base;
-- ANALYZE TABLE pbl_knowledge_embeddings;
-- ANALYZE TABLE pbl_knowledge_usage_logs;

-- 7.2 清理旧的使用日志（保留6个月）
-- DELETE FROM pbl_knowledge_usage_logs 
-- WHERE used_at < DATE_SUB(NOW(), INTERVAL 6 MONTH);

-- ===== 执行说明 =====
-- 1. 此脚本创建3个核心表（知识库、向量、使用日志）
-- 2. 更新消息表，增加知识来源字段
-- 3. 可重复执行（使用 IF NOT EXISTS 和动态SQL检查）
-- 4. 支持全文检索（FULLTEXT索引）
-- 5. 预留向量检索扩展能力
-- 6. 如需清理：
--    DROP TABLE IF EXISTS pbl_knowledge_usage_logs;
--    DROP TABLE IF EXISTS pbl_knowledge_embeddings;
--    DROP TABLE IF EXISTS pbl_unit_knowledge_base;

