# Nginx 配置

Nginx 反向代理配置文件。

## 文件说明

- `aiot-admin.conf` - 主配置文件（HTTP）
- `baota-aiot-admin.conf` - 宝塔面板配置（可选）

## 快速部署

### 1. 复制配置文件

```bash
sudo cp aiot-admin.conf /etc/nginx/sites-available/aiot-admin
sudo ln -s /etc/nginx/sites-available/aiot-admin /etc/nginx/sites-enabled/
```

### 2. 修改配置

编辑配置文件，修改以下内容：
- `server_name` - 域名
- `root` - 前端文件路径
- `proxy_pass` - 后端服务地址

### 3. 测试并重启

```bash
sudo nginx -t
sudo nginx -s reload
```

## 关键配置

### Vue Router History 模式

```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

### API 代理

```nginx
location /api {
    proxy_pass http://127.0.0.1:8000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

## HTTPS 配置

使用 Let's Encrypt 免费证书：

```bash
sudo certbot --nginx -d your-domain.com
```
