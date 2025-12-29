-- ============================================================================
-- 学习助手对话历史优化配置
-- 创建时间: 2025-01-XX
-- 描述: 添加对话历史优化的系统配置，方便动态调整
-- ============================================================================

-- 添加学习助手对话历史配置
INSERT IGNORE INTO `core_system_config` 
(`config_key`, `config_value`, `description`, `config_type`, `is_public`) 
VALUES 
(
    'learning_assistant_history_questions', 
    '5', 
    '学习助手保留最近N个用户问题（不包含AI回复）。推荐值：3-8。值越大记忆越长但Token消耗越高', 
    'system', 
    0
);

-- 验证插入
SELECT 
    `config_key`,
    `config_value`,
    `description`,
    `updated_at`
FROM `core_system_config`
WHERE `config_key` = 'learning_assistant_history_questions';

-- ============================================================================
-- 配置说明
-- ============================================================================

/*
配置值建议：
- 3个问题：最激进，Token节省最多（约90%），适合独立问题为主的场景
- 5个问题：推荐值，平衡记忆和成本（节省85%），适合大多数场景
- 8个问题：保守值，更长的问题脉络（节省80%），适合复杂学习场景

优化效果（以10轮对话为例）：
- 原方案：10问10答 = 20条消息 ≈ 4500 tokens
- 优化后：最近5个问题 = 5条消息 ≈ 750 tokens
- 节省：约85% Token

知识库权重提升：
- 原方案：知识库内容占20%（800/4000）
- 优化后：知识库内容占64%（800/1250）
- 提升：+220%

如果需要动态读取配置（未来扩展）：
可以在 learning_assistant_service.py 的 __init__ 中读取：

def __init__(self, db: Session):
    self.db = db
    self.moderator = ContentModerationService(db)
    
    # 从配置表读取参数
    config = db.query(SystemConfig).filter(
        SystemConfig.config_key == 'learning_assistant_history_questions'
    ).first()
    
    history_questions = int(config.config_value) if config else 5
    
    self.history_optimizer = ConversationHistoryOptimizer(
        recent_user_questions=history_questions
    )
*/

