# 统一前端 - 5分钟快速开始

## 🎯 你已经获得了什么

一个**完整的统一前端项目**，包含：
- ✅ Device管理系统
- ✅ PBL学习系统（学生/教师/管理员）
- ✅ 统一认证（Token自动共享）
- ✅ 门户页面（根据角色显示）
- ✅ 完整的路由和布局

## 🚀 5步启动

### 1️⃣ 安装依赖（2分钟）

```bash
cd frontend
npm install
```

### 2️⃣ 启动开发服务器（1分钟）

```bash
npm run dev
```

访问：http://localhost:3000

### 3️⃣ 登录测试（1分钟）

使用你的测试账号登录，应该能看到门户页面。

### 4️⃣ 迁移现有代码（30分钟）

```bash
# 自动迁移Device代码
./migrate_code.sh

# 手动迁移PBL代码（参考详细指南）
```

### 5️⃣ 测试功能（10分钟）

- 测试登录
- 测试门户页
- 测试Device系统
- 测试PBL系统

## 💡 核心优势

### Token不再需要传递！

**旧方案：**
```javascript
// PBL前端
window.location.href = `device.com?token=${token}`

// Device前端
const token = getUrlParam('token')
localStorage.setItem('token', token)
```

**新方案：**
```javascript
// 任何位置
router.push('/device/dashboard')
// Token自动可用！
```

### 一个项目包含所有功能

```
统一前端
├── Device系统      (/device/*)
├── PBL学生端       (/pbl/student/*)
├── PBL教师端       (/pbl/teacher/*)
└── PBL管理端       (/pbl/admin/*)
```

## 📁 项目结构

```
frontend/
├── src/
│   ├── modules/          # 业务模块
│   │   ├── device/       # Device模块
│   │   └── pbl/          # PBL模块
│   ├── shared/           # 共享代码（Token管理等）
│   ├── layouts/          # 布局组件
│   ├── views/            # 门户、登录页
│   ├── router/           # 路由配置
│   └── stores/           # 状态管理
├── migrate_code.sh       # 代码迁移脚本
└── README.md             # 详细文档
```

## 🔧 常用命令

```bash
# 开发
npm run dev

# 构建
npm run build

# 预览
npm run preview

# 代码迁移
./migrate_code.sh
```

## 📚 详细文档

- **完整指南**: `FRONTEND_UNIFIED_INTEGRATION_GUIDE.md`
- **项目文档**: `frontend/README.md`
- **迁移报告**: `frontend/MIGRATION_REPORT.md`（运行迁移脚本后生成）

## 🎉 开始使用

```bash
cd frontend
npm install
npm run dev
```

**就是这么简单！** 🚀
