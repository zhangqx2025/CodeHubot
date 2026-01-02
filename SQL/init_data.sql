-- ==========================================================================================================
-- CodeHubot 系统初始化数据脚本
-- ==========================================================================================================
-- 
-- 脚本名称: init_data.sql
-- 脚本版本: 1.0.0
-- 创建日期: 2025-01-02
-- 兼容版本: MySQL 5.7.x, 8.0.x
-- 字符集: utf8mb4
-- 排序规则: utf8mb4_unicode_ci
--
-- ==========================================================================================================
-- 脚本说明
-- ==========================================================================================================
--
-- 1. 用途说明:
--    本脚本用于初始化 CodeHubot 系统的基础数据，包括：
--    - 系统配置数据
--    - 平台配置信息
--    - 用户协议和隐私政策
--    - AI学习助手配置
--    - 敏感词库数据
--    - 系统知识库
--    - 提示词模板
--
-- 2. 前置条件:
--    - 必须先执行 init_database.sql 创建核心表
--    - 必须先执行 pbl_schema.sql 创建PBL模块表
--    - 目标数据库已存在且包含所有必需的表
--
-- 3. 执行方式:
--    mysql -h hostname -u username -p --default-character-set=utf8mb4 aiot_admin < init_data.sql
--
-- 4. 注意事项:
--    - 本脚本使用 INSERT IGNORE，可安全重复执行
--    - 如果数据已存在，不会覆盖现有数据
--    - 建议在数据库结构初始化后立即执行
--
-- ==========================================================================================================

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ==========================================================================================================
-- 系统配置数据
-- ==========================================================================================================

SELECT '========================================' AS '';
SELECT '开始初始化系统配置数据...' AS '';
SELECT '========================================' AS '';

-- 平台基础配置
INSERT IGNORE INTO `core_system_config` 
(`config_key`, `config_value`, `config_type`, `description`, `category`, `is_public`) 
VALUES 
('platform_name', 'CodeHubot', 'string', '平台名称', 'system', 1),
('platform_description', '智能物联网管理平台', 'string', '平台描述', 'system', 1),
('enable_user_registration', 'false', 'boolean', '是否开启用户注册', 'module', 1),
('enable_device_module', 'true', 'boolean', '是否开启设备管理模块', 'module', 1),
('enable_ai_module', 'true', 'boolean', '是否开启AI模块', 'module', 1),
('enable_pbl_module', 'true', 'boolean', '是否开启PBL模块', 'module', 1);

-- AI模块功能开关
INSERT IGNORE INTO `core_system_config` 
(`config_key`, `config_value`, `config_type`, `description`, `category`, `is_public`) 
VALUES 
('ai_module_knowledge_base_enabled', 'false', 'boolean', 'AI模块-知识库功能是否启用（暂未开放）', 'feature', 1),
('ai_module_workflow_enabled', 'false', 'boolean', 'AI模块-工作流功能是否启用（暂未开放）', 'feature', 1),
('ai_module_agent_enabled', 'true', 'boolean', 'AI模块-智能体功能是否启用', 'feature', 1),
('ai_module_prompt_template_enabled', 'true', 'boolean', 'AI模块-提示词模板功能是否启用', 'feature', 1);

-- 学习助手配置
INSERT IGNORE INTO `core_system_config` 
(`config_key`, `config_value`, `config_type`, `description`, `category`, `is_public`) 
VALUES 
('learning_assistant_history_questions', '5', 'integer', '学习助手保留最近N个用户问题（不包含AI回复）。推荐值：3-8', 'system', 0),
('enable_ai_assistant_in_unit', 'true', 'boolean', '是否在单元学习页面显示AI助手图标', 'feature', 1);

SELECT '✓ 系统配置数据初始化完成' AS '';

-- ==========================================================================================================
-- 用户协议和隐私政策
-- ==========================================================================================================

SELECT '开始初始化用户协议和隐私政策...' AS '';

