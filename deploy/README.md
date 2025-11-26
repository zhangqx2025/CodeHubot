# CodeHubot 部署目录

本目录包含 CodeHubot 系统的部署文档。

## 目录结构

```
deploy/
├── docs/                    # 部署文档
│   ├── docker-deployment.md # Docker 容器化部署指南（推荐）
│   ├── manual-deployment.md # 手动部署指南（传统方式）
│   ├── development-guide.md # 开发环境指南
│   └── quick-reference.md   # 快速参考文档
└── README.md                # 本文件
```

## 快速开始

### 选择部署方式

- **Docker 容器化部署**（推荐）: 查看 [Docker 部署指南](./docs/docker-deployment.md)
- **手动部署**（传统方式）: 查看 [手动部署指南](./docs/manual-deployment.md)
- **开发环境配置**: 查看 [开发环境指南](./docs/development-guide.md)

### Docker 容器化部署（推荐）

使用 Docker 一键部署所有服务，适用于本地和生产环境：

```bash
# 查看 Docker 部署指南
cat docs/docker-deployment.md

# 或直接执行部署脚本
./deploy.sh deploy
```

### 手动部署（传统方式）

手动安装和配置所有服务，适用于需要精细控制的场景：

```bash
# 查看手动部署指南
cat docs/manual-deployment.md
```

### 开发环境配置

配置本地开发环境，基础服务用 Docker，应用服务本地运行：

```bash
# 查看开发环境指南
cat docs/development-guide.md
```

**部署顺序**：
1. **数据库部署** - 创建数据库并导入数据
2. **MQTT 服务部署** - 使用 Docker 容器部署 MQTT 服务
3. **后端服务部署** - 部署主 API 服务
4. **前端服务部署** - 构建并部署前端应用
5. **插件后端服务部署** - ⭐ **新增** 部署 plugin-backend-service（端口9001）
6. **插件服务部署** - 部署 plugin-service（端口9000）

⚠️ **重要**: 插件后端服务(plugin-backend-service)必须在插件服务(plugin-service)之前部署！

## 文档说明

### DEPLOYMENT_COMPLETE_GUIDE.md ⭐ **新增**

**完整部署指南**（包含新架构），包含：
- 包含 plugin-backend-service 的完整部署流程
- Docker Compose 和直接运行两种方式
- 服务架构说明
- 配置清单
- 验证步骤

### PLUGIN_BACKEND_DEPLOYMENT.md ⭐ **新增**

**Plugin Backend Service 专项部署指南**，包含：
- Docker 容器部署
- 直接运行方式
- 详细的故障排查

### docker-deployment.md

**Docker 容器化自动部署指南**（推荐使用），包含：
- 使用 Docker Compose 一键部署所有服务
- 适用于本地和生产环境
- 自动化部署脚本使用说明
- 服务管理和故障排查

### manual-deployment.md

**手动部署指南**（传统方式），包含：
- 手动安装和配置所有服务
- 适用于需要精细控制的场景
- Nginx 反向代理配置
- 系统服务配置

### development-guide.md

**开发环境指南**，包含：
- 本地开发环境配置
- 基础服务用 Docker，应用服务本地运行
- 开发工具推荐
- 调试技巧
- 常见问题解决

### quick-reference.md

**快速参考文档**，包含：
- 常用命令速查
- 配置文件位置
- 环境变量说明
- 故障排查要点

## 注意事项

1. **新架构**: 2025-11-26 更新，新增 plugin-backend-service（端口9001）
2. **服务依赖**: plugin-service 依赖 plugin-backend-service，部署顺序很重要
3. **配置**: 部署前请仔细检查所有配置文件
4. **备份**: 建议在部署前备份现有数据
5. **路径**: 文档中的路径基于 `/opt/codehubot`，如使用其他路径请相应修改
6. **端口**: 确保 9001 端口未被占用（plugin-backend-service 使用）

## 支持

如遇到问题，请：
1. 查看 [Docker 部署指南](./docs/docker-deployment.md) 或 [手动部署指南](./docs/manual-deployment.md) 中的常见问题部分
2. 查看服务日志（参考快速参考文档中的命令）
3. 检查服务状态（参考快速参考文档中的命令）

---

**最后更新**: 2025-01-XX

