# 前端应用

基于 Vue 3 + Vite 的物联网设备管理前端应用。

## 技术栈

- **Vue 3** - 前端框架
- **Vite** - 构建工具
- **Element Plus** - UI 组件库
- **Vue Router** - 路由管理
- **Pinia** - 状态管理
- **ECharts** - 数据可视化
- **Axios** - HTTP 客户端

## 快速开始

### 1. 安装依赖

```bash
npm install
```

### 2. 配置API地址

编辑 `src/api/request.js`，修改后端API地址：

```javascript
const baseURL = 'http://localhost:8000'  // 开发环境
// const baseURL = 'https://your-domain.com'  // 生产环境
```

### 3. 启动开发服务器

```bash
npm run dev
```

访问：http://localhost:5173

### 4. 构建生产版本

```bash
npm run build
```

构建产物在 `dist/` 目录。

## 项目结构

```
frontend/
├── src/
│   ├── api/          # API 接口
│   ├── components/    # 组件
│   ├── views/        # 页面
│   ├── router/       # 路由
│   ├── store/        # 状态管理
│   ├── utils/        # 工具函数
│   └── styles/       # 样式
├── public/           # 静态资源
├── package.json      # 依赖配置
└── vite.config.js    # Vite 配置
```

## 部署

### 开发环境

```bash
npm run dev
```

### 生产环境

#### 方法一：静态文件部署

```bash
# 构建
npm run build

# 将 dist/ 目录部署到 Web 服务器
# 例如：Nginx、Apache、CDN 等
```

#### 方法二：使用 Docker

```bash
# 构建生产镜像（需要先创建生产环境的 Dockerfile）
docker build -t aiot-frontend -f Dockerfile.prod .

# 运行容器
docker run -d \
  --name aiot-frontend \
  -p 80:80 \
  aiot-frontend
```

创建 `Dockerfile.prod`:

```dockerfile
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

#### 方法三：使用 Nginx 部署

1. 构建项目：

```bash
npm run build
```

2. 复制文件到 Nginx 目录：

```bash
sudo cp -r dist/* /var/www/aiot-admin/
```

3. 配置 Nginx（参考 Docker 部署文档或使用 `nginx.conf` 作为参考）

### 环境配置

#### 开发环境

在 `vite.config.js` 中配置代理：

```javascript
export default {
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true
      }
    }
  }
}
```

#### 生产环境

修改 `src/api/request.js` 中的 `baseURL`：

```javascript
const baseURL = import.meta.env.VITE_API_BASE_URL || 'https://your-domain.com'
```

使用环境变量文件 `.env.production`:

```bash
VITE_API_BASE_URL=https://api.your-domain.com
```

### 构建优化

```bash
# 分析构建产物大小
npm run build -- --report

# 预览构建结果
npm run preview
```

### 常见问题

#### 1. 路由刷新 404

确保 Web 服务器配置了 History 模式支持（参考 `nginx.conf` 中的配置）

#### 2. API 请求跨域

- 开发环境：配置 Vite 代理
- 生产环境：使用 Nginx 反向代理或配置后端 CORS

#### 3. 静态资源路径错误

在 `vite.config.js` 中配置 `base`:

```javascript
export default {
  base: '/',  // 或 '/aiot-admin/' 如果部署在子目录
}
```

