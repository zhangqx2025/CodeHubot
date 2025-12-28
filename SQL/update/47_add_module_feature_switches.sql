-- ============================================================================
-- 文件: 47_add_module_feature_switches.sql
-- 说明: 添加AI模块功能开关配置（知识库、工作流）
-- 作者: AI Assistant
-- 日期: 2024-12-28
-- 可重复执行: 是（使用 INSERT IGNORE）
-- ============================================================================

-- 添加AI模块功能开关配置
-- 这些配置控制前端菜单和页面功能的显示

-- 1. 知识库功能开关（暂未开放，默认关闭）
INSERT IGNORE INTO `core_system_config` 
(`config_key`, `config_value`, `config_type`, `description`, `category`, `is_public`) 
VALUES 
('ai_module_knowledge_base_enabled', 'false', 'boolean', 'AI模块-知识库功能是否启用（暂未开放）', 'feature', 1);

-- 2. 工作流功能开关（暂未开放，默认关闭）
INSERT IGNORE INTO `core_system_config` 
(`config_key`, `config_value`, `config_type`, `description`, `category`, `is_public`) 
VALUES 
('ai_module_workflow_enabled', 'false', 'boolean', 'AI模块-工作流功能是否启用（暂未开放）', 'feature', 1);

-- 3. 智能体功能开关（预留）
INSERT IGNORE INTO `core_system_config` 
(`config_key`, `config_value`, `config_type`, `description`, `category`, `is_public`) 
VALUES 
('ai_module_agent_enabled', 'true', 'boolean', 'AI模块-智能体功能是否启用', 'feature', 1);

-- 4. 提示词模板功能开关（预留）
INSERT IGNORE INTO `core_system_config` 
(`config_key`, `config_value`, `config_type`, `description`, `category`, `is_public`) 
VALUES 
('ai_module_prompt_template_enabled', 'true', 'boolean', 'AI模块-提示词模板功能是否启用', 'feature', 1);

-- 完成
SELECT 'AI module feature switches added successfully' AS result;

