# 文档向量化手动处理指南

## 问题描述

文档上传后一直显示"待处理"状态，向量化任务没有自动执行。

## 原因分析

1. **后端代码缺失**: 原代码中只有 `TODO` 注释，没有实际调用向量化函数
2. **前端界面缺失**: 没有手动触发向量化的按钮
3. **后台任务未启动**: 向量化函数已实现但未被调用

## 解决方案

### ✅ 已修复的内容

1. **后端代码**（`backend/app/api/kb_documents.py`）
   - ✅ 添加了 `BackgroundTasks` 支持
   - ✅ 添加了 `run_document_embedding()` 后台任务函数
   - ✅ 文档上传时自动触发向量化
   - ✅ 手动触发向量化接口正常工作

2. **前端界面**（`frontend/src/views/KnowledgeBaseDetail.vue`）
   - ✅ 添加了"向量化"按钮
   - ✅ 按钮仅在状态为 `pending` 或 `failed` 时显示
   - ✅ 点击后自动刷新列表

## 手动处理方式

### 方式1: 使用前端界面（推荐）

**前提**: 前端代码已部署

**步骤**:
1. 登录系统
2. 进入"知识库管理"
3. 点击知识库进入详情页
4. 在文档列表中，状态为"待处理"或"失败"的文档会显示"向量化"按钮
5. 点击"向量化"按钮
6. 确认后任务提交，3秒后自动刷新

**界面示例**:
```
| 标题      | 类型 | 状态   | 操作                    |
|-----------|------|--------|------------------------|
| 文档1.txt | TXT  | 待处理 | 查看 | 向量化 | 删除   |
| 文档2.md  | MD   | 已完成 | 查看 | 删除              |
| 文档3.txt | TXT  | 失败   | 查看 | 向量化 | 删除   |
```

---

### 方式2: 使用Python脚本（适合批量处理）

**位置**: `backend/scripts/manual_embed_document.py`

**功能**:
- ✅ 列出所有待处理文档
- ✅ 处理单个文档
- ✅ 批量处理所有待处理文档

**使用方法**:

#### 2.1 列出待处理文档
```bash
cd /path/to/backend
python scripts/manual_embed_document.py list
```

**输出示例**:
```
📋 找到 3 个待处理的文档：

1. ⏸️ [123] 数学教材第一章.md
   状态: pending
   UUID: abc-123-def
   知识库ID: 5

2. ❌ [124] 物理实验报告.txt
   状态: failed
   UUID: abc-124-def
   知识库ID: 6
   错误: Connection timeout

3. ⏸️ [125] 化学公式汇总.md
   状态: pending
   UUID: abc-125-def
   知识库ID: 5
```

#### 2.2 处理单个文档
```bash
python scripts/manual_embed_document.py 123
```

**输出示例**:
```
🔄 开始处理文档: 数学教材第一章.md
   ID: 123
   UUID: abc-123-def
✅ 文档处理成功!
   文本块数量: 25
```

#### 2.3 批量处理所有待处理文档
```bash
python scripts/manual_embed_document.py all
```

**输出示例**:
```
🚀 开始批量处理 3 个文档...

🔄 开始处理文档: 数学教材第一章.md
✅ 文档处理成功!
   文本块数量: 25
------------------------------------------------------------
🔄 开始处理文档: 物理实验报告.txt
✅ 文档处理成功!
   文本块数量: 18
------------------------------------------------------------
🔄 开始处理文档: 化学公式汇总.md
✅ 文档处理成功!
   文本块数量: 32
------------------------------------------------------------

📊 处理完成:
   ✅ 成功: 3
   ❌ 失败: 0
```

---

### 方式3: 使用API调用脚本

**位置**: `backend/scripts/trigger_embedding_api.py`

**适用场景**: 需要通过HTTP API触发，或需要提供认证令牌

**使用方法**:

```bash
cd /path/to/backend
python scripts/trigger_embedding_api.py <知识库UUID> <文档UUID> [访问令牌]
```

**示例**:
```bash
# 无需认证
python scripts/trigger_embedding_api.py kb-abc-123 doc-def-456

# 需要认证
python scripts/trigger_embedding_api.py kb-abc-123 doc-def-456 eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**输出示例**:
```
🔄 正在触发向量化...
   知识库UUID: kb-abc-123
   文档UUID: doc-def-456
   API URL: http://localhost:8000/api/kb-documents/kb-abc-123/doc-def-456/embed

