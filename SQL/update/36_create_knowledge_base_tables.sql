-- ============================================================================
-- 知识库系统数据库表 - 支持分级知识库管理
-- 创建日期: 2025-11-30
-- 说明: 支持系统级、学校级、课程级、智能体级四级知识库体系
--       仅支持Markdown(.md)和纯文本(.txt)格式
-- ============================================================================

-- ============================================================================
-- 1. 知识库表 aiot_knowledge_bases
-- ============================================================================

CREATE TABLE IF NOT EXISTS `aiot_knowledge_bases` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '知识库ID',
  `uuid` VARCHAR(36) NOT NULL COMMENT '唯一标识UUID',
  `name` VARCHAR(100) NOT NULL COMMENT '知识库名称',
  `description` TEXT COMMENT '知识库描述',
  `icon` VARCHAR(200) COMMENT '知识库图标URL',
  
  -- 层级与归属
  `scope_type` ENUM('system', 'school', 'course', 'agent', 'personal') NOT NULL COMMENT '作用域类型',
  `scope_id` INT NULL COMMENT '作用域ID（school_id/course_id/agent_id）',
  `parent_kb_id` INT NULL COMMENT '父知识库ID（支持继承）',
  
  -- 创建者与权限
  `owner_id` INT NOT NULL COMMENT '创建者用户ID',
  `access_level` ENUM('public', 'protected', 'private') DEFAULT 'protected' COMMENT '访问级别',
  
  -- 统计信息
  `document_count` INT DEFAULT 0 COMMENT '文档数量',
  `chunk_count` INT DEFAULT 0 COMMENT '文本块数量',
  `total_size` BIGINT DEFAULT 0 COMMENT '总大小（字节）',
  `last_updated_at` DATETIME COMMENT '最后更新时间',
  
  -- 配置参数
  `chunk_size` INT DEFAULT 500 COMMENT '文本块大小（字符数）',
  `chunk_overlap` INT DEFAULT 50 COMMENT '文本块重叠大小',
  `embedding_model_id` INT NULL COMMENT 'Embedding模型ID',
  `retrieval_config` JSON COMMENT '检索配置（相似度阈值、返回数量等）',
  
  -- 状态与元数据
  `is_active` TINYINT(1) DEFAULT 1 COMMENT '是否激活',
  `is_system` TINYINT(1) DEFAULT 0 COMMENT '是否系统内置',
  `tags` JSON COMMENT '标签（便于分类）',
  `meta_data` JSON COMMENT '扩展元数据',
  
  -- 时间戳
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '删除时间（软删除）',
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_scope` (`scope_type`, `scope_id`),
  KEY `idx_owner` (`owner_id`),
  KEY `idx_parent` (`parent_kb_id`),
  KEY `idx_active` (`is_active`, `deleted_at`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='知识库表';

-- ============================================================================
-- 2. 文档表 aiot_documents
-- ============================================================================

CREATE TABLE IF NOT EXISTS `aiot_documents` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '文档ID',
  `uuid` VARCHAR(36) NOT NULL COMMENT '唯一标识UUID',
  `knowledge_base_id` INT NOT NULL COMMENT '所属知识库ID',
  
  -- 文档基本信息
  `title` VARCHAR(200) NOT NULL COMMENT '文档标题',
  `content` LONGTEXT COMMENT '文档内容（纯文本）',
  `file_type` ENUM('txt', 'md') NOT NULL COMMENT '文件类型（txt-纯文本, md-Markdown）',
  `file_size` BIGINT COMMENT '文件大小（字节）',
  `file_url` VARCHAR(500) COMMENT '文件存储路径（相对路径）',
  `file_hash` VARCHAR(64) COMMENT '文件MD5哈希（去重）',
  
  -- 向量化状态
  `embedding_status` ENUM('pending', 'processing', 'completed', 'failed') DEFAULT 'pending' COMMENT '向量化状态',
  `chunk_count` INT DEFAULT 0 COMMENT '切分的文本块数量',
  `embedding_error` TEXT COMMENT '向量化失败原因',
  `embedded_at` DATETIME COMMENT '向量化完成时间',
  
  -- 元数据
  `author` VARCHAR(100) COMMENT '作者',
  `source` VARCHAR(200) COMMENT '来源',
  `language` VARCHAR(20) DEFAULT 'zh' COMMENT '语言',
  `tags` JSON COMMENT '标签',
  `meta_data` JSON COMMENT '扩展元数据',
  
  -- 上传者
  `uploader_id` INT NOT NULL COMMENT '上传者用户ID',
  
  -- 状态
  `is_active` TINYINT(1) DEFAULT 1 COMMENT '是否激活',
  `view_count` INT DEFAULT 0 COMMENT '查看次数',
  `reference_count` INT DEFAULT 0 COMMENT '被引用次数',
  
  -- 时间戳
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted_at` DATETIME NULL COMMENT '删除时间（软删除）',
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_kb` (`knowledge_base_id`),
  KEY `idx_status` (`embedding_status`),
  KEY `idx_hash` (`file_hash`),
  KEY `idx_uploader` (`uploader_id`),
  KEY `idx_type` (`file_type`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='文档表';

-- ============================================================================
-- 3. 文本块表 aiot_document_chunks
-- ============================================================================

CREATE TABLE IF NOT EXISTS `aiot_document_chunks` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '文本块ID',
  `uuid` VARCHAR(36) NOT NULL COMMENT '唯一标识UUID',
  `document_id` INT NOT NULL COMMENT '所属文档ID',
  `knowledge_base_id` INT NOT NULL COMMENT '所属知识库ID（冗余，便于查询）',
  
  -- 文本内容
  `content` TEXT NOT NULL COMMENT '文本块内容',
  `chunk_index` INT NOT NULL COMMENT '在文档中的顺序',
  `char_count` INT COMMENT '字符数',
  `token_count` INT COMMENT 'Token数（估算）',
  
  -- 向量（存储在MySQL的JSON字段）
  `embedding_vector` JSON COMMENT '向量表示（JSON数组，用于MySQL存储）',
  
  -- 上下文信息
  `previous_chunk_id` INT NULL COMMENT '上一个文本块ID',
  `next_chunk_id` INT NULL COMMENT '下一个文本块ID',
  
  -- 元数据
  `meta_data` JSON COMMENT '扩展元数据（如段落位置、标题层级等）',
  
  -- 时间戳
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_document` (`document_id`, `chunk_index`),
  KEY `idx_kb` (`knowledge_base_id`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='文本块表（用于向量检索）';

-- ============================================================================
-- 4. 智能体知识库关联表 aiot_agent_knowledge_bases
-- ============================================================================

CREATE TABLE IF NOT EXISTS `aiot_agent_knowledge_bases` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '关联ID',
  `agent_id` INT NOT NULL COMMENT '智能体ID',
  `knowledge_base_id` INT NOT NULL COMMENT '知识库ID',
  
  -- 配置
  `priority` INT DEFAULT 0 COMMENT '优先级（数字越大优先级越高）',
  `is_enabled` TINYINT(1) DEFAULT 1 COMMENT '是否启用',
  
  -- 检索配置（可覆盖知识库默认配置）
  `top_k` INT DEFAULT 5 COMMENT '检索返回的文档数量',
  `similarity_threshold` DECIMAL(3,2) DEFAULT 0.70 COMMENT '相似度阈值',
  `retrieval_mode` ENUM('vector', 'keyword', 'hybrid') DEFAULT 'hybrid' COMMENT '检索模式',
  
  -- 时间戳
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_agent_kb` (`agent_id`, `knowledge_base_id`),
  KEY `idx_agent` (`agent_id`),
  KEY `idx_kb` (`knowledge_base_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='智能体知识库关联表';

-- ============================================================================
-- 5. 知识库权限表 aiot_kb_permissions
-- ============================================================================

CREATE TABLE IF NOT EXISTS `aiot_kb_permissions` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '权限ID',
  `knowledge_base_id` INT NOT NULL COMMENT '知识库ID',
  
  -- 授权对象（二选一）
  `user_id` INT NULL COMMENT '用户ID',
  `role` VARCHAR(50) NULL COMMENT '角色（platform_admin/school_admin/teacher/student）',
  
  -- 权限类型
  `permission_type` ENUM('read', 'write', 'manage', 'admin') NOT NULL COMMENT '权限类型',
  
  -- 授权者
  `granted_by` INT NOT NULL COMMENT '授权人ID',
  
  -- 时间限制
  `expires_at` DATETIME NULL COMMENT '过期时间（NULL表示永久）',
  
  -- 时间戳
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  
  PRIMARY KEY (`id`),
  KEY `idx_kb` (`knowledge_base_id`),
  KEY `idx_user` (`user_id`),
  KEY `idx_role` (`role`),
  KEY `idx_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='知识库权限表';

-- ============================================================================
-- 6. 知识库共享表 aiot_kb_sharing
-- ============================================================================

CREATE TABLE IF NOT EXISTS `aiot_kb_sharing` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '共享ID',
  `knowledge_base_id` INT NOT NULL COMMENT '知识库ID',
  
  -- 共享范围（三选一）
  `school_id` INT NULL COMMENT '共享给学校ID',
  `course_id` INT NULL COMMENT '共享给课程ID',
  `user_id` INT NULL COMMENT '共享给用户ID',
  
  -- 共享类型
  `share_type` ENUM('read_only', 'editable', 'reference') DEFAULT 'read_only' COMMENT '共享类型',
  
  -- 共享者
  `shared_by` INT NOT NULL COMMENT '共享人ID',
  
  -- 时间限制
  `expires_at` DATETIME NULL COMMENT '过期时间',
  
  -- 状态
  `is_active` TINYINT(1) DEFAULT 1 COMMENT '是否激活',
  
  -- 时间戳
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  
  PRIMARY KEY (`id`),
  KEY `idx_kb` (`knowledge_base_id`),
  KEY `idx_school` (`school_id`),
  KEY `idx_course` (`course_id`),
  KEY `idx_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='知识库共享表';

-- ============================================================================
-- 7. 检索日志表 aiot_kb_retrieval_logs
-- ============================================================================

CREATE TABLE IF NOT EXISTS `aiot_kb_retrieval_logs` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `uuid` VARCHAR(36) NOT NULL COMMENT '唯一标识UUID',
  
  -- 查询信息
  `query` TEXT NOT NULL COMMENT '查询文本',
  `agent_id` INT NULL COMMENT '智能体ID',
  `user_id` INT NOT NULL COMMENT '用户ID',
  
  -- 检索范围
  `kb_ids` JSON COMMENT '检索的知识库ID列表',
  `scope_type` VARCHAR(50) COMMENT '检索范围类型',
  
  -- 检索结果
  `retrieved_chunks` JSON COMMENT '检索到的文本块ID及分数',
  `chunk_count` INT COMMENT '返回的文本块数量',
  `avg_similarity_score` DECIMAL(4,3) COMMENT '平均相似度分数',
  `retrieval_time_ms` INT COMMENT '检索耗时（毫秒）',
  
  -- 用户反馈
  `user_feedback` ENUM('helpful', 'not_helpful', 'irrelevant') NULL COMMENT '用户反馈',
  `feedback_at` DATETIME NULL COMMENT '反馈时间',
  
  -- 时间戳
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_uuid` (`uuid`),
  KEY `idx_agent` (`agent_id`),
  KEY `idx_user` (`user_id`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='知识库检索日志表';

-- ============================================================================
-- 8. 知识库统计表 aiot_kb_analytics
-- ============================================================================

CREATE TABLE IF NOT EXISTS `aiot_kb_analytics` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT '统计ID',
  `knowledge_base_id` INT NOT NULL COMMENT '知识库ID',
  `date` DATE NOT NULL COMMENT '统计日期',
  
  -- 查询统计
  `query_count` INT DEFAULT 0 COMMENT '查询次数',
  `unique_users` INT DEFAULT 0 COMMENT '独立用户数',
  
  -- 质量统计
  `hit_rate` DECIMAL(4,3) COMMENT '命中率',
  `avg_similarity` DECIMAL(4,3) COMMENT '平均相似度',
  `positive_feedback_count` INT DEFAULT 0 COMMENT '正面反馈数',
  `negative_feedback_count` INT DEFAULT 0 COMMENT '负面反馈数',
  
  -- 更新统计
  `document_added` INT DEFAULT 0 COMMENT '新增文档数',
  `document_updated` INT DEFAULT 0 COMMENT '更新文档数',
  `document_deleted` INT DEFAULT 0 COMMENT '删除文档数',
  
  -- 时间戳
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_kb_date` (`knowledge_base_id`, `date`),
  KEY `idx_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='知识库统计表';

-- ============================================================================
-- 添加外键约束
-- ============================================================================

-- 知识库表外键（先尝试删除，再添加）
SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0;
ALTER TABLE `aiot_knowledge_bases` DROP FOREIGN KEY `fk_kb_owner`;
ALTER TABLE `aiot_knowledge_bases` DROP FOREIGN KEY `fk_kb_parent`;
SET SQL_NOTES=@OLD_SQL_NOTES;

ALTER TABLE `aiot_knowledge_bases`
  ADD CONSTRAINT `fk_kb_owner` FOREIGN KEY (`owner_id`) REFERENCES `aiot_core_users` (`id`),
  ADD CONSTRAINT `fk_kb_parent` FOREIGN KEY (`parent_kb_id`) REFERENCES `aiot_knowledge_bases` (`id`) ON DELETE SET NULL;

-- 文档表外键
SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0;
ALTER TABLE `aiot_documents` DROP FOREIGN KEY `fk_doc_kb`;
ALTER TABLE `aiot_documents` DROP FOREIGN KEY `fk_doc_uploader`;
SET SQL_NOTES=@OLD_SQL_NOTES;

ALTER TABLE `aiot_documents`
  ADD CONSTRAINT `fk_doc_kb` FOREIGN KEY (`knowledge_base_id`) REFERENCES `aiot_knowledge_bases` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_doc_uploader` FOREIGN KEY (`uploader_id`) REFERENCES `aiot_core_users` (`id`);

-- 文本块表外键
SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0;
ALTER TABLE `aiot_document_chunks` DROP FOREIGN KEY `fk_chunk_document`;
ALTER TABLE `aiot_document_chunks` DROP FOREIGN KEY `fk_chunk_kb`;
SET SQL_NOTES=@OLD_SQL_NOTES;

ALTER TABLE `aiot_document_chunks`
  ADD CONSTRAINT `fk_chunk_document` FOREIGN KEY (`document_id`) REFERENCES `aiot_documents` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_chunk_kb` FOREIGN KEY (`knowledge_base_id`) REFERENCES `aiot_knowledge_bases` (`id`) ON DELETE CASCADE;

-- 智能体知识库关联表外键
SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0;
ALTER TABLE `aiot_agent_knowledge_bases` DROP FOREIGN KEY `fk_akb_agent`;
ALTER TABLE `aiot_agent_knowledge_bases` DROP FOREIGN KEY `fk_akb_kb`;
SET SQL_NOTES=@OLD_SQL_NOTES;

ALTER TABLE `aiot_agent_knowledge_bases`
  ADD CONSTRAINT `fk_akb_agent` FOREIGN KEY (`agent_id`) REFERENCES `aiot_agents` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_akb_kb` FOREIGN KEY (`knowledge_base_id`) REFERENCES `aiot_knowledge_bases` (`id`) ON DELETE CASCADE;

-- 知识库权限表外键
SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0;
ALTER TABLE `aiot_kb_permissions` DROP FOREIGN KEY `fk_kbp_kb`;
ALTER TABLE `aiot_kb_permissions` DROP FOREIGN KEY `fk_kbp_user`;
ALTER TABLE `aiot_kb_permissions` DROP FOREIGN KEY `fk_kbp_granter`;
SET SQL_NOTES=@OLD_SQL_NOTES;

ALTER TABLE `aiot_kb_permissions`
  ADD CONSTRAINT `fk_kbp_kb` FOREIGN KEY (`knowledge_base_id`) REFERENCES `aiot_knowledge_bases` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_kbp_user` FOREIGN KEY (`user_id`) REFERENCES `aiot_core_users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_kbp_granter` FOREIGN KEY (`granted_by`) REFERENCES `aiot_core_users` (`id`);

-- 知识库共享表外键
SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0;
ALTER TABLE `aiot_kb_sharing` DROP FOREIGN KEY `fk_kbs_kb`;
ALTER TABLE `aiot_kb_sharing` DROP FOREIGN KEY `fk_kbs_school`;
ALTER TABLE `aiot_kb_sharing` DROP FOREIGN KEY `fk_kbs_course`;
ALTER TABLE `aiot_kb_sharing` DROP FOREIGN KEY `fk_kbs_user`;
ALTER TABLE `aiot_kb_sharing` DROP FOREIGN KEY `fk_kbs_sharer`;
SET SQL_NOTES=@OLD_SQL_NOTES;

ALTER TABLE `aiot_kb_sharing`
  ADD CONSTRAINT `fk_kbs_kb` FOREIGN KEY (`knowledge_base_id`) REFERENCES `aiot_knowledge_bases` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_kbs_school` FOREIGN KEY (`school_id`) REFERENCES `aiot_schools` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_kbs_course` FOREIGN KEY (`course_id`) REFERENCES `aiot_courses` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_kbs_user` FOREIGN KEY (`user_id`) REFERENCES `aiot_core_users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_kbs_sharer` FOREIGN KEY (`shared_by`) REFERENCES `aiot_core_users` (`id`);

-- 知识库统计表外键
SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0;
ALTER TABLE `aiot_kb_analytics` DROP FOREIGN KEY `fk_kba_kb`;
SET SQL_NOTES=@OLD_SQL_NOTES;

ALTER TABLE `aiot_kb_analytics`
  ADD CONSTRAINT `fk_kba_kb` FOREIGN KEY (`knowledge_base_id`) REFERENCES `aiot_knowledge_bases` (`id`) ON DELETE CASCADE;

-- ============================================================================
-- 插入初始数据
-- ============================================================================

-- 创建系统级知识库（示例）
INSERT INTO `aiot_knowledge_bases` 
  (`uuid`, `name`, `description`, `scope_type`, `scope_id`, `owner_id`, `access_level`, `is_system`, `chunk_size`, `chunk_overlap`)
VALUES
  (UUID(), '系统知识库', '平台通用知识库，包含平台使用手册、常见问题等', 'system', NULL, 1, 'public', 1, 500, 50)
ON DUPLICATE KEY UPDATE `name`=`name`;

-- ============================================================================
-- 完成
-- ============================================================================

SELECT 'Knowledge Base tables created successfully!' AS status;

