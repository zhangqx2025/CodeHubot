# 端口冲突解决方案

## 🚨 问题

端口 9001 被 MQTT WebSocket 占用，导致 plugin-backend-service 无法启动。

```
MQTT 容器 (codehubot-mqtt): 0.0.0.0:9001->9001/tcp (WebSocket)
plugin-backend-service: 需要使用 9001 端口
```

## ✅ 解决方案

### 方案1：修改 plugin-backend-service 端口为 9002（推荐）

#### 1. 修改服务器上的配置

```bash
# 在服务器上
cd /opt/CodeHubot/CodeHubot-main/plugin-backend-service
nano .env

# 修改端口
SERVICE_PORT=9002
```

#### 2. 重启服务

```bash
python main.py
```

#### 3. 更新 plugin-service 配置

```bash
cd ../plugin-service
nano .env

# 修改插件后端地址
PLUGIN_BACKEND_URL=http://localhost:9002
```

#### 4. 重启 plugin-service

```bash
# 停止旧进程
pkill -f "plugin-service.*main.py"

# 启动新进程
nohup python main.py > plugin-service.log 2>&1 &
```

### 方案2：修改 MQTT WebSocket 端口（不推荐）

如果确实需要 plugin-backend-service 使用 9001：

```bash
# 停止 MQTT 容器
docker stop codehubot-mqtt

# 修改 docker-compose.yml 中 MQTT 的端口映射
# 将 9001:9001 改为 9003:9001

# 重启 MQTT
docker start codehubot-mqtt
```

**注意**：这会影响使用 WebSocket 连接 MQTT 的客户端。

## 📋 端口分配建议

| 服务 | 端口 | 说明 |
|------|------|------|
| Frontend | 80 | Web 前端 |
| Backend | 8000 | 后端 API |
| Plugin Service | 9000 | 插件服务（对外） |
| **Plugin Backend** | **9002** | 插件后端（内部）⭐ 修改 |
| MQTT TCP | 1883 | MQTT 通信 |
| MQTT WebSocket | 9001 | MQTT WebSocket |
| MySQL | 3306 | 数据库 |
| Redis | 6379 | 缓存 |

## 🚀 快速修复（推荐）

```bash
# 在服务器上执行
echo "SERVICE_PORT=9002" >> /opt/CodeHubot/CodeHubot-main/plugin-backend-service/.env
echo "PLUGIN_BACKEND_URL=http://localhost:9002" >> /opt/CodeHubot/CodeHubot-main/plugin-service/.env

# 重启服务
cd /opt/CodeHubot/CodeHubot-main/plugin-backend-service
python main.py
```

## ✅ 验证

```bash
# 检查端口
netstat -tlnp | grep 9002

# 测试服务
curl http://localhost:9002/health
```

应该返回：
```json
{
  "status": "healthy",
  "database": true,
  "mqtt": true
}
```

