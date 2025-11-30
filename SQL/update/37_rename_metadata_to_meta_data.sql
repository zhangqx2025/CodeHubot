-- ============================================================================
-- 修复知识库表字段名称：metadata -> meta_data
-- 创建日期: 2025-11-30
-- 说明: 修复SQLAlchemy保留字冲突问题
-- ============================================================================

-- 1. 修改 aiot_knowledge_bases 表
ALTER TABLE `aiot_knowledge_bases` 
  CHANGE COLUMN `metadata` `meta_data` JSON COMMENT '扩展元数据';

-- 2. 修改 aiot_documents 表
ALTER TABLE `aiot_documents` 
  CHANGE COLUMN `metadata` `meta_data` JSON COMMENT '扩展元数据';

-- 3. 修改 aiot_document_chunks 表
ALTER TABLE `aiot_document_chunks` 
  CHANGE COLUMN `metadata` `meta_data` JSON COMMENT '扩展元数据（如段落位置、标题层级等）';

SELECT 'Metadata fields renamed to meta_data successfully!' AS status;

