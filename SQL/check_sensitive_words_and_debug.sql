-- ============================================================================
-- 调试敏感词和内容审核问题
-- ============================================================================

-- 1. 查看所有启用的敏感词
SELECT 
    `category`,
    `severity`,
    `word`,
    `is_active`
FROM `pbl_sensitive_words`
WHERE `is_active` = 1
ORDER BY `category`, `severity` DESC;

-- 2. 统计各类别敏感词数量
SELECT 
    `category`,
    `severity`,
    COUNT(*) as word_count
FROM `pbl_sensitive_words`
WHERE `is_active` = 1
GROUP BY `category`, `severity`
ORDER BY `category`;

-- 3. 搜索可能误判的技术术语
SELECT 
    `word`,
    `category`,
    `severity`
FROM `pbl_sensitive_words`
WHERE `is_active` = 1
AND (
    `word` LIKE '%烧%' OR
    `word` LIKE '%录%' OR
    `word` LIKE '%固件%' OR
    `word` LIKE '%USB%' OR
    `word` LIKE '%串口%' OR
    `word` LIKE '%设备%' OR
    `word` LIKE '%连接%' OR
    `word` LIKE '%ESP%'
);

-- 4. 查看最近的审核拦截记录
SELECT 
    `user_id`,
    `content_type`,
    `content_preview`,
    `moderation_result`,
    `created_at`
FROM `pbl_content_moderation_logs`
ORDER BY `created_at` DESC
LIMIT 20;

-- 5. 如果发现不合理的敏感词，可以用以下SQL禁用
-- 示例：禁用误判的技术术语
-- UPDATE `pbl_sensitive_words` 
-- SET `is_active` = 0 
-- WHERE `word` IN ('烧录', '固件', 'USB', '串口', '设备', '连接');

-- 6. 清空所有敏感词（慎用！）
-- DELETE FROM `pbl_sensitive_words`;

