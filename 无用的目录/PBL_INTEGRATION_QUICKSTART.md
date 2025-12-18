# PBL系统整合 - 快速开始

## 🚀 一键整合（推荐）

```bash
# 1. 进入CodeHubot目录
cd /Users/zhangqixun/AICodeing/CodeHubot工作空间/CodeHubot

# 2. 运行自动整合脚本
./integrate_pbl.sh

# 3. 查看整合结果
tree -L 2 backend/app/api/pbl
tree -L 1 frontend-pbl
```

## ⚙️ 配置SSO单点登录

### 1. 编辑环境变量

编辑 `docker/.env` 文件，添加以下配置：

```bash
# JWT配置（重要！必须配置）
SECRET_KEY=your-super-secret-key-at-least-32-characters-long-please-change-this
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=120
REFRESH_TOKEN_EXPIRE_MINUTES=10080

# SSO配置（生产环境）
COOKIE_DOMAIN=.yourdomain.com
COOKIE_SECURE=true
COOKIE_SAMESITE=lax
PBL_FRONTEND_URL=https://pbl.yourdomain.com
DEVICE_FRONTEND_URL=https://device.yourdomain.com
CORS_ORIGINS=https://pbl.yourdomain.com,https://device.yourdomain.com

# 前端端口
DEVICE_FRONTEND_PORT=80
PBL_FRONTEND_PORT=81

# 本地开发环境配置
# COOKIE_DOMAIN=localhost
# COOKIE_SECURE=false
# PBL_FRONTEND_URL=http://localhost:81
# DEVICE_FRONTEND_URL=http://localhost:80
# CORS_ORIGINS=http://localhost:80,http://localhost:81
```

### 2. 生成安全的SECRET_KEY

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

将输出复制到 `.env` 文件的 `SECRET_KEY` 中。

## 📝 必需的代码修改

### 1. 更新 backend/main.py

在 `backend/main.py` 文件中添加PBL路由导入：

```python
# 在文件顶部添加导入
from app.api.pbl import (
    student_auth, teacher_auth, admin_auth,
    student_courses, teacher_courses, admin_courses,
    # 根据实际整合的模块调整导入
)

# 在路由注册部分添加
# PBL系统路由
app.include_router(student_auth.router, prefix="/api/v1/student/auth", tags=["pbl-student-auth"])
app.include_router(teacher_auth.router, prefix="/api/v1/teacher/auth", tags=["pbl-teacher-auth"])
app.include_router(admin_auth.router, prefix="/api/v1/admin/auth", tags=["pbl-admin-auth"])
# ... 其他PBL路由
```

### 2. 更新 backend/app/core/config.py

在 `Settings` 类中添加SSO配置：

```python
class Settings(BaseSettings):
    # ... 现有配置 ...
    
    # SSO单点登录配置
    cookie_domain: Optional[str] = None
    cookie_secure: bool = False
    cookie_samesite: str = "lax"
    pbl_frontend_url: Optional[str] = None
    device_frontend_url: Optional[str] = None
    cors_origins: str = "*"
    
    @property
    def get_cors_origins_list(self) -> list:
        if self.cors_origins == "*":
            return ["*"]
        return [origin.strip() for origin in self.cors_origins.split(",")]
```

### 3. 更新PBL登录接口

在 `backend/app/api/pbl/student_auth.py`（以及其他登录接口）中添加Cookie设置：

```python
from fastapi import Response

@router.post("/login")
async def login(
    response: Response,  # 添加这个参数
    login_data: LoginRequest,
    db: Session = Depends(get_db)
):
    # ... 现有的验证逻辑 ...
    
    # 生成token
    access_token = create_access_token(data={"sub": str(user.id)})
    
    # 设置SSO Cookie（新增）
    if settings.cookie_domain:
        response.set_cookie(
            key="sso_access_token",
            value=access_token,
            httponly=True,
            secure=settings.cookie_secure,
            samesite=settings.cookie_samesite,
            domain=settings.cookie_domain,
            max_age=settings.access_token_expire_minutes * 60,
            path="/"
        )
    
    return {"access_token": access_token, "user": user}
```

### 4. 更新 docker-compose.prod.yml

在 `backend` 服务中添加SSO环境变量：

```yaml
services:
  backend:
    environment:
      # ... 现有配置 ...
      
      # SSO配置（新增）
      COOKIE_DOMAIN: ${COOKIE_DOMAIN}
      COOKIE_SECURE: ${COOKIE_SECURE:-true}
      COOKIE_SAMESITE: ${COOKIE_SAMESITE:-lax}
      CORS_ORIGINS: ${CORS_ORIGINS}
      PBL_FRONTEND_URL: ${PBL_FRONTEND_URL}
      DEVICE_FRONTEND_URL: ${DEVICE_FRONTEND_URL}
```

