# CodeHubot 部署快速参考

本文档提供常用的部署命令和配置信息快速参考。

## 服务端口

- **后端服务**: 8000
- **配置服务**: 8001
- **插件服务**: 9000
- **MQTT 服务**: 1883, 9001 (Docker 容器)
- **前端**: 80 (通过 Nginx)

## 常用命令

### 服务管理

```bash
# 查看服务状态
sudo systemctl status codehubot-backend
sudo systemctl status codehubot-config
sudo systemctl status codehubot-plugin

# 启动服务
sudo systemctl start codehubot-backend
sudo systemctl start codehubot-config
sudo systemctl start codehubot-plugin

# 停止服务
sudo systemctl stop codehubot-backend
sudo systemctl stop codehubot-config
sudo systemctl stop codehubot-plugin

# 重启服务
sudo systemctl restart codehubot-backend
sudo systemctl restart codehubot-config
sudo systemctl restart codehubot-plugin

# 查看服务日志
sudo journalctl -u codehubot-backend -f
sudo journalctl -u codehubot-config -f
sudo journalctl -u codehubot-plugin -f
```

### MQTT 容器管理

```bash
cd /opt/codehubot/docker

# 启动 MQTT 容器
docker-compose up -d mqtt

# 停止 MQTT 容器
docker-compose stop mqtt

# 重启 MQTT 容器
docker-compose restart mqtt

# 查看 MQTT 容器状态
docker-compose ps mqtt

# 查看 MQTT 日志
docker-compose logs -f mqtt

# 查看所有容器
docker ps | grep mqtt

# 进入 MQTT 容器
docker-compose exec mqtt sh
```

### 使用部署脚本

```bash
# 检查所有服务状态
./deploy/scripts/check-services.sh

# 重启所有服务
./deploy/scripts/restart-all.sh

# 备份数据库
./deploy/scripts/backup-database.sh

# 查看服务日志
./deploy/scripts/view-logs.sh
```

### 健康检查

```bash
# 后端服务
curl http://localhost:8000/health

# 配置服务
curl http://localhost:8001/health

# 插件服务
curl http://localhost:9000/
```

## 配置文件位置

### MQTT 服务
- Docker Compose 配置: `/opt/codehubot/docker/docker-compose.yml`
- MQTT 配置文件: `/opt/codehubot/docker/mosquitto.conf`
- 服务文件: `/etc/systemd/system/codehubot-mqtt.service` (可选)

### 后端服务
- 配置文件: `/opt/codehubot/backend/.env`
- 服务文件: `/etc/systemd/system/codehubot-backend.service`

### 配置服务
- 配置文件: `/opt/codehubot/config-service/.env`
- 服务文件: `/etc/systemd/system/codehubot-config.service`

### 插件服务
- 配置文件: `/opt/codehubot/plugin-service/.env`
- 服务文件: `/etc/systemd/system/codehubot-plugin.service`

### Nginx
- 配置文件: `/etc/nginx/sites-available/codehubot-*`
- 日志文件: `/var/log/nginx/error.log`, `/var/log/nginx/access.log`

## 环境变量关键配置

### MQTT 配置 (mosquitto.conf)

```bash
# 监听端口
listener 1883
allow_anonymous true  # 生产环境建议改为 false 并配置认证

# 持久化
persistence true
persistence_location /mosquitto/data/
```

### 后端服务 (.env)

```bash
DATABASE_URL=mysql+pymysql://aiot_user:password@localhost:3306/aiot_admin
SECRET_KEY=your-secret-key-at-least-32-characters
INTERNAL_API_KEY=your-internal-api-key
MQTT_BROKER_HOST=localhost
MQTT_BROKER_PORT=1883
MQTT_USERNAME=your_mqtt_username
MQTT_PASSWORD=your_mqtt_password
```

### 配置服务 (.env)

```bash
PROVISIONING_DB_URL=mysql+pymysql://aiot_user:password@localhost:3306/aiot_device
MQTT_BROKER=your-mqtt-server-ip
MQTT_PORT=1883
API_SERVER=http://your-server-ip:8000
PORT=8001
```

### 插件服务 (.env)

```bash
PORT=9000
BACKEND_URL=http://localhost:8000
BACKEND_API_KEY=your-internal-api-key  # 必须与后端 INTERNAL_API_KEY 一致
CORS_ENABLED=true
CORS_ORIGINS=*
```

## 数据库操作

### 连接数据库

```bash
mysql -u aiot_user -p aiot_admin
mysql -u aiot_user -p aiot_device
```

### 备份数据库

```bash
# 手动备份
mysqldump -u aiot_user -p aiot_admin > backup.sql
mysqldump -u aiot_user -p aiot_device > backup_device.sql

# 使用脚本备份
./deploy/scripts/backup-database.sh
```

### 恢复数据库

```bash
mysql -u aiot_user -p aiot_admin < backup.sql
mysql -u aiot_user -p aiot_device < backup_device.sql
```

## 前端更新

```bash
cd /opt/codehubot/frontend

# 拉取最新代码
git pull

# 安装依赖（如果有新依赖）
npm install

# 重新构建
npm run build

# 重启 Nginx（如果需要）
sudo systemctl restart nginx
```

## 后端更新

```bash
cd /opt/codehubot/backend

# 拉取最新代码
git pull

# 激活虚拟环境
source venv/bin/activate

# 更新依赖（如果有新依赖）
pip install -r requirements.txt

# 重启服务
sudo systemctl restart codehubot-backend
```

## 故障排查

### 服务无法启动

1. 查看服务状态: `sudo systemctl status <service-name>`
2. 查看详细日志: `sudo journalctl -u <service-name> -n 100`
3. 检查配置文件: 确认 `.env` 文件配置正确
4. 检查端口占用: `sudo lsof -i :<port>`

### 数据库连接失败

1. 检查 MySQL 服务: `sudo systemctl status mysql`
2. 测试数据库连接: `mysql -u aiot_user -p`
3. 检查防火墙: `sudo ufw status`
4. 检查 `.env` 中的 `DATABASE_URL` 配置

### API 请求失败

1. 检查后端服务是否运行
2. 检查 CORS 配置
3. 检查 Nginx 代理配置
4. 查看 Nginx 错误日志: `sudo tail -f /var/log/nginx/error.log`

## 安全建议

1. **修改默认密码**: 确保所有服务的密码都已修改
2. **使用强密钥**: `SECRET_KEY` 和 `INTERNAL_API_KEY` 应使用强随机字符串
3. **限制访问**: 配置防火墙，只开放必要端口
4. **定期备份**: 设置定时任务自动备份数据库
5. **更新系统**: 定期更新系统和依赖包

## 生成密钥命令

```bash
# 生成 SECRET_KEY (Python)
python -c "import secrets; print(secrets.token_urlsafe(32))"

# 生成密钥 (OpenSSL)
openssl rand -hex 32

# 生成密钥 (Linux)
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1
```

## 定时任务示例

### 自动备份数据库

编辑 crontab: `crontab -e`

```bash
# 每天凌晨2点备份数据库
0 2 * * * /opt/codehubot/deploy/scripts/backup-database.sh
```

### 自动清理日志

```bash
# 每周清理超过30天的日志
0 3 * * 0 journalctl --vacuum-time=30d
```

## 监控建议

1. 设置服务监控，确保服务自动重启
2. 监控磁盘空间，定期清理日志和备份
3. 监控数据库大小，及时优化
4. 设置告警，及时发现服务异常

---

**提示**: 更多详细信息请参考 [完整部署指南](./deployment-guide.md)

