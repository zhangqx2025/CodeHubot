# 数据库表重命名完成摘要

## 📅 更新时间
2025-12-15

## 🎯 更新目标
将数据库表名从 `aiot_*` 前缀改为按功能模块划分的前缀，提高代码可读性和维护性。

## 📊 表名变更清单

### 1. 核心模块（Core）
| 原表名 | 新表名 | 说明 |
|--------|--------|------|
| `aiot_core_users` | `core_users` | 用户表 |
| `aiot_schools` | `core_schools` | 学校表 |

### 2. 设备模块（Device）
| 原表名 | 新表名 | 说明 |
|--------|--------|------|
| `aiot_core_devices` | `device_main` | 设备主表 |
| `aiot_core_products` | `device_products` | 产品表 |
| `aiot_core_firmware_versions` | `device_firmware_versions` | 固件版本表 |
| `aiot_device_binding_history` | `device_binding_history` | 设备绑定历史 |
| `aiot_device_groups` | `device_groups` | 设备分组 |
| `aiot_device_group_members` | `device_group_members` | 设备分组成员 |

### 3. 智能体模块（Agent）
| 原表名 | 新表名 | 说明 |
|--------|--------|------|
| `aiot_agents` | `agent_main` | 智能体主表 |
| `aiot_agent_knowledge_bases` | `agent_knowledge_bases` | 智能体知识库关联 |

### 4. 知识库模块（KB）
| 原表名 | 新表名 | 说明 |
|--------|--------|------|
| `aiot_knowledge_bases` | `kb_main` | 知识库主表 |
| `aiot_documents` | `kb_documents` | 文档表 |
| `aiot_document_chunks` | `kb_document_chunks` | 文档块表 |
| `aiot_kb_permissions` | `kb_permissions` | 知识库权限 |
| `aiot_kb_sharing` | `kb_sharing` | 知识库共享 |
| `aiot_kb_retrieval_logs` | `kb_retrieval_logs` | 检索日志 |
| `aiot_kb_analytics` | `kb_analytics` | 统计分析 |

### 5. LLM模块
| 原表名 | 新表名 | 说明 |
|--------|--------|------|
| `aiot_llm_models` | `llm_models` | LLM模型表 |
| `aiot_llm_providers` | `llm_providers` | LLM提供商表 |
| `aiot_prompt_templates` | `llm_prompt_templates` | 提示词模板 |

### 6. 插件模块（Plugin）
| 原表名 | 新表名 | 说明 |
|--------|--------|------|
| `aiot_plugins` | `plugin_main` | 插件主表 |

### 7. 工作流模块（Workflow）
| 原表名 | 新表名 | 说明 |
|--------|--------|------|
| `aiot_workflows` | `workflow_main` | 工作流主表 |
| `aiot_workflow_executions` | `workflow_executions` | 工作流执行记录 |

**总计：23 张表完成重命名**

## 🔧 代码更新清单

### 模型文件更新（Model Files）
✅ 已更新所有模型文件中的表名和外键引用：

1. **核心模块**
   - `backend/app/models/user.py` - 更新 `core_users` 表名
   - `backend/app/models/school.py` - 更新 `core_schools` 表名

2. **设备模块**
   - `backend/app/models/device.py` - 更新 `device_main` 表名及外键
   - `backend/app/models/product.py` - 更新 `device_products` 表名及外键
   - `backend/app/models/firmware.py` - 更新 `device_firmware_versions` 表名
   - `backend/app/models/device_binding_history.py` - 更新 `device_binding_history` 表名及外键
   - `backend/app/models/device_group.py` - 更新 `device_groups`, `device_group_members` 表名及外键

3. **智能体模块**
   - `backend/app/models/agent.py` - 更新 `agent_main` 表名及外键

4. **知识库模块**
   - `backend/app/models/knowledge_base.py` - 更新 `kb_main`, `agent_knowledge_bases`, `kb_permissions`, `kb_sharing` 表名及外键
   - `backend/app/models/document.py` - 更新 `kb_documents`, `kb_document_chunks` 表名及外键
   - `backend/app/models/kb_analytics.py` - 更新 `kb_retrieval_logs`, `kb_analytics` 表名及外键

