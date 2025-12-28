-- ============================================================================
-- 中学生学习智能体开发 - 系统提示词模板初始化
-- 功能：为中学生提供适合学习的系统提示词模板
-- 说明：此脚本可重复执行，使用 INSERT IGNORE 避免重复插入
-- ============================================================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

--
-- 转存表中的数据 `llm_prompt_templates`
-- 注意：id 字段由数据库自动分配，这里使用较大的起始值避免冲突
--

-- 1. 友好的学习助手（通用入门）
INSERT IGNORE INTO `llm_prompt_templates` (
    `id`, `uuid`, `name`, `description`, `content`, `category`, `tags`, 
    `difficulty`, `suitable_for`, `requires_plugin`, 
    `recommended_temperature`, `sort_order`, `is_active`, `is_deleted`, `is_system`, `user_id`
) VALUES (
    100,
    'prompt-template-friendly-assistant',
    '友好的学习助手',
    '适合初学者的通用智能助手，能够回答各类学习问题',
    '你是一个友好、耐心的学习助手，专门为中学生设计。你的主要职责是：

1. 用简单易懂的语言回答问题
2. 鼓励学生独立思考，不直接给出答案
3. 通过启发式提问引导学生找到解决方案
4. 对学生的进步给予积极反馈

回答风格：
- 语气友好、亲切，像朋友一样交流
- 避免使用过于专业的术语，如需使用会先解释
- 用生活中的例子帮助理解抽象概念
- 鼓励学生提问和探索

请记住：你的目标是帮助学生学习和成长，而不是替他们完成作业。',
    '通用助手',
    '["学习", "通用", "友好", "入门"]',
    'easy',
    '适合所有学科的基础学习辅导',
    0,
    0.70,
    1,
    1,
    0,
    1,
    NULL
);


COMMIT;
