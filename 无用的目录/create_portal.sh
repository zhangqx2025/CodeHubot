#!/bin/bash

# 创建统一前端门户脚本
# 功能：快速创建一个轻量级的门户页面，作为各系统的统一入口

set -e

echo "=========================================="
echo "  创建CodeHubot统一门户"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORTAL_DIR="$SCRIPT_DIR/frontend-portal"

# 检查是否已存在
if [ -d "$PORTAL_DIR" ]; then
    echo -e "${YELLOW}⚠️  frontend-portal 目录已存在${NC}"
    read -p "是否覆盖？(y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "操作已取消"
        exit 0
    fi
    rm -rf "$PORTAL_DIR"
fi

echo -e "${BLUE}步骤 1/6: 创建项目目录...${NC}"
mkdir -p "$PORTAL_DIR"
cd "$PORTAL_DIR"

echo -e "${BLUE}步骤 2/6: 初始化Vue3项目...${NC}"
npm create vite@latest . -- --template vue

echo -e "${BLUE}步骤 3/6: 安装依赖...${NC}"
npm install
npm install element-plus @element-plus/icons-vue vue-router axios

echo -e "${BLUE}步骤 4/6: 创建项目结构...${NC}"
mkdir -p src/views src/utils src/config src/assets

# 创建Portal.vue
cat > src/views/Portal.vue << 'EOF'
<!-- 复制之前生成的Portal.vue内容 -->
EOF

# 创建Login.vue
cat > src/views/Login.vue << 'EOF'
<template>
  <div class="login-container">
    <div class="login-box">
      <h1>CodeHubot 统一登录</h1>
      <el-form :model="form" @submit.prevent="handleLogin">
        <el-form-item>
          <el-input
            v-model="form.username"
            placeholder="用户名/邮箱"
            prefix-icon="el-icon-user"
            size="large"
          />
        </el-form-item>
        <el-form-item>
          <el-input
            v-model="form.password"
            type="password"
            placeholder="密码"
            prefix-icon="el-icon-lock"
            size="large"
            @keyup.enter="handleLogin"
          />
        </el-form-item>
        <el-form-item>
          <el-button
            type="primary"
            size="large"
            style="width: 100%"
            @click="handleLogin"
            :loading="loading"
          >
            登录
          </el-button>
        </el-form-item>
      </el-form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { login } from '@/api/auth'

const router = useRouter()
const form = ref({
  username: '',
  password: ''
})
const loading = ref(false)

async function handleLogin() {
  if (!form.value.username || !form.value.password) {
    ElMessage.warning('请输入用户名和密码')
    return
  }
  
  loading.value = true
  try {
    const response = await login(form.value)
    
    // 保存token和用户信息
    localStorage.setItem('access_token', response.access_token)
    localStorage.setItem('userInfo', JSON.stringify(response.user))
    
    ElMessage.success('登录成功')
    router.push('/')
  } catch (error) {
    ElMessage.error(error.message || '登录失败')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.login-box {
  background: white;
  padding: 40px;
  border-radius: 16px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.2);
  width: 400px;
}

.login-box h1 {
  text-align: center;
  margin-bottom: 30px;
  color: #333;
}
</style>
EOF

# 创建路由配置
cat > src/router/index.js << 'EOF'
import { createRouter, createWebHistory } from 'vue-router'
import Portal from '@/views/Portal.vue'
import Login from '@/views/Login.vue'

const routes = [
  {
    path: '/',
    component: Portal,
    meta: { requiresAuth: true }
  },
  {
    path: '/login',
    component: Login
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('access_token')
  
  if (to.meta.requiresAuth && !token) {
    next('/login')
  } else if (to.path === '/login' && token) {
    next('/')
  } else {
    next()
  }
})

export default router
EOF

# 创建API配置
mkdir -p src/api
cat > src/api/auth.js << 'EOF'
import request from './request'

export function login(data) {
  return request({
    url: '/api/auth/login',
    method: 'post',
    data
  })
}

export function logout() {
  return request({
    url: '/api/auth/logout',
    method: 'post'
  })
}
EOF

cat > src/api/request.js << 'EOF'
import axios from 'axios'
import { ElMessage } from 'element-plus'

const service = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '',
  timeout: 10000
})

