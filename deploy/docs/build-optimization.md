# Docker 镜像构建优化指南

本文档介绍如何优化 Docker 镜像构建速度，特别是解决 apt-get 和 pip 安装较慢的问题。

## 🚀 快速优化方案

### 方案一：使用国内镜像源（推荐，适用于中国用户）

在 `docker/.env` 文件中添加：

```bash
# 启用国内镜像源加速
USE_CHINA_MIRROR=true
```

这样会自动使用清华大学 PyPI 镜像源，大幅提升 pip 安装速度。

### 方案二：使用自定义镜像源

如果需要使用其他镜像源，可以在 `docker/.env` 中配置：

```bash
# 使用自定义镜像源
PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
PIP_TRUSTED_HOST=pypi.tuna.tsinghua.edu.cn
```

**常用国内镜像源**：

- **清华大学**: `https://pypi.tuna.tsinghua.edu.cn/simple`
- **阿里云**: `https://mirrors.aliyun.com/pypi/simple/`
- **中科大**: `https://pypi.mirrors.ustc.edu.cn/simple/`
- **豆瓣**: `https://pypi.douban.com/simple/`

## 📊 优化效果

使用国内镜像源后，构建速度通常可以提升：

- **pip 安装**: 从 5-10 分钟 → 1-2 分钟
- **总体构建时间**: 减少 60-80%

## 🔧 已实施的优化

### 1. apt-get 优化

- ✅ 使用 `--no-install-recommends` 减少不必要的包
- ✅ 合并清理操作，减少镜像层数
- ✅ 及时清理 apt 缓存

### 2. pip 优化

- ✅ 支持通过构建参数配置镜像源
- ✅ 先升级 pip 再安装依赖
- ✅ 使用 `--no-cache-dir` 减少镜像大小

### 3. Docker 缓存优化

- ✅ 先复制 `requirements.txt`，利用 Docker 缓存
- ✅ 代码变更时只需重新安装依赖，不需要重新下载包

## 💡 使用示例

### 启用国内镜像源构建

```bash
# 1. 编辑 docker/.env
cd docker
echo "USE_CHINA_MIRROR=true" >> .env

# 2. 构建镜像
cd ..
./deploy.sh build
```

### 手动构建时指定镜像源

```bash
cd docker

# 使用国内镜像源
docker-compose -f docker-compose.prod.yml build \
  --build-arg USE_CHINA_MIRROR=true \
  backend

# 或使用自定义镜像源
docker-compose -f docker-compose.prod.yml build \
  --build-arg PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple \
  --build-arg PIP_TRUSTED_HOST=pypi.tuna.tsinghua.edu.cn \
  backend
```

## ⚠️ 注意事项

1. **网络环境**: 如果不在中国，使用国内镜像源可能反而变慢
2. **镜像源稳定性**: 建议使用清华大学或阿里云镜像源
3. **缓存利用**: 首次构建会下载所有依赖，后续构建会利用缓存

## 🔍 故障排查

### 问题：镜像源连接失败

**解决方法**：
1. 检查网络连接
2. 尝试其他镜像源
3. 回退到官方源（设置 `USE_CHINA_MIRROR=false`）

### 问题：构建仍然很慢

**检查项**：
1. 确认镜像源配置是否正确
2. 检查 Docker 缓存是否生效
3. 考虑使用 Docker BuildKit 加速

```bash
# 启用 BuildKit
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# 然后构建
./deploy.sh build
```

---

**最后更新**: 2025-01-XX
**版本**: 1.0.0

