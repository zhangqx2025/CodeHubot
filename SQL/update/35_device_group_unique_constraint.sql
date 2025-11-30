-- ============================================================================
-- 设备分组唯一性约束
-- 确保一个设备同一时间只能属于一个设备组
-- ============================================================================

-- 1. 检查是否有重复的设备（同时在多个组中且未离开）
SELECT 
    device_id,
    COUNT(*) as group_count,
    GROUP_CONCAT(group_id) as group_ids
FROM aiot_device_group_members
WHERE left_at IS NULL
GROUP BY device_id
HAVING COUNT(*) > 1;

-- 如果上面的查询有结果，说明存在冲突数据，需要先手动处理

-- 2. 添加唯一索引 - 确保一个设备只能在一个活跃的分组中
-- 使用条件唯一索引：只对left_at为NULL的记录生效
-- 注意：MySQL 5.7不支持条件唯一索引，所以我们用触发器来实现

-- 先删除可能存在的旧触发器
DROP TRIGGER IF EXISTS before_insert_device_group_member_check;
DROP TRIGGER IF EXISTS before_update_device_group_member_check;

-- 创建插入前检查触发器
DELIMITER //

CREATE TRIGGER before_insert_device_group_member_check
BEFORE INSERT ON aiot_device_group_members
FOR EACH ROW
BEGIN
    DECLARE existing_count INT;
    
    -- 检查该设备是否已经在其他活跃的设备组中
    SELECT COUNT(*) INTO existing_count
    FROM aiot_device_group_members
    WHERE device_id = NEW.device_id
      AND left_at IS NULL
      AND group_id != NEW.group_id;
    
    IF existing_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '该设备已在其他设备组中，一个设备只能属于一个设备组';
    END IF;
END//

-- 创建更新前检查触发器（当left_at从NULL变为非NULL时允许，但从非NULL变为NULL时需要检查）
CREATE TRIGGER before_update_device_group_member_check
BEFORE UPDATE ON aiot_device_group_members
FOR EACH ROW
BEGIN
    DECLARE existing_count INT;
    
    -- 只在left_at从非NULL变为NULL时检查（设备重新加入）
    IF OLD.left_at IS NOT NULL AND NEW.left_at IS NULL THEN
        SELECT COUNT(*) INTO existing_count
        FROM aiot_device_group_members
        WHERE device_id = NEW.device_id
          AND left_at IS NULL
          AND group_id != NEW.group_id;
        
        IF existing_count > 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '该设备已在其他设备组中，一个设备只能属于一个设备组';
        END IF;
    END IF;
END//

DELIMITER ;

-- 3. 验证触发器是否创建成功
SHOW TRIGGERS WHERE `Table` = 'aiot_device_group_members';

-- 4. 添加注释说明约束规则
ALTER TABLE aiot_device_group_members 
COMMENT = '设备分组成员表 - 一个设备同一时间只能属于一个设备组（通过触发器约束）';

