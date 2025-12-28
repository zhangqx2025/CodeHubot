-- ============================================================================
-- 文件: 49_disable_ai_workflow_and_kb.sql
-- 说明: 禁用AI模块中的工作流编排和知识库管理功能（暂未开放）
-- 作者: AI Assistant
-- 日期: 2024-12-28
-- 可重复执行: 是
-- ============================================================================

-- 说明：
-- 根据实际部署情况，暂时关闭以下功能：
-- 1. 工作流编排 (ai_module_workflow_enabled)
-- 2. 知识库管理 (ai_module_knowledge_base_enabled)
-- 
-- 保留开启的功能：
-- 1. AI对话与智能体 (ai_module_agent_enabled)
-- 2. 插件开发/提示词模板 (ai_module_prompt_template_enabled)

-- 1. 关闭工作流编排功能
UPDATE `core_system_config` 
SET `config_value` = 'false', 
    `updated_at` = CURRENT_TIMESTAMP
WHERE `config_key` = 'ai_module_workflow_enabled';

-- 2. 关闭知识库管理功能
UPDATE `core_system_config` 
SET `config_value` = 'false', 
    `updated_at` = CURRENT_TIMESTAMP
WHERE `config_key` = 'ai_module_knowledge_base_enabled';

-- 3. 确保智能体功能开启
UPDATE `core_system_config` 
SET `config_value` = 'true', 
    `updated_at` = CURRENT_TIMESTAMP
WHERE `config_key` = 'ai_module_agent_enabled';

-- 4. 确保提示词模板功能开启（用于插件开发）
UPDATE `core_system_config` 
SET `config_value` = 'true', 
    `updated_at` = CURRENT_TIMESTAMP
WHERE `config_key` = 'ai_module_prompt_template_enabled';

-- 完成
SELECT 'AI module features updated: workflow and knowledge base disabled' AS result;