✅ 成功: 向量化任务已提交，正在后台处理
```

**配置说明**:
- 默认后端地址: `http://localhost:8000`
- 如需修改端口，编辑脚本中的 `base_url` 变量

---

### 方式4: 使用SQL直接查询和修复

**位置**: `SQL/update/38_fix_pending_documents.sql`

**适用场景**: 
- 需要批量查看文档状态
- 需要重置失败的文档
- 需要检查数据一致性

**使用方法**:

#### 4.1 查看所有待处理文档
```sql
SELECT 
    id, uuid, title, 
    embedding_status, 
    chunk_count,
    embedding_error
FROM aiot_documents
WHERE embedding_status IN ('pending', 'failed')
  AND deleted_at IS NULL;
```

#### 4.2 重置失败的文档
```sql
UPDATE aiot_documents
SET 
    embedding_status = 'pending',
    embedding_error = NULL,
    embedded_at = NULL
WHERE embedding_status = 'failed'
  AND deleted_at IS NULL;
```

#### 4.3 重置特定文档
```sql
UPDATE aiot_documents
SET 
    embedding_status = 'pending',
    embedding_error = NULL
WHERE uuid = '您的文档UUID'
  AND deleted_at IS NULL;
```

#### 4.4 查看知识库统计
```sql
SELECT 
    kb.name,
    COUNT(DISTINCT d.id) as 总文档数,
    SUM(CASE WHEN d.embedding_status = 'completed' THEN 1 ELSE 0 END) as 已完成,
    SUM(CASE WHEN d.embedding_status = 'pending' THEN 1 ELSE 0 END) as 待处理,
    SUM(CASE WHEN d.embedding_status = 'failed' THEN 1 ELSE 0 END) as 失败
FROM aiot_knowledge_bases kb
LEFT JOIN aiot_documents d ON kb.id = d.knowledge_base_id
WHERE kb.deleted_at IS NULL AND d.deleted_at IS NULL
GROUP BY kb.name;
```

---

## 部署步骤

### 1. 部署后端代码

```bash
# 在远程服务器上
cd /path/to/backend
git pull

# 重启后端服务
# systemctl restart your-backend-service
# 或使用您的部署方式重启
```

### 2. 部署前端代码

```bash
# 在远程服务器上
cd /path/to/frontend
git pull
npm run build

# 重启前端服务或刷新静态文件
```

### 3. 验证部署

#### 3.1 测试后端API
```bash
curl -X POST http://your-server:8000/api/kb-documents/{kb_uuid}/{doc_uuid}/embed \
  -H "Content-Type: application/json" \
  -d '{"force": false}'
```

#### 3.2 测试前端界面
1. 访问知识库详情页
2. 检查是否有"向量化"按钮
3. 点击测试

---

## 问题排查

### 问题1: 向量化一直处于"处理中"状态

**可能原因**:
- Embedding服务未配置
- API密钥无效
- 网络连接问题

**排查方法**:
```bash
# 查看后端日志
tail -f /path/to/backend/logs/app.log

# 检查环境变量
echo $DASHSCOPE_API_KEY
```

### 问题2: 向量化失败

**查看错误信息**:
```sql
SELECT id, title, embedding_error
FROM aiot_documents
WHERE embedding_status = 'failed'
  AND deleted_at IS NULL;
```

**常见错误**:
- `Connection timeout`: 网络超时，重试
- `File not found`: 文件路径错误
- `API key invalid`: API密钥无效

### 问题3: 数据不一致

**检查数据**:
```sql
-- 检查文档块数量是否一致
SELECT 
    d.title,
    d.chunk_count as 记录数量,
    COUNT(c.id) as 实际数量
FROM aiot_documents d
LEFT JOIN aiot_document_chunks c ON d.id = c.document_id
WHERE d.deleted_at IS NULL
GROUP BY d.id
HAVING d.chunk_count != COUNT(c.id);
```

---

## 联系支持

如果以上方法都无法解决问题，请提供:
1. 文档ID或UUID
2. 错误信息（`embedding_error`字段）
3. 后端日志片段
4. Embedding服务配置

---

**最后更新**: 2025-11-30
**版本**: v1.0

