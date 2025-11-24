# CodeHubot 容器化自动部署 - 文件清单

本文档列出了所有为容器化自动部署创建的文件。

## 📦 创建的文件

### 1. Docker 配置文件

#### `config-service/Dockerfile`
- **说明**: 配置服务的 Docker 镜像构建文件
- **端口**: 8001
- **基础镜像**: python:3.11-slim

#### `frontend/Dockerfile` 
- **说明**: 前端服务的 Docker 镜像构建文件（多阶段构建，生产环境）
- **端口**: 80 (Nginx)
- **构建阶段**: 
  - 构建阶段: node:18-alpine
  - 生产阶段: nginx:alpine

#### `docker/docker-compose.prod.yml`
- **说明**: 生产环境的 Docker Compose 配置文件
- **包含服务**: MySQL, Redis, MQTT, Backend, Config-Service, Frontend, Plugin-Service
- **功能**: 
  - 服务编排
  - 健康检查
  - 网络配置
  - 数据卷管理

#### `docker/.env.example`
- **说明**: 环境变量配置示例文件
- **用途**: 作为 `.env` 文件的模板

### 2. 部署脚本

#### `deploy.sh`
- **说明**: 自动化部署脚本
- **功能**:
  - 依赖检查
  - 环境配置检查
  - 自动生成密钥
  - 构建 Docker 镜像
  - 启动所有服务
  - 数据库初始化
  - 健康检查
- **命令**:
  - `./deploy.sh deploy` - 完整部署
  - `./deploy.sh build` - 仅构建镜像
  - `./deploy.sh start` - 启动服务
  - `./deploy.sh stop` - 停止服务
  - `./deploy.sh restart` - 重启服务
  - `./deploy.sh status` - 查看状态
  - `./deploy.sh logs [服务名]` - 查看日志

### 3. 文档

#### `deploy/docs/docker-deployment.md`
- **说明**: 完整的 Docker 部署文档
- **内容**:
  - 系统要求
  - 快速开始指南
  - 详细配置说明
  - 部署流程
  - 服务管理
  - 故障排查
  - 生产环境建议

#### `docker/README.md` (已更新)
- **说明**: Docker 目录的快速参考文档
- **内容**: 常用命令和快速开始指南

## 🚀 快速使用

### 1. 首次部署

```bash
# 1. 配置环境变量
cd docker
cp .env.example .env
vim .env  # 编辑配置，特别是 SECRET_KEY 和 INTERNAL_API_KEY

# 2. 返回项目根目录并执行部署
cd ..
./deploy.sh deploy
```

### 2. 查看服务状态

```bash
./deploy.sh status
```

### 3. 查看日志

```bash
./deploy.sh logs          # 所有服务
./deploy.sh logs backend  # 后端服务
./deploy.sh logs frontend # 前端服务
```

## 📋 服务列表

| 服务 | 容器名 | 端口 | 说明 |
|------|--------|------|------|
| MySQL | codehubot-mysql | 3306 | 数据库 |
| Redis | codehubot-redis | 6379 | 缓存 |
| MQTT | codehubot-mqtt | 1883, 9001 | 消息代理 |
| Backend | codehubot-backend | 8000 | 后端 API |
| Config-Service | codehubot-config-service | 8001 | 配置服务 |
| Frontend | codehubot-frontend | 80 | 前端 Web |
| Plugin-Service | codehubot-plugin-service | 9000 | 插件服务 |

## 🔧 配置要点

### 必需配置项

1. **SECRET_KEY**: JWT 密钥（至少 32 个字符）
   ```bash
   python3 -c "import secrets; print(secrets.token_urlsafe(32))"
   ```

2. **INTERNAL_API_KEY**: 内部 API 密钥
   ```bash
   python3 -c "import secrets; print(secrets.token_urlsafe(32))"
   ```

3. **数据库密码**: MYSQL_PASSWORD 和 MYSQL_ROOT_PASSWORD

### 可选配置项

- 服务端口（如果默认端口被占用）
- MQTT 认证信息
- 日志级别
- 环境类型

## 📚 相关文档

- [Docker 部署详细文档](deploy/docs/docker-deployment.md)
- [开发环境指南](deploy/docs/development-guide.md)
- [手动部署指南](deploy/docs/manual-deployment.md)

## ⚠️ 注意事项

1. **插件服务**: 已包含在部署中，但不包含 SSL 证书配置（HTTP 模式）
2. **数据持久化**: 所有数据存储在 Docker 数据卷中
3. **端口冲突**: 确保所需端口未被占用
4. **资源要求**: 建议至少 4GB RAM
5. **插件服务配置**: 确保 `INTERNAL_API_KEY` 与后端配置一致

## 🆘 获取帮助

如遇问题，请：
1. 查看 [Docker 部署文档](deploy/docs/docker-deployment.md) 的故障排查部分
2. 查看服务日志：`./deploy.sh logs [服务名]`
3. 检查服务状态：`./deploy.sh status`

---

**创建时间**: 2025-11-24
**版本**: 1.0.0
