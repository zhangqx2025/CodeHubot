# 教学设备创建说明

## 📋 文件说明

**文件名**: `23_create_teaching_devices.sql`  
**用途**: 批量创建20个教学用设备，每个设备配置相同的传感器和预设指令

## 🔧 使用步骤

### 1. 执行SQL脚本

在MySQL数据库中执行该脚本：

```bash
mysql -u your_username -p your_database < 23_create_teaching_devices.sql
```

或在MySQL客户端中：

```sql
source /path/to/23_create_teaching_devices.sql;
```

### 2. 查询生成的UUID

执行脚本后，运行以下查询获取所有设备的UUID：

```sql
-- 查看完整信息
SELECT 
    name as '设备名称',
    uuid as '设备UUID',
    device_id as '设备ID',
    mac_address as 'MAC地址'
FROM aiot_core_devices 
WHERE name LIKE '教学设备%' 
ORDER BY name;
```

### 3. 导出UUID列表

```sql
-- 仅导出UUID列表（供学生使用）
SELECT 
    SUBSTRING(name, 5) as '设备编号',
    uuid as 'UUID'
FROM aiot_core_devices 
WHERE name LIKE '教学设备%' 
ORDER BY name;
```

### 4. 导出为CSV（可选）

如需导出为CSV格式，可以使用：

```sql
SELECT 
    SUBSTRING(name, 5) as '设备编号',
    uuid,
    device_id,
    device_secret,
    mac_address
FROM aiot_core_devices 
WHERE name LIKE '教学设备%' 
ORDER BY name
INTO OUTFILE '/tmp/teaching_devices.csv'
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
```

## 📊 设备配置信息

### 共同配置
- **产品ID**: 2
- **用户ID**: 1 (admin)
- **固件版本**: 1.5
- **硬件版本**: ESP32
- **传感器**: DHT11温湿度传感器（温度+湿度）
- **控制器**: 4个LED灯（LED1-LED4）

### 预设指令
每个设备都配置了相同的4个预设指令：

| preset_key | 名称 | 说明 | 用途 |
|------------|------|------|------|
| `led_seq_mig4wqy5` | LED1打开3秒关闭 | 绿灯 | 可回收垃圾 |
| `led_seq_mig5hiep` | LED2打开3秒关闭 | 红灯 | 有害垃圾 |
| `led_seq_mig5i461` | LED3打开3秒关闭 | 黄灯 | 厨余垃圾 |
| `led_seq_mig5ivu5` | LED4打开3秒关闭 | 灰灯 | 其他垃圾 |

## 🎓 教学使用

### 分配设备
1. 执行脚本创建20个设备
2. 导出UUID列表
3. 每个学生分配一个设备编号（01-20）
4. 记录学生对应的设备UUID

### 学生创建智能体
1. 学生登录系统
2. 创建智能体时选择"物联网设备助手"模板
3. 绑定插件时，选择对应编号的教学设备
4. 系统自动使用设备的UUID和预设指令

### 测试验证
学生可以通过以下方式测试设备：

**垃圾分类助手测试**:
- "我要扔报纸" → LED1亮（绿灯）
- "废电池扔哪里" → LED2亮（红灯）
- "苹果皮怎么扔" → LED3亮（黄灯）
- "烟头扔哪里" → LED4亮（灰灯）

**LED温湿度助手测试**:
- "打开LED1" → LED1打开
- "关闭LED1" → LED1关闭
- "现在温度多少？" → 显示温度
- "查看温湿度" → 显示温湿度

## ⚠️ 注意事项

1. **UUID唯一性**: 每次执行脚本会生成新的UUID，不会重复
2. **设备命名**: 设备名称为"教学设备01"到"教学设备20"
3. **MAC地址**: 每个设备有唯一的MAC地址（80:B5:4E:D6:F8:01 ~ 20）
4. **预设指令**: 所有设备的preset_key名称完全一致，方便统一教学
5. **Device Secret**: 仅用于设备端认证，学生无需知道

## 🔄 重新创建

如需重新创建设备（例如UUID丢失），可以：

```sql
-- 1. 删除现有教学设备
DELETE FROM aiot_core_devices WHERE name LIKE '教学设备%';

-- 2. 重新执行23_create_teaching_devices.sql脚本

-- 3. 重新导出UUID列表
```

## 📝 设备清单模板

执行后可以使用以下模板记录：

```
学生姓名 | 设备编号 | 设备UUID
--------|---------|----------
张三     | 01      | xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
李四     | 02      | xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
...
```

---

**创建日期**: 2025-11-27  
**适用场景**: 小学生AI智能体教学  
**版本**: v2.0 (动态UUID版本)