service.interceptors.request.use(
  config => {
    const token = localStorage.getItem('access_token')
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`
    }
    return config
  },
  error => {
    return Promise.reject(error)
  }
)

service.interceptors.response.use(
  response => {
    return response.data
  },
  error => {
    ElMessage.error(error.response?.data?.message || '请求失败')
    return Promise.reject(error)
  }
)

export default service
EOF

# 创建系统配置
cat > src/config/systems.js << 'EOF'
export const systems = [
  {
    id: 'device',
    name: '设备管理系统',
    description: '管理物联网设备、查看实时数据、远程控制',
    url: import.meta.env.VITE_DEVICE_URL || 'http://localhost:80',
    icon: 'Setting',
    color: '#667eea',
    features: ['设备监控', '数据分析', '远程控制', '固件管理']
  },
  {
    id: 'pbl-student',
    name: 'PBL学习平台',
    description: '项目式学习、课程作业、学习进度跟踪',
    url: import.meta.env.VITE_PBL_URL || 'http://localhost:81',
    path: '/student',
    icon: 'Reading',
    color: '#f5576c',
    roles: ['student'],
    features: ['我的课程', '项目学习', '作业提交', '学习档案']
  },
  {
    id: 'pbl-teacher',
    name: 'PBL教学平台',
    description: '课程管理、作业批改、学生进度监控',
    url: import.meta.env.VITE_PBL_URL || 'http://localhost:81',
    path: '/teacher',
    icon: 'Notebook',
    color: '#fcb69f',
    roles: ['teacher'],
    features: ['课程管理', '作业批改', '数据分析', '班级管理']
  },
  {
    id: 'pbl-admin',
    name: 'PBL管理平台',
    description: '系统管理、用户管理、课程模板配置',
    url: import.meta.env.VITE_PBL_URL || 'http://localhost:81',
    path: '/admin',
    icon: 'User',
    color: '#ff9a9e',
    roles: ['admin', 'super_admin'],
    features: ['用户管理', '课程模板', '学校管理', '数据统计']
  }
]
EOF

# 更新main.js
cat > src/main.js << 'EOF'
import { createApp } from 'vue'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import * as ElementPlusIconsVue from '@element-plus/icons-vue'
import router from './router'
import App from './App.vue'

const app = createApp(App)

// 注册所有图标
for (const [key, component] of Object.entries(ElementPlusIconsVue)) {
  app.component(key, component)
}

app.use(ElementPlus)
app.use(router)
app.mount('#app')
EOF

# 更新App.vue
cat > src/App.vue << 'EOF'
<template>
  <router-view />
</template>

<script setup>
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

#app {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
}
</style>
EOF

# 创建环境变量文件
cat > .env.development << 'EOF'
VITE_API_BASE_URL=http://localhost:8000
VITE_DEVICE_URL=http://localhost:80
VITE_PBL_URL=http://localhost:81
EOF

cat > .env.production << 'EOF'
VITE_API_BASE_URL=/api
VITE_DEVICE_URL=https://device.yourdomain.com
VITE_PBL_URL=https://pbl.yourdomain.com
EOF

echo -e "${BLUE}步骤 5/6: 创建Dockerfile...${NC}"
cat > Dockerfile << 'EOF'
FROM node:18-alpine as build

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

cat > nginx.conf << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://backend:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

echo -e "${BLUE}步骤 6/6: 创建README...${NC}"
cat > README.md << 'EOF'
# CodeHubot 统一门户

统一的系统入口，支持跳转到：
- Device管理系统
- PBL学习平台（学生/教师/管理员）

## 开发

```bash
npm install
npm run dev
```

## 构建

```bash
npm run build
```

## Docker部署

```bash
docker build -t codehubot-portal .
docker run -p 80:80 codehubot-portal
```
EOF

echo ""
echo -e "${GREEN}✅ 门户创建完成！${NC}"
echo ""
echo -e "${BLUE}下一步操作：${NC}"
echo "1. 进入门户目录："
echo "   cd $PORTAL_DIR"
echo ""
echo "2. 启动开发服务器："
echo "   npm run dev"
echo ""
echo "3. 访问："
echo "   http://localhost:5173"
echo ""
echo "4. 构建生产版本："
echo "   npm run build"
echo ""
echo -e "${YELLOW}注意：${NC}"
echo "- 需要先启动后端API服务（端口8000）"
echo "- 需要配置正确的环境变量（.env.development 或 .env.production）"
echo "- Portal.vue 文件需要手动完善（已创建占位符）"
echo ""

