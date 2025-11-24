# CodeHubot 系统部署指南

本文档提供 CodeHubot 物联网设备服务系统的完整部署说明，适用于手动部署到服务器环境。

## 目录

1. [环境准备](#环境准备)
2. [数据库部署](#数据库部署)
3. [MQTT 服务部署](#mqtt-服务部署)
4. [后端服务部署](#后端服务部署)
5. [前端服务部署](#前端服务部署)
6. [配置服务部署](#配置服务部署)
7. [插件服务部署](#插件服务部署)
8. [服务验证](#服务验证)
9. [常见问题](#常见问题)

---

## 环境准备


- **操作系统**: Linux (推荐 Ubuntu 20.04+ 或 CentOS 7+)
- **Python**: 3.11+
- **Node.js**: 18+
- **MySQL**: 5.7.8+ 或 8.0+ (兼容 MySQL 5.7 和 8.0，需要 5.7.8+ 以支持 JSON 数据类型)
- **Docker**: 20.10+ (用于运行 MQTT 服务)
- **Docker Compose**: 2.0+ (用于编排容器)
- **Redis**: 6.0+ (可选，用于缓存)
- **MQTT Broker**: Mosquitto 2.0+ (通过 Docker 容器部署)



## 数据库部署

### 1. 创建数据库和用户

**重要**: 确保 MySQL 版本 >= 5.7.8 以支持 JSON 数据类型。

```bash
# 登录 MySQL
sudo mysql -u root -p

# 在 MySQL 中执行以下命令
CREATE DATABASE aiot_admin CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE aiot_device CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# 创建数据库用户（请修改密码）
# 注意：MySQL 5.7 和 8.0 的认证插件可能不同
# MySQL 5.7 默认使用 mysql_native_password
# MySQL 8.0 默认使用 caching_sha2_password
# 如果需要兼容，可以显式指定认证插件
CREATE USER 'aiot_user'@'localhost' IDENTIFIED BY 'your_secure_password';
# 如果是 MySQL 8.0 且需要兼容旧客户端，可以使用：
# CREATE USER 'aiot_user'@'localhost' IDENTIFIED WITH mysql_native_password BY 'your_secure_password';

GRANT ALL PRIVILEGES ON aiot_admin.* TO 'aiot_user'@'localhost';
GRANT ALL PRIVILEGES ON aiot_device.* TO 'aiot_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 2. 导入数据库结构

```bash
cd /opt/codehubot

# 导入主系统数据库
mysql -u aiot_user -p aiot_admin < SQL/init_database.sql

# 如果存在演示数据，可以选择性导入
# mysql -u aiot_user -p aiot_admin < SQL/aiot-demo.sql
```

### 3. 验证数据库

```bash
# 检查表是否创建成功
mysql -u aiot_user -p aiot_admin -e "SHOW TABLES;"
```

应该看到以下表：
- users
- products
- devices
- device_binding_history
- firmware
- interaction_logs
- device_product_mapping (如果存在)

---

## MQTT 服务部署

MQTT 服务通过 Docker 容器部署，使用项目提供的 Docker Compose 配置。

### 1. 配置 MQTT

```bash
cd /opt/codehubot/docker

# 查看 MQTT 配置文件
cat mosquitto.conf
```

如果需要修改 MQTT 配置（如添加认证），可以编辑 `mosquitto.conf` 文件：

```bash
nano mosquitto.conf
```

**注意**: 当前配置允许匿名访问，生产环境建议添加认证。

### 2. 启动 MQTT 容器

```bash
# 进入 docker 目录
cd /opt/codehubot/docker

# 启动 MQTT 服务（仅启动 MQTT，不启动 MySQL）
docker-compose up -d mqtt

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f mqtt
```

### 3. 验证 MQTT 服务

```bash
# 检查容器是否运行
docker ps | grep mqtt

# 检查端口是否监听
sudo netstat -tlnp | grep 1883

# 测试 MQTT 连接（需要安装 mosquitto-clients）
sudo apt install mosquitto-clients -y
mosquitto_pub -h localhost -p 1883 -t test/topic -m "Hello MQTT"
```

### 4. 配置 MQTT 认证（可选，生产环境推荐）

如果需要为 MQTT 添加用户名密码认证：

```bash
cd /opt/codehubot/docker

# 创建密码文件
docker-compose exec mqtt mosquitto_passwd -c /mosquitto/config/passwd mqtt_user

# 输入密码（会提示输入两次）

# 修改 mosquitto.conf 文件
nano mosquitto.conf
```

在 `mosquitto.conf` 中添加：

```
allow_anonymous false
password_file /mosquitto/config/passwd
```

然后重启容器：

```bash
docker-compose restart mqtt
```

### 5. 配置开机自启

```bash
# 创建 systemd 服务文件（如果希望 MQTT 容器随系统启动）
sudo nano /etc/systemd/system/codehubot-mqtt.service
```

添加以下内容：

```ini
[Unit]
Description=CodeHubot MQTT Service (Docker)
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/codehubot/docker
ExecStart=/usr/local/bin/docker-compose up -d mqtt
ExecStop=/usr/local/bin/docker-compose stop mqtt
User=your_username

[Install]
WantedBy=multi-user.target
```

**注意**: 将 `your_username` 替换为实际的用户名。

```bash
# 启用服务
sudo systemctl daemon-reload
sudo systemctl enable codehubot-mqtt
sudo systemctl start codehubot-mqtt

# 查看状态
sudo systemctl status codehubot-mqtt
```

### 6. MQTT 常用命令

```bash
cd /opt/codehubot/docker

# 查看日志
docker-compose logs -f mqtt

# 重启服务
docker-compose restart mqtt

# 停止服务
docker-compose stop mqtt

# 启动服务
docker-compose start mqtt

# 停止并删除容器（数据会保留在 volumes 中）
docker-compose down mqtt

# 完全删除（包括数据卷，谨慎使用）
docker-compose down -v mqtt
```

### 7. 配置后端服务连接 MQTT

在后端服务的 `.env` 文件中配置 MQTT 连接信息：

```bash
# 如果 MQTT 允许匿名访问
MQTT_BROKER_HOST=localhost
MQTT_BROKER_PORT=1883
MQTT_USERNAME=
MQTT_PASSWORD=

# 如果 MQTT 需要认证
MQTT_BROKER_HOST=localhost
MQTT_BROKER_PORT=1883
MQTT_USERNAME=mqtt_user
MQTT_PASSWORD=your_mqtt_password
```

---

## 后端服务部署

### 1. 创建虚拟环境

```bash
cd /opt/codehubot/backend

# 创建 Python 虚拟环境
python3.11 -m venv venv

# 激活虚拟环境
source venv/bin/activate

# 升级 pip
pip install --upgrade pip
```

### 2. 安装依赖

```bash
# 安装 Python 依赖
pip install -r requirements.txt
```

### 3. 配置环境变量

```bash
# 创建 .env 文件
cat > .env << 'EOF'
# 数据库配置
DATABASE_URL=mysql+pymysql://aiot_user:your_secure_password@localhost:3306/aiot_admin

# Redis 配置（可选）
REDIS_URL=redis://localhost:6379

# 服务器配置
SERVER_BASE_URL=http://your-server-ip:8000
FIRMWARE_BASE_URL=http://your-server-ip:8000

# JWT 配置（必须，至少32个字符）
SECRET_KEY=your-very-long-secret-key-at-least-32-characters-long
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_MINUTES=45

# MQTT 配置
MQTT_BROKER_HOST=localhost
MQTT_BROKER_PORT=1883
MQTT_USERNAME=your_mqtt_username
MQTT_PASSWORD=your_mqtt_password

# 邮件服务配置（可选）
MAIL_USERNAME=your_email@gmail.com
MAIL_PASSWORD=your_email_password
MAIL_FROM=your_email@gmail.com
MAIL_PORT=587
MAIL_SERVER=smtp.gmail.com
MAIL_TLS=true
MAIL_SSL=false

# 内部 API 密钥（用于服务间调用）
INTERNAL_API_KEY=your-internal-api-key-change-me

# 环境配置
ENVIRONMENT=production
LOG_LEVEL=INFO
EOF

# 修改 .env 文件中的配置值
nano .env
```

**重要配置说明**：
- `SECRET_KEY`: 必须至少32个字符，用于JWT签名。生成方法：
  ```bash
  python -c "import secrets; print(secrets.token_urlsafe(32))"
  ```
- `INTERNAL_API_KEY`: 用于插件服务调用后端API，必须与插件服务配置一致
- `DATABASE_URL`: 使用上面创建的数据库用户和密码
- `MQTT_BROKER_HOST`: 如果 MQTT 使用 Docker 容器部署，使用 `localhost`；如果允许匿名访问，`MQTT_USERNAME` 和 `MQTT_PASSWORD` 可以留空

### 4. 测试运行

```bash
# 确保虚拟环境已激活
source venv/bin/activate

# 测试启动（前台运行）
python main.py
```

如果看到 "🚀 启动物联网设备服务系统" 且没有错误，说明配置正确。

按 `Ctrl+C` 停止服务。

### 5. 配置系统服务（使用 systemd）

```bash
# 创建 systemd 服务文件
sudo nano /etc/systemd/system/codehubot-backend.service
```

添加以下内容：

```ini
[Unit]
Description=CodeHubot Backend Service
After=network.target mysql.service

[Service]
Type=simple
User=your_username
WorkingDirectory=/opt/codehubot/backend
Environment="PATH=/opt/codehubot/backend/venv/bin"
ExecStart=/opt/codehubot/backend/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**注意**: 将 `your_username` 替换为实际的用户名。

```bash
# 重新加载 systemd
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start codehubot-backend

# 设置开机自启
sudo systemctl enable codehubot-backend

# 查看服务状态
sudo systemctl status codehubot-backend

# 查看日志
sudo journalctl -u codehubot-backend -f
```

### 6. 配置 Nginx 反向代理（可选）

```bash
sudo nano /etc/nginx/sites-available/codehubot-backend
```

添加以下配置：

```nginx
server {
    listen 80;
    server_name your-domain.com;  # 修改为你的域名或IP

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# 启用配置
sudo ln -s /etc/nginx/sites-available/codehubot-backend /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx
```

---

## 前端服务部署

### 1. 安装依赖

```bash
cd /opt/codehubot/frontend

# 安装 Node.js 依赖
npm install
```

### 2. 配置 API 地址

检查 `src/api/request.js` 文件，确保 API 基础地址正确：

```javascript
// 修改为你的后端服务地址
const baseURL = 'http://your-server-ip:8000/api'
// 或使用域名
// const baseURL = 'http://your-domain.com/api'
```

### 3. 构建生产版本

```bash
# 构建前端应用
npm run build
```

构建完成后，会在 `dist/` 目录生成静态文件。

### 4. 配置 Nginx 服务前端

```bash
sudo nano /etc/nginx/sites-available/codehubot-frontend
```

添加以下配置：

```nginx
server {
    listen 80;
    server_name your-domain.com;  # 修改为你的域名或IP

    root /opt/codehubot/frontend/dist;
    index index.html;

    # 前端路由支持
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API 代理到后端
    location /api {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

```bash
# 启用配置
sudo ln -s /etc/nginx/sites-available/codehubot-frontend /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx
```

**注意**: 如果后端和前端使用同一个域名，可以合并到一个 Nginx 配置中。

---

## 配置服务部署

配置服务（config-service）为设备提供配置信息，包括设备UUID、MQTT配置等。

### 1. 创建虚拟环境

```bash
cd /opt/codehubot/config-service

# 创建 Python 虚拟环境
python3.11 -m venv venv

# 激活虚拟环境
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt
```

### 2. 配置环境变量

```bash
# 创建 .env 文件
cat > .env << 'EOF'
# 数据库配置（使用主系统的数据库）
PROVISIONING_DB_URL=mysql+pymysql://aiot_user:your_secure_password@localhost:3306/aiot_device

# MQTT 配置
MQTT_BROKER=your-mqtt-server-ip
MQTT_PORT=1883
MQTT_USE_SSL=false

# API 服务器配置
API_SERVER=http://your-server-ip:8000
OTA_SERVER=http://your-server-ip:8000

# 服务配置
PORT=8001

# 速率限制配置
RATE_LIMIT_REQUESTS=10
RATE_LIMIT_WINDOW=60

# 日志配置
LOG_LEVEL=INFO
EOF

# 修改配置值
nano .env
```

### 3. 配置系统服务

```bash
sudo nano /etc/systemd/system/codehubot-config.service
```

添加以下内容：

```ini
[Unit]
Description=CodeHubot Config Service
After=network.target mysql.service

[Service]
Type=simple
User=your_username
WorkingDirectory=/opt/codehubot/config-service
Environment="PATH=/opt/codehubot/config-service/venv/bin"
ExecStart=/opt/codehubot/config-service/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8001
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
# 启动服务
sudo systemctl daemon-reload
sudo systemctl start codehubot-config
sudo systemctl enable codehubot-config

# 查看状态
sudo systemctl status codehubot-config
```

### 4. 配置 Nginx 反向代理（可选）

如果需要通过域名访问，可以配置 Nginx：

```nginx
server {
    listen 80;
    server_name config.your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

---

## 插件服务部署

插件服务（plugin-service）为外部插件（如 Coze、GPT 等）提供设备控制接口。

### 1. 创建虚拟环境

```bash
cd /opt/codehubot/plugin-service

# 创建 Python 虚拟环境
python3.11 -m venv venv

# 激活虚拟环境
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt
```

### 2. 配置环境变量

```bash
# 创建 .env 文件
cat > .env << 'EOF'
# 服务配置
PORT=9000
HOST=0.0.0.0
LOG_LEVEL=INFO
RELOAD=false

# 后端服务配置
BACKEND_URL=http://localhost:8000

# 后端内部 API 密钥（必须与后端 .env 中的 INTERNAL_API_KEY 一致）
BACKEND_API_KEY=your-internal-api-key-change-me

# 安全配置
CORS_ENABLED=true
CORS_ORIGINS=*

# 其他配置
REQUEST_TIMEOUT=30
DEBUG_MODE=false
EOF

# 修改配置值
nano .env
```

**重要**: `BACKEND_API_KEY` 必须与后端服务 `.env` 文件中的 `INTERNAL_API_KEY` 完全一致。

### 3. 配置系统服务

```bash
sudo nano /etc/systemd/system/codehubot-plugin.service
```

添加以下内容：

```ini
[Unit]
Description=CodeHubot Plugin Service
After=network.target

[Service]
Type=simple
User=your_username
WorkingDirectory=/opt/codehubot/plugin-service
Environment="PATH=/opt/codehubot/plugin-service/venv/bin"
ExecStart=/opt/codehubot/plugin-service/venv/bin/uvicorn main:app --host 0.0.0.0 --port 9000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
# 启动服务
sudo systemctl daemon-reload
sudo systemctl start codehubot-plugin
sudo systemctl enable codehubot-plugin

# 查看状态
sudo systemctl status codehubot-plugin
```

### 4. 配置 Nginx 反向代理（可选）

```nginx
server {
    listen 80;
    server_name plugin.your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:9000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

---

## 服务验证

### 1. 检查所有服务状态

```bash
# 检查后端服务
sudo systemctl status codehubot-backend

# 检查配置服务
sudo systemctl status codehubot-config

# 检查插件服务
sudo systemctl status codehubot-plugin

# 检查 Nginx
sudo systemctl status nginx
```

### 2. 测试 API 端点

```bash
# 测试后端健康检查
curl http://localhost:8000/health

# 测试配置服务
curl http://localhost:8001/health

# 测试插件服务
curl http://localhost:9000/
```

### 3. 检查 MQTT 容器

```bash
cd /opt/codehubot/docker

# 检查容器状态
docker-compose ps mqtt

# 测试 MQTT 连接（需要安装 mosquitto-clients）
sudo apt install mosquitto-clients -y
mosquitto_pub -h localhost -p 1883 -t test/topic -m "Hello MQTT"
```

### 4. 检查端口监听

```bash
# 检查端口是否正常监听
sudo netstat -tlnp | grep -E '8000|8001|9000|1883'
```

### 5. 查看日志

```bash
# 后端服务日志
sudo journalctl -u codehubot-backend -f

# 配置服务日志
sudo journalctl -u codehubot-config -f

# 插件服务日志
sudo journalctl -u codehubot-plugin -f

# Nginx 日志
sudo tail -f /var/log/nginx/error.log

# MQTT 容器日志
cd /opt/codehubot/docker
docker-compose logs -f mqtt
```

### 6. 访问前端界面

在浏览器中访问：
- `http://your-server-ip` 或 `http://your-domain.com`

应该能看到登录界面。

---

## 常见问题

### 1. 数据库连接失败

**问题**: 后端服务无法连接数据库

**解决方案**:
- 检查 MySQL 服务是否运行: `sudo systemctl status mysql`
- 检查数据库用户权限: `mysql -u aiot_user -p`
- 检查 `.env` 文件中的 `DATABASE_URL` 配置是否正确
- 检查防火墙是否允许本地连接

### 2. 端口被占用

**问题**: 服务启动失败，提示端口被占用

**解决方案**:
```bash
# 查看端口占用情况
sudo lsof -i :8000
sudo lsof -i :8001
sudo lsof -i :9000

# 停止占用端口的进程
sudo kill -9 <PID>
```

### 3. 前端无法访问后端 API

**问题**: 前端页面显示 API 请求失败

**解决方案**:
- 检查 `src/api/request.js` 中的 API 地址配置
- 检查后端服务是否正常运行
- 检查 Nginx 配置中的 `/api` 代理是否正确
- 检查 CORS 配置（后端 `main.py` 中的 `allow_origins`）

### 4. 插件服务无法调用后端 API

**问题**: 插件服务返回认证失败

**解决方案**:
- 检查插件服务的 `.env` 文件中的 `BACKEND_API_KEY` 是否配置
- 检查后端服务的 `.env` 文件中的 `INTERNAL_API_KEY` 是否配置
- 确保两个服务的 API 密钥完全一致
- 检查后端服务是否正常运行

### 5. 服务无法自动启动

**问题**: 服务器重启后服务未自动启动

**解决方案**:
```bash
# 确保服务已启用开机自启
sudo systemctl enable codehubot-backend
sudo systemctl enable codehubot-config
sudo systemctl enable codehubot-plugin

# 检查服务状态
sudo systemctl is-enabled codehubot-backend
```

### 6. MQTT 容器无法启动或连接失败

**问题**: MQTT 容器无法启动，或后端服务无法连接 MQTT

**解决方案**:
```bash
# 检查 Docker 是否运行
sudo systemctl status docker

# 检查 MQTT 容器状态
cd /opt/codehubot/docker
docker-compose ps mqtt

# 查看 MQTT 容器日志
docker-compose logs mqtt

# 检查端口是否被占用
sudo lsof -i :1883

# 检查 MQTT 配置文件
cat mosquitto.conf

# 重启 MQTT 容器
docker-compose restart mqtt

# 如果容器无法启动，尝试重新创建
docker-compose down mqtt
docker-compose up -d mqtt
```

**后端连接 MQTT 失败**:
- 检查后端 `.env` 文件中的 `MQTT_BROKER_HOST` 是否为 `localhost`
- 检查 `MQTT_BROKER_PORT` 是否为 `1883`
- 如果 MQTT 需要认证，确保 `MQTT_USERNAME` 和 `MQTT_PASSWORD` 配置正确
- 检查后端服务日志: `sudo journalctl -u codehubot-backend -f`

### 7. 权限问题

**问题**: 服务启动失败，提示权限不足

**解决方案**:
```bash
# 检查文件权限
ls -la /opt/codehubot/

# 修改文件所有者
sudo chown -R your_username:your_username /opt/codehubot/

# 检查 systemd 服务文件中的 User 配置是否正确

# 检查 Docker 权限（如果使用 MQTT 容器）
sudo usermod -aG docker $USER
# 然后重新登录或执行: newgrp docker
```

---

## 部署完成检查清单

- [ ] 数据库已创建并导入数据
- [ ] 后端服务已部署并运行在 8000 端口
- [ ] 前端已构建并可通过 Nginx 访问
- [ ] 配置服务已部署并运行在 8001 端口
- [ ] 插件服务已部署并运行在 9000 端口
- [ ] 所有服务的 systemd 服务已配置并启用
- [ ] Nginx 反向代理已配置（如需要）
- [ ] 所有服务的健康检查端点正常响应
- [ ] 前端可以正常登录和访问
- [ ] 日志文件正常记录

---

## 后续维护

### 更新代码

```bash
cd /opt/codehubot

# 拉取最新代码
git pull

# 重启服务
sudo systemctl restart codehubot-backend
sudo systemctl restart codehubot-config
sudo systemctl restart codehubot-plugin

# 如果前端有更新，需要重新构建
cd frontend
npm install
npm run build
sudo systemctl restart nginx
```

### 备份数据库

```bash
# 备份数据库
mysqldump -u aiot_user -p aiot_admin > backup_aiot_admin_$(date +%Y%m%d).sql
mysqldump -u aiot_user -p aiot_device > backup_aiot_device_$(date +%Y%m%d).sql
```

### 查看服务日志

```bash
# 实时查看日志
sudo journalctl -u codehubot-backend -f
sudo journalctl -u codehubot-config -f
sudo journalctl -u codehubot-plugin -f
```

---

## 技术支持

如遇到问题，请检查：
1. 服务日志: `sudo journalctl -u <service-name> -f`
2. Nginx 日志: `sudo tail -f /var/log/nginx/error.log`
3. 系统日志: `sudo dmesg | tail`

---

**部署完成！** 🎉

现在你可以通过浏览器访问前端界面，开始使用 CodeHubot 系统了。

