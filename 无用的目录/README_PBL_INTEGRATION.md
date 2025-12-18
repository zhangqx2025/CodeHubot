# CodeHubot-PBL 整合方案总结

## ✅ 已完成的工作

我已经为你准备了完整的PBL系统整合方案，包括：

### 📄 文档（3个）
1. **`integrate_pbl.sh`** - 自动化整合脚本
   - 自动备份项目
   - 复制PBL前后端代码到正确位置
   - 合并SQL脚本和文档
   
2. **`docs/PBL系统整合指南.md`** - 详细整合指南（60+ KB）
   - 完整的整合步骤
   - SSO单点登录原理和配置
   - Docker配置详解
   - 前端跳转逻辑
   - 常见问题排查
   
3. **`PBL_INTEGRATION_QUICKSTART.md`** - 快速开始指南
   - 一键整合命令
   - 必要的代码修改清单
   - 环境变量配置模板
   - 测试和调试指南

### 🎯 整合方案特点

1. **最小侵入性**
   - 保持两个系统的独立性
   - 通过共享认证模块实现SSO
   - 不需要大规模重构代码

2. **统一认证（SSO）**
   - 用户在PBL登录后，可直接跳转到Device系统
   - 基于JWT + Cookie的单点登录
   - 共享用户数据库

3. **模块化整合**
   - PBL代码独立放在 `backend/app/api/pbl/` 目录
   - 两个前端分别部署（端口80和81）
   - 统一的后端API服务

## 📋 你需要做的事情

### 第一步：运行整合脚本（5分钟）

```bash
cd /Users/zhangqixun/AICodeing/CodeHubot工作空间/CodeHubot
./integrate_pbl.sh
```

### 第二步：修改配置文件（10分钟）

按照 `PBL_INTEGRATION_QUICKSTART.md` 中的说明，修改以下文件：

1. ✏️ `docker/.env` - 添加SSO配置
2. ✏️ `backend/main.py` - 注册PBL路由
3. ✏️ `backend/app/core/config.py` - 添加SSO配置
4. ✏️ `backend/app/api/pbl/*_auth.py` - 设置SSO Cookie
5. ✏️ `docker/docker-compose.prod.yml` - 添加PBL前端服务

### 第三步：前端跳转逻辑（10分钟）

1. 在PBL前端创建 `jumpToDevice()` 函数
2. 在Device前端创建 `initAuth()` 函数
3. 在合适的地方添加跳转按钮

### 第四步：数据库初始化（5分钟）

```bash
# 初始化PBL数据库表
mysql -u root -p aiot_admin < SQL/pbl/pbl_schema.sql
```

### 第五步：部署测试（5分钟）

```bash
cd docker
docker-compose -f docker-compose.prod.yml up --build -d
```

访问测试：
- PBL: http://localhost:81
- Device: http://localhost:80

## 🗂️ 整合后的项目结构

```
CodeHubot/
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   ├── auth.py              # Device认证
│   │   │   ├── devices.py           # Device管理
│   │   │   ├── pbl/                 # 🆕 PBL模块
│   │   │   │   ├── student_auth.py  # 学生认证
│   │   │   │   ├── teacher_auth.py  # 教师认证
│   │   │   │   ├── admin_auth.py    # 管理员认证
│   │   │   │   └── ...              # 其他PBL API
│   │   │   └── ...
│   │   ├── models/
│   │   │   ├── user.py              # 统一用户模型
│   │   │   ├── device.py
│   │   │   ├── pbl/                 # 🆕 PBL模型
│   │   │   │   ├── course.py
│   │   │   │   └── ...
│   │   │   └── ...
│   │   └── ...
│   └── main.py
│
├── frontend/                         # Device前端
│   └── ...
│
├── frontend-pbl/                     # 🆕 PBL前端
│   ├── src/
│   │   ├── views/
│   │   │   ├── AdminDashboard.vue
│   │   │   ├── StudentCourses.vue
│   │   │   └── ...
│   │   └── utils/
│   │       └── sso.js                # SSO跳转工具
│   └── ...
│
├── docker/
│   ├── docker-compose.prod.yml       # 包含两个前端服务
│   └── .env                          # 统一配置
│
├── SQL/
│   ├── init_database.sql             # Device表
│   └── pbl/
│       └── pbl_schema.sql            # PBL表
│
├── docs/
│   ├── PBL系统整合指南.md            # 详细文档
│   └── ...
│
├── integrate_pbl.sh                  # 整合脚本
├── PBL_INTEGRATION_QUICKSTART.md     # 快速指南
└── README_PBL_INTEGRATION.md         # 本文件
```

## 🔑 SSO工作原理

