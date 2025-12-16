# CodeHubot 统一前端项目

集成Device管理系统和PBL学习系统的统一前端平台。

## 🎯 项目特点

- ✅ **单页面应用**：一个项目包含所有功能模块
- ✅ **统一认证**：Token在整个应用中共享，无需跨域传递
- ✅ **模块化设计**：Device和PBL模块独立，便于维护
- ✅ **懒加载优化**：按需加载模块，提升首屏性能
- ✅ **统一UI**：基于Element Plus的统一设计风格
- ✅ **角色权限**：根据用户角色显示不同的入口和菜单

## 📁 项目结构

```
frontend/
├── src/
│   ├── modules/              # 业务模块
│   │   ├── device/           # Device管理模块
│   │   │   ├── views/        # 页面
│   │   │   ├── components/   # 组件
│   │   │   └── api/          # API
│   │   └── pbl/              # PBL学习模块
│   │       ├── student/      # 学生端
│   │       ├── teacher/      # 教师端
│   │       └── admin/        # 管理端
│   │
│   ├── shared/               # 共享代码
│   │   ├── api/              # 统一API封装
│   │   ├── utils/            # 工具函数
│   │   └── components/       # 共享组件
│   │
│   ├── layouts/              # 布局组件
│   │   ├── DeviceLayout.vue
│   │   ├── PBLStudentLayout.vue
│   │   ├── PBLTeacherLayout.vue
│   │   └── PBLAdminLayout.vue
│   │
│   ├── views/                # 通用页面
│   │   ├── Login.vue         # 登录页
│   │   ├── Portal.vue        # 门户页
│   │   └── NotFound.vue      # 404页面
│   │
│   ├── router/               # 路由配置
│   ├── stores/               # Pinia状态管理
│   └── App.vue
│
├── public/                   # 静态资源
├── package.json
├── vite.config.js           # Vite配置
├── Dockerfile               # Docker构建文件
└── nginx.conf               # Nginx配置

```

## 🚀 快速开始

### 1. 安装依赖

```bash
npm install
```

### 2. 启动开发服务器

```bash
npm run dev
```

访问：http://localhost:3000

### 3. 构建生产版本

```bash
npm run build
```

### 4. 预览生产版本

```bash
npm run preview
```

## 🔧 环境变量

### 开发环境 (.env.development)

```env
VITE_API_BASE_URL=http://localhost:8000
VITE_DEBUG=true
```

### 生产环境 (.env.production)

```env
VITE_API_BASE_URL=/api
VITE_DEBUG=false
```

## 📦 代码迁移

### 迁移Device代码

```bash
# 运行迁移脚本
./migrate_code.sh
```

脚本会自动：
1. 复制views、components、api文件
2. 更新导入路径
3. 生成迁移报告

### 手动迁移PBL代码

1. 复制学生端页面到 `src/modules/pbl/student/views/`
2. 复制教师端页面到 `src/modules/pbl/teacher/views/`
3. 复制管理端页面到 `src/modules/pbl/admin/views/`
4. 更新导入路径：
   - `@/api/xxx` → `@pbl/student/api/xxx`
   - 共享API使用 `@shared/api/xxx`

## 🔑 认证说明

### Token管理

所有模块共享同一个Token，存储在localStorage中：

```javascript
// 登录后，Token自动保存
await authStore.login(loginFunc, loginData)

// 在任何模块中都可以直接使用
const authStore = useAuthStore()
console.log(authStore.token)  // 获取token
console.log(authStore.userInfo)  // 获取用户信息
```

### 无需SSO跳转

**旧方案（独立前端）：**
```javascript
// PBL前端 → Device前端
window.location.href = `https://device.com?token=${token}`
```

**新方案（统一前端）：**
```javascript
// 直接路由跳转，Token自动可用
router.push('/device/dashboard')
```

## 🎨 路由结构

### 门户和认证

- `/` - 系统门户（选择入口）
- `/login` - 统一登录页

### Device系统

- `/device/dashboard` - 控制台
- `/device/devices` - 设备管理
- `/device/products` - 产品管理

### PBL学生端

- `/pbl/student/courses` - 我的课程
- `/pbl/student/tasks` - 我的任务
- `/pbl/student/portfolio` - 学习档案

### PBL教师端

- `/pbl/teacher/dashboard` - 教师工作台
- `/pbl/teacher/courses` - 课程管理
- `/pbl/teacher/grading` - 作业批改

### PBL管理端

- `/pbl/admin/dashboard` - 管理控制台
- `/pbl/admin/users` - 用户管理
- `/pbl/admin/schools` - 学校管理

## 🔒 权限控制

### 路由权限

```javascript
{
  path: '/pbl/student/courses',
  meta: { 
    requiresAuth: true,  // 需要登录
    roles: ['student']   // 只有学生角色可访问
  }
}
```

### 组件内权限

```vue
<template>
  <el-button v-if="authStore.isAdmin">管理功能</el-button>
</template>

<script setup>
import { useAuthStore } from '@/stores/auth'
const authStore = useAuthStore()
</script>
```

## 🐳 Docker部署

### 构建镜像

```bash
docker build -t codehubot-frontend .
```

### 运行容器

```bash
docker run -p 80:80 codehubot-frontend
```

### Docker Compose

```yaml
services:
  frontend:
    build: ./frontend
    ports:
      - "80:80"
    networks:
      - aiot-network
    depends_on:
      - backend
```

## 📝 开发规范

### 目录命名

- 文件夹：kebab-case（如 `device-groups`）
- 组件：PascalCase（如 `DeviceList.vue`）
- JS/TS文件：camelCase（如 `authService.js`）

### 导入路径

```javascript
// 共享代码
import request from '@shared/api/request'
import { useAuthStore } from '@/stores/auth'

// Device模块
import DeviceCard from '@device/components/DeviceCard.vue'
import { getDevices } from '@device/api/device'

// PBL学生模块
import CourseCard from '@pbl/student/components/CourseCard.vue'
```

### 组件通信

```javascript
// 使用Pinia进行跨模块状态共享
import { useAuthStore } from '@/stores/auth'
const authStore = useAuthStore()
```

## 🔍 调试技巧

### 查看路由信息

```javascript
import { useRoute } from 'vue-router'
const route = useRoute()
console.log('当前路由:', route.path)
console.log('路由参数:', route.params)
console.log('查询参数:', route.query)
```

### 查看用户信息

```javascript
import { useAuthStore } from '@/stores/auth'
const authStore = useAuthStore()
console.log('用户信息:', authStore.userInfo)
console.log('用户角色:', authStore.userRole)
console.log('是否登录:', authStore.isAuthenticated)
```

## 🐛 常见问题

### Q: 为什么路由跳转后页面空白？

A: 检查目标路由的组件是否正确导入，使用动态导入：
```javascript
component: () => import('@device/views/Dashboard.vue')
```

### Q: API请求失败？

A: 检查：
1. 后端服务是否启动（http://localhost:8000）
2. API路径是否正确（查看network面板）
3. Token是否过期（查看console）

### Q: 登录后还是跳转到登录页？

A: 检查：
1. Token是否正确保存到localStorage
2. 路由守卫是否正确配置
3. 用户信息是否正确获取

## 📚 相关文档

- [Element Plus](https://element-plus.org/)
- [Vue3](https://vuejs.org/)
- [Vite](https://vitejs.dev/)
- [Pinia](https://pinia.vuejs.org/)
- [Vue Router](https://router.vuejs.org/)

## 📄 License

MIT
