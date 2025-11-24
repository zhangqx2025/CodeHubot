# CodeHubot 部署文档索引

本目录包含 CodeHubot 系统的所有部署相关文档。

## 📚 文档列表

### 1. [Docker 容器化部署指南](./docker-deployment.md) ⭐ 推荐

**适用场景**: 使用 Docker 一键部署所有服务（本地和生产环境）

**内容**:
- 使用 Docker Compose 自动化部署
- 适用于本地和生产环境
- 自动化部署脚本使用说明
- 服务管理和故障排查
- 本地运行特殊说明

**快速开始**:
```bash
cd docker
cp .env.example .env
# 编辑 .env 文件
cd ..
./deploy.sh deploy
```

---

### 2. [手动部署指南](./manual-deployment.md)

**适用场景**: 手动安装和配置所有服务（传统方式）

**内容**:
- 手动安装 Python、Node.js 等依赖
- 手动配置各个服务
- Nginx 反向代理配置
- 系统服务配置（systemd）
- 适用于需要精细控制的场景

---

### 3. [开发环境指南](./development-guide.md)

**适用场景**: 本地开发环境配置

**内容**:
- 基础服务用 Docker（MySQL、Redis、MQTT）
- 应用服务本地运行（Backend、Frontend）
- 开发工具推荐
- 调试技巧
- 热重载配置

**特点**: 适合需要频繁修改代码和调试的开发场景

---

### 4. [快速参考](./quick-reference.md)

**适用场景**: 快速查找常用命令和配置

**内容**:
- 常用命令速查
- 配置文件位置
- 环境变量说明
- 故障排查要点

---

## 🎯 如何选择

| 场景 | 推荐文档 |
|------|---------|
| **快速部署（本地/生产）** | [Docker 容器化部署指南](./docker-deployment.md) |
| **需要精细控制** | [手动部署指南](./manual-deployment.md) |
| **本地开发调试** | [开发环境指南](./development-guide.md) |
| **查找命令** | [快速参考](./quick-reference.md) |

---

## 📝 文档更新说明

### 已优化的内容

1. ✅ **合并重复文档**: 删除了 `local-docker-deployment.md`，其内容已合并到 `docker-deployment.md`
2. ✅ **重命名文件**: 
   - `deployment-guide.md` → `manual-deployment.md`（更清晰）
   - `local-development.md` → `development-guide.md`（更清晰）
3. ✅ **更新引用**: 所有文档中的交叉引用已更新

### 当前文档结构

```
deploy/docs/
├── README.md              # 本文件（文档索引）
├── docker-deployment.md   # Docker 容器化部署（主文档）
├── manual-deployment.md   # 手动部署指南
├── development-guide.md   # 开发环境指南
└── quick-reference.md     # 快速参考
```

---

## 🔗 相关资源

- **项目根目录**: [README.md](../../README.md)
- **部署脚本**: [deploy.sh](../../deploy.sh)
- **Docker 配置**: [docker/](../../docker/)

---

**最后更新**: 2025-01-XX
**版本**: 1.0.0