-- 用户协议
INSERT IGNORE INTO `core_system_config` 
(`config_key`, `config_value`, `config_type`, `description`, `category`, `is_public`) 
VALUES 
('user_agreement', '
# CodeHubot 用户协议

欢迎使用 CodeHubot 智能物联网管理平台！

## 1. 服务条款
1.1 用户应遵守国家相关法律法规
1.2 用户应妥善保管账号和密码
1.3 禁止利用平台从事违法活动

## 2. 使用规范
2.1 尊重知识产权，不得侵权
2.2 保护个人隐私，不得泄露他人信息
2.3 维护平台秩序，不得发布不良信息

## 3. 免责声明
3.1 平台不对用户发布的内容负责
3.2 因不可抗力导致的服务中断，平台不承担责任

更新日期：2025-01-02
', 'text', '用户协议', 'policy', 1);

-- 隐私政策
INSERT IGNORE INTO `core_system_config` 
(`config_key`, `config_value`, `config_type`, `description`, `category`, `is_public`) 
VALUES 
('privacy_policy', '
# CodeHubot 隐私政策

我们重视您的隐私保护。

## 1. 信息收集
1.1 我们收集您的基本信息（姓名、学校等）
1.2 我们记录您的学习行为数据
1.3 我们保存您的设备操作日志

## 2. 信息使用
2.1 用于提供教学服务
2.2 用于改进平台功能
2.3 用于数据分析和研究

## 3. 信息保护
3.1 采用加密技术保护数据
3.2 严格限制数据访问权限
3.3 定期备份和安全检查

## 4. 信息共享
4.1 不会向第三方出售您的信息
4.2 依法配合司法机关调查
4.3 征得同意后的学术研究

更新日期：2025-01-02
', 'text', '隐私政策', 'policy', 1);

SELECT '✓ 用户协议和隐私政策初始化完成' AS '';

-- ==========================================================================================================
-- AI学习助手智能体
-- ==========================================================================================================

SELECT '开始初始化AI学习助手...' AS '';

-- 获取管理员用户ID
SET @admin_id = (SELECT id FROM `core_users` WHERE `role` = 'super_admin' LIMIT 1);
SET @admin_id = IFNULL(@admin_id, (SELECT id FROM `core_users` ORDER BY id ASC LIMIT 1));

-- 创建系统学习助手智能体
INSERT IGNORE INTO `agent_main` 
(`uuid`, `name`, `description`, `system_prompt`, `user_id`, `is_system`, `is_active`, `created_at`) 
VALUES (
    'system-learning-assistant',
    'AI学习助手',
    '专为学生学习设计的智能助手，提供个性化学习指导和答疑',
    '你是一个耐心的AI学习助手，专门帮助学生学习。你的职责是：
1. 引导学生主动思考，而不是直接给出答案
2. 根据学生的学习进度和知识掌握情况提供个性化建议
3. 鼓励学生自己探索和解决问题
4. 当学生遇到困难时，提供循序渐进的提示
5. 保持友好、耐心和鼓励的态度',
    @admin_id,
    1,
    1,
    NOW()
);

SELECT '✓ AI学习助手智能体创建完成' AS '';

-- ==========================================================================================================
-- 系统知识库
-- ==========================================================================================================

SELECT '开始初始化系统知识库...' AS '';

-- 创建系统知识库
INSERT IGNORE INTO `kb_main` 
(`uuid`, `name`, `description`, `scope_type`, `owner_id`, `access_level`) 
VALUES (
    'kb-system-ai-curriculum', 
    '人工智能课程官方知识库', 
    '包含AI基础、Python编程、机器人技术等官方教学文档，为学习助手提供权威知识支持。', 
    'system', 
    @admin_id, 
    'public'
);

-- 关联知识库到学习助手
SET @agent_id = (SELECT id FROM `agent_main` WHERE `uuid` = 'system-learning-assistant');
SET @kb_id = (SELECT id FROM `kb_main` WHERE `uuid` = 'kb-system-ai-curriculum');

INSERT IGNORE INTO `agent_knowledge_bases` 
(`agent_id`, `knowledge_base_id`, `priority`, `is_enabled`, `top_k`, `similarity_threshold`, `retrieval_mode`) 
VALUES (@agent_id, @kb_id, 10, 1, 5, 0.70, 'hybrid');

SELECT '✓ 系统知识库初始化完成' AS '';

-- ==========================================================================================================
-- 敏感词库数据
-- ==========================================================================================================

SELECT '开始初始化敏感词库...' AS '';

-- 学业诚信类
INSERT IGNORE INTO `pbl_sensitive_words` (`word`, `category`, `severity`, `is_active`) VALUES
('作弊', 'education', 'high', 1),
('考试答案', 'education', 'high', 1),
('代写作业', 'education', 'high', 1),
('作业帮', 'education', 'medium', 1),
('小猿搜题', 'education', 'medium', 1),
('题拍拍', 'education', 'medium', 1),
('抄作业', 'education', 'high', 1),
('代写', 'education', 'high', 1),
('帮我写作文', 'education', 'medium', 1),
('直接给我代码', 'education', 'high', 1),
('泄题', 'education', 'high', 1),
('真题答案', 'education', 'high', 1),
('期末考题', 'education', 'high', 1),
('买答案', 'education', 'high', 1),
('代写代码', 'education', 'high', 1),
('代做', 'education', 'high', 1),
('代考', 'education', 'high', 1);

-- 校园霸凌、辱骂类
INSERT IGNORE INTO `pbl_sensitive_words` (`word`, `category`, `severity`, `is_active`) VALUES
('傻逼', 'abuse', 'high', 1),
('傻X', 'abuse', 'high', 1),
('煞笔', 'abuse', 'high', 1),
('sb', 'abuse', 'high', 1),
('SB', 'abuse', 'high', 1),
('垃圾', 'abuse', 'low', 1),
('智障', 'abuse', 'medium', 1),
('脑残', 'abuse', 'medium', 1),
('废物', 'abuse', 'medium', 1),
('菜鸡', 'abuse', 'low', 1),
('孤儿', 'abuse', 'high', 1),
('死全家', 'abuse', 'high', 1),
('你妈的', 'abuse', 'high', 1),
('滚蛋', 'abuse', 'medium', 1),
('操你', 'abuse', 'high', 1),
('混蛋', 'abuse', 'medium', 1),
('贱人', 'abuse', 'high', 1),
('婊子', 'abuse', 'high', 1),
('去死', 'abuse', 'high', 1),
('打死你', 'violence', 'high', 1),
('约架', 'violence', 'high', 1),
('放学别走', 'violence', 'high', 1);

-- 心理健康类
INSERT IGNORE INTO `pbl_sensitive_words` (`word`, `category`, `severity`, `is_active`) VALUES
('自杀', 'mental_health', 'high', 1),
('不想活了', 'mental_health', 'high', 1),
('割腕', 'mental_health', 'high', 1),
('跳楼', 'mental_health', 'high', 1),
('自残', 'mental_health', 'high', 1),
('抑郁', 'mental_health', 'medium', 1);

-- 不良内容类
INSERT IGNORE INTO `pbl_sensitive_words` (`word`, `category`, `severity`, `is_active`) VALUES
('色情', 'inappropriate', 'high', 1),
('裸聊', 'inappropriate', 'high', 1),
('约炮', 'inappropriate', 'high', 1),
('黄色网站', 'inappropriate', 'high', 1),
('黄片', 'inappropriate', 'high', 1);

-- 违禁品类
INSERT IGNORE INTO `pbl_sensitive_words` (`word`, `category`, `severity`, `is_active`) VALUES
('抽烟', 'behavior', 'medium', 1),
('喝酒', 'behavior', 'medium', 1),
('电子烟', 'behavior', 'medium', 1),
('逃课', 'behavior', 'medium', 1),
('大麻', 'illegal', 'high', 1),
('吸毒', 'illegal', 'high', 1);

-- 金融风险类
INSERT IGNORE INTO `pbl_sensitive_words` (`word`, `category`, `severity`, `is_active`) VALUES
('网贷', 'finance', 'high', 1),
('校园贷', 'finance', 'high', 1),
('裸贷', 'finance', 'high', 1),
('兼职刷单', 'finance', 'high', 1),
('高利贷', 'finance', 'high', 1),
('赌博', 'illegal', 'high', 1);

-- 翻墙与代理类
INSERT IGNORE INTO `pbl_sensitive_words` (`word`, `category`, `severity`, `is_active`) VALUES
('翻墙', 'politics', 'high', 1),
('梯子', 'politics', 'high', 1),
('VPN', 'politics', 'medium', 1),
('科学上网', 'politics', 'high', 1);

SELECT '✓ 敏感词库初始化完成（共' , COUNT(*), '条）' 
FROM `pbl_sensitive_words`;

-- ==========================================================================================================
-- 执行完成信息
-- ==========================================================================================================

SELECT '========================================' AS '';
SELECT 'CodeHubot 系统初始化数据执行完成！' AS 'Status';
SELECT '========================================' AS '';

-- 统计信息
SELECT 
    'System Config' AS 'Data Type',
    COUNT(*) AS 'Record Count'
FROM `core_system_config`
UNION ALL
SELECT 
    'Sensitive Words' AS 'Data Type',
    COUNT(*) AS 'Record Count'
FROM `pbl_sensitive_words`
UNION ALL
SELECT 
    'AI Agents' AS 'Data Type',
    COUNT(*) AS 'Record Count'
FROM `agent_main` WHERE `is_system` = 1
UNION ALL
SELECT 
    'Knowledge Bases' AS 'Data Type',
    COUNT(*) AS 'Record Count'
FROM `kb_main` WHERE `scope_type` = 'system';

SELECT '========================================' AS '';
SELECT '初始化数据已成功导入！' AS '';
SELECT '下一步：根据需要调整配置项和敏感词库' AS '';
SELECT '========================================' AS '';

-- ==========================================================================================================
-- 脚本结束
-- ==========================================================================================================