5. **LLM模块**
   - `backend/app/models/llm_model.py` - 更新 `llm_models` 表名
   - `backend/app/models/llm_provider.py` - 更新 `llm_providers` 表名

6. **提示词模块**
   - `backend/app/models/prompt_template.py` - 更新 `llm_prompt_templates` 表名

7. **插件模块**
   - `backend/app/models/plugin.py` - 更新 `plugin_main` 表名及外键

8. **工作流模块**
   - `backend/app/models/workflow.py` - 更新 `workflow_main` 表名及外键
   - `backend/app/models/workflow_execution.py` - 更新 `workflow_executions` 表名及外键

9. **课程模块**
   - `backend/app/models/course_model.py` - 更新外键引用（表名本身保持 `aiot_courses` 等不变）

### API文件更新（API Files）
✅ 已更新API文件中的SQL查询：

1. `backend/app/api/products.py` - 更新 SQL 查询中的表名
2. `backend/app/api/devices.py` - 更新 SQL 查询中的表名

### 其他文件更新（Other Files）
✅ 已更新其他相关文件：

1. `backend/app/core/init_admin.py` - 更新错误日志中的表名
2. `backend/scripts/test_agent_kb_association.py` - 更新测试脚本中的表名

### 微服务更新（Microservices）
✅ 已更新其他微服务中的表名：

#### mqtt-service（MQTT消息服务）
- `mqtt-service/models.py` - 更新 `device_main`, `device_products` 表名
- `mqtt-service/README.md` - 更新文档中的SQL示例

#### config-service（设备配置服务）
- `config-service/main.py` - 更新 `device_main`, `device_firmware_versions` 表名

#### plugin-backend-service（插件后端服务）
- `plugin-backend-service/main.py` - 更新 `device_main` 表名

**微服务更新统计**：3个服务，5个文件

## 📝 数据库迁移脚本

已创建数据库迁移脚本：
- **文件位置**: `SQL/update/27_rename_tables_to_new_schema.sql`
- **脚本功能**: 执行所有表的重命名操作
- **兼容性**: MySQL 5.7.x, 8.0.x
- **执行方式**: 
  ```bash
  mysql -h hostname -u username -p --default-character-set=utf8mb4 aiot_admin < SQL/update/27_rename_tables_to_new_schema.sql
  ```

## ⚠️ 注意事项

1. **数据库迁移脚本不可重复执行**
   - 如果表已经重命名，再次执行会报错
   - 执行前请确认当前表名状态

2. **需要重启所有服务**
   - 执行完数据库迁移后，必须重启所有使用数据库的服务
   - 包括：backend、mqtt-service、config-service、plugin-backend-service
   - 确保所有服务都使用新的表名

3. **外键约束自动更新**
   - MySQL 的 RENAME TABLE 操作会自动更新外键约束
   - 无需手动修改外键定义

4. **数据不会丢失**
   - 表重命名操作只修改表名，不影响数据
   - 所有数据、索引、约束都会保留

5. **回滚方案**
   - 如需回滚，可以使用反向的 RENAME TABLE 语句
   - 建议在执行前备份数据库

## ✅ 验证清单

执行完更新后，请验证以下内容：

- [ ] 所有表名已成功重命名
- [ ] 外键约束仍然有效
- [ ] **所有服务启动无错误**
  - [ ] backend 主后端服务
  - [ ] mqtt-service MQTT服务
  - [ ] config-service 配置服务
  - [ ] plugin-backend-service 插件后端服务
- [ ] API接口正常工作
- [ ] 设备连接和数据上报正常（MQTT）
- [ ] 设备配置拉取正常（config-service）
- [ ] 插件功能正常（plugin-backend-service）
- [ ] 数据查询和写入正常
- [ ] 前端功能正常使用

## 📞 技术支持

如有问题，请检查：
1. 数据库连接是否正常
2. 表名是否正确重命名
3. 后端服务是否已重启
4. 日志中是否有错误信息

---
**更新完成时间**: 2025-12-15  
**影响范围**: 后端模型层、API层、微服务层、数据库结构  
**影响服务**: backend, mqtt-service, config-service, plugin-backend-service  
**破坏性变更**: 是（需要执行数据库迁移脚本并重启所有服务）