```
┌──────────────────────────────────────────────────────┐
│  用户在PBL登录（https://pbl.yourdomain.com）           │
│  ↓                                                     │
│  后端验证成功，生成JWT Token                            │
│  ↓                                                     │
│  设置Cookie (domain=.yourdomain.com)                  │
│  ↓                                                     │
│  返回Token给前端                                        │
└──────────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────────┐
│  用户点击"进入设备管理"按钮                              │
│  ↓                                                     │
│  携带Token跳转到Device (https://device.yourdomain.com) │
│  ↓                                                     │
│  Device前端从URL或Cookie获取Token                      │
│  ↓                                                     │
│  Device后端验证Token（使用相同的SECRET_KEY）            │
│  ↓                                                     │
│  自动登录成功！无需重新输入密码                           │
└──────────────────────────────────────────────────────┘
```

## 🎨 关键技术点

### 1. 共享JWT密钥
```bash
# docker/.env
SECRET_KEY=your-super-secret-key-must-be-same-for-both-systems
```

### 2. Cookie域名配置
```bash
COOKIE_DOMAIN=.yourdomain.com  # 注意前面的点！
```

### 3. CORS配置
```bash
CORS_ORIGINS=https://pbl.yourdomain.com,https://device.yourdomain.com
```

### 4. 登录接口设置Cookie
```python
response.set_cookie(
    key="sso_access_token",
    value=access_token,
    domain=".yourdomain.com",  # 关键！
    httponly=True,
    secure=True
)
```

## 🔍 验证清单

整合完成后，检查以下项目：

- [ ] `integrate_pbl.sh` 脚本执行成功
- [ ] `frontend-pbl/` 目录存在且包含PBL前端代码
- [ ] `backend/app/api/pbl/` 目录存在且包含PBL API
- [ ] `docker/.env` 已配置SSO相关变量
- [ ] `backend/main.py` 已注册PBL路由
- [ ] `backend/app/core/config.py` 已添加SSO配置
- [ ] PBL登录接口已设置SSO Cookie
- [ ] `docker-compose.prod.yml` 已添加PBL前端服务
- [ ] 数据库已初始化PBL表
- [ ] 两个前端可以正常访问
- [ ] SSO跳转功能正常工作

## 📞 技术支持

### 调试技巧

1. **查看Cookie**
   ```
   浏览器开发者工具 → Application → Cookies
   检查 sso_access_token 是否存在
   ```

2. **查看后端日志**
   ```bash
   docker-compose -f docker/docker-compose.prod.yml logs -f backend
   ```

3. **测试Token验证**
   ```bash
   curl -H "Authorization: Bearer YOUR_TOKEN" \
        http://localhost:8000/api/auth/user-info
   ```

### 常见问题

| 问题 | 解决方案 |
|------|---------|
| Cookie无法共享 | 检查domain是否为 `.yourdomain.com` |
| Token验证失败 | 检查两个后端的SECRET_KEY是否相同 |
| CORS错误 | 检查CORS_ORIGINS配置是否包含两个前端地址 |
| 本地开发无法测试 | 设置 `COOKIE_DOMAIN=localhost` |

## 📚 相关文档

1. **详细整合指南**: `docs/PBL系统整合指南.md`
2. **快速开始**: `PBL_INTEGRATION_QUICKSTART.md`
3. **原PBL文档**: `docs/pbl/` （整合脚本会自动复制）

## 💡 下一步建议

整合完成后，你可能还需要：

1. **配置Nginx反向代理**（生产环境）
   ```nginx
   server {
       server_name pbl.yourdomain.com;
       location / {
           proxy_pass http://localhost:81;
       }
   }
   
   server {
       server_name device.yourdomain.com;
       location / {
           proxy_pass http://localhost:80;
       }
   }
   ```

2. **配置HTTPS证书**
   ```bash
   certbot --nginx -d pbl.yourdomain.com -d device.yourdomain.com
   ```

3. **优化前端跳转体验**
   - 添加跳转前的提示
   - 记住用户的跳转偏好
   - 添加快捷导航菜单

4. **统一用户管理**
   - 考虑合并两个系统的用户表
   - 添加角色权限管理
   - 实现用户资料的统一修改

## 🎉 总结

这个整合方案为你提供了：
- ✅ **完整的自动化脚本** - 一键整合
- ✅ **详细的文档** - 60KB+的整合指南
- ✅ **SSO单点登录** - 用户体验优化
- ✅ **最小改动** - 保持系统独立性
- ✅ **统一管理** - 一个项目部署两个系统

如有任何问题，请查看详细文档或联系技术支持。

**祝整合顺利！** 🚀
