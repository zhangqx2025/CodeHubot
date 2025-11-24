# Docker 服务配置

Docker Compose 编排的基础设施服务。

## 服务列表

| 服务 | 端口 | 说明 |
|------|------|------|
| MySQL | 3306 | 数据库 |
| MQTT | 1883, 9001 | 消息代理 |

## 快速开始

### 启动服务

```bash
cd docker
docker-compose up -d
```

### 查看状态

```bash
docker-compose ps
docker-compose logs -f
```

### 停止服务

```bash
docker-compose down
```

## 配置文件

- `docker-compose.yml` - Docker Compose 配置
- `mosquitto.conf` - MQTT 服务器配置

## 数据持久化

数据存储在 `./data` 目录：
- `mysql/` - MySQL 数据
- `mosquitto/` - MQTT 数据

## 常用命令

```bash
# 查看日志
docker-compose logs -f mysql
docker-compose logs -f mqtt

# 重启服务
docker-compose restart mysql

# 进入容器
docker-compose exec mysql mysql -u root -p
```
