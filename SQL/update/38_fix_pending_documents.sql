-- ============================================================================
-- 修复待处理文档的向量化状态
-- 创建日期: 2025-11-30
-- 说明: 用于检查和修复处于pending状态的文档
-- ============================================================================

-- 查看所有待处理的文档
SELECT 
    id,
    uuid,
    title,
    knowledge_base_id,
    embedding_status,
    chunk_count,
    created_at,
    embedded_at,
    embedding_error
FROM aiot_documents
WHERE embedding_status IN ('pending', 'failed')
  AND deleted_at IS NULL
ORDER BY created_at DESC;

-- 如果需要将某些文档状态重置为pending（清除错误信息）
-- 取消下面注释并执行
/*
UPDATE aiot_documents
SET 
    embedding_status = 'pending',
    embedding_error = NULL,
    embedded_at = NULL
WHERE embedding_status = 'failed'
  AND deleted_at IS NULL;
*/

-- 如果需要强制将某个特定文档重置为pending
-- 取消下面注释，替换UUID后执行
/*
UPDATE aiot_documents
SET 
    embedding_status = 'pending',
    embedding_error = NULL,
    embedded_at = NULL
WHERE uuid = 'YOUR_DOCUMENT_UUID'
  AND deleted_at IS NULL;
*/

-- 查看知识库统计信息
SELECT 
    kb.id,
    kb.uuid,
    kb.name,
    kb.document_count,
    kb.chunk_count,
    COUNT(DISTINCT d.id) as actual_doc_count,
    SUM(CASE WHEN d.embedding_status = 'completed' THEN 1 ELSE 0 END) as completed_docs,
    SUM(CASE WHEN d.embedding_status = 'pending' THEN 1 ELSE 0 END) as pending_docs,
    SUM(CASE WHEN d.embedding_status = 'processing' THEN 1 ELSE 0 END) as processing_docs,
    SUM(CASE WHEN d.embedding_status = 'failed' THEN 1 ELSE 0 END) as failed_docs
FROM aiot_knowledge_bases kb
LEFT JOIN aiot_documents d ON kb.id = d.knowledge_base_id AND d.deleted_at IS NULL
WHERE kb.deleted_at IS NULL
GROUP BY kb.id, kb.uuid, kb.name, kb.document_count, kb.chunk_count
ORDER BY kb.id;

-- 查看文档块统计
SELECT 
    d.id as doc_id,
    d.title,
    d.embedding_status,
    d.chunk_count as recorded_chunks,
    COUNT(c.id) as actual_chunks
FROM aiot_documents d
LEFT JOIN aiot_document_chunks c ON d.id = c.document_id
WHERE d.deleted_at IS NULL
GROUP BY d.id, d.title, d.embedding_status, d.chunk_count
HAVING d.chunk_count != COUNT(c.id)
ORDER BY d.id;