添加PBL前端服务：

```yaml
  # PBL前端（新增）
  frontend-pbl:
    build:
      context: ../frontend-pbl
      dockerfile: Dockerfile
    container_name: codehubot-frontend-pbl
    environment:
      - VITE_API_BASE_URL=/api
      - VITE_DEVICE_FRONTEND_URL=${DEVICE_FRONTEND_URL}
    ports:
      - "${PBL_FRONTEND_PORT:-81}:80"
    networks:
      - aiot-network
    depends_on:
      backend:
        condition: service_healthy
    restart: unless-stopped
```

## 🔄 前端跳转逻辑

### PBL前端 → Device前端

创建 `frontend-pbl/src/utils/sso.js`：

```javascript
export function jumpToDevice(path = '/') {
    const deviceUrl = import.meta.env.VITE_DEVICE_FRONTEND_URL
    const token = localStorage.getItem('access_token')
    
    const url = new URL(path, deviceUrl)
    url.searchParams.set('sso_token', token)
    window.location.href = url.toString()
}
```

在PBL页面中使用：

```vue
<template>
  <el-button @click="jumpToDeviceManagement">
    进入设备管理系统
  </el-button>
</template>

<script setup>
import { jumpToDevice } from '@/utils/sso'

function jumpToDeviceManagement() {
    jumpToDevice('/devices')
}
</script>
```

### Device前端接收SSO

创建 `frontend/src/utils/auth.js`：

```javascript
export async function initAuth() {
    // 检查URL参数中的token
    const urlParams = new URLSearchParams(window.location.search)
    const ssoToken = urlParams.get('sso_token')
    
    if (ssoToken) {
        localStorage.setItem('access_token', ssoToken)
        window.history.replaceState({}, document.title, window.location.pathname)
        return true
    }
    
    // 检查LocalStorage
    const token = localStorage.getItem('access_token')
    if (token) {
        const isValid = await validateToken(token)
        return isValid
    }
    
    return false
}
```

在 `frontend/src/main.js` 中调用：

```javascript
import { initAuth } from './utils/auth'

async function bootstrap() {
    const isAuthenticated = await initAuth()
    
    if (!isAuthenticated && !window.location.pathname.includes('/login')) {
        window.location.href = '/login'
        return
    }
    
    createApp(App).use(router).mount('#app')
}

bootstrap()
```

## 🗄️ 数据库初始化

```bash
# 进入数据库容器
docker-compose -f docker/docker-compose.prod.yml exec mysql bash

# 初始化Device系统表
mysql -u aiot_user -p aiot_admin < /path/to/init_database.sql

# 初始化PBL系统表
mysql -u aiot_user -p aiot_admin < /path/to/pbl_schema.sql
```

## 🚢 部署

```bash
cd docker

# 构建并启动所有服务
docker-compose -f docker-compose.prod.yml up --build -d

# 查看日志
docker-compose -f docker-compose.prod.yml logs -f

# 检查服务状态
docker-compose -f docker-compose.prod.yml ps
```

访问地址：
- PBL前端：http://localhost:81 或 https://pbl.yourdomain.com
- Device前端：http://localhost:80 或 https://device.yourdomain.com
- 后端API：http://localhost:8000/docs

## ✅ 测试SSO

1. 访问PBL系统并登录
2. 在PBL系统中点击"进入设备管理"按钮
3. 检查是否自动登录到Device系统（无需重新输入密码）

## 🐛 调试

查看Cookie是否设置成功：
1. 打开浏览器开发者工具 → Application → Cookies
2. 检查是否有 `sso_access_token`
3. 检查Cookie的Domain是否为 `.yourdomain.com`

查看后端日志：
```bash
docker-compose -f docker/docker-compose.prod.yml logs -f backend
```

## 📚 详细文档

查看完整的整合指南：`docs/PBL系统整合指南.md`

## ❓ 常见问题

**Q: Cookie无法共享？**
A: 检查：
- 两个前端必须是同一主域名的子域名
- Cookie的domain设置为 `.yourdomain.com`（注意前面的点）
- 生产环境必须使用HTTPS

**Q: Token验证失败？**
A: 确保两个后端使用完全相同的SECRET_KEY

**Q: 本地开发如何测试？**
A: 设置 `COOKIE_DOMAIN=localhost`，通过不同端口访问（80和81）

---

**整合愉快！** 🎉
