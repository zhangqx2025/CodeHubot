# plugin-backend-service 数据库连接故障排查

## 🔍 快速诊断

### 1. 检查 .env 文件是否存在

```bash
cd /opt/CodeHubot/CodeHubot-main/plugin-backend-service
ls -la .env
```

如果不存在，需要创建：
```bash
cp env.example .env
nano .env
```

### 2. 检查数据库配置

查看当前配置：
```bash
cat .env | grep DB_
```

应该看到：
```
DB_HOST=localhost
DB_PORT=3306
DB_NAME=aiot
DB_USER=aiot_user
DB_PASSWORD=实际密码
```

### 3. 测试数据库连接

```bash
# 使用 mysql 命令行测试
mysql -h localhost -P 3306 -u aiot_user -p aiot

# 输入密码后应该能连接成功
```

如果连接失败，查看错误信息：
- **Access denied**: 密码错误或用户不存在
- **Unknown database**: 数据库不存在
- **Can't connect**: MySQL 服务未运行

## 🛠️ 常见问题解决

### 问题1: 密码错误（Access denied）

**症状**：
```
Access denied for user 'aiot_user'@'localhost'
```

**解决方案**：

```bash
# 1. 使用 root 登录 MySQL
mysql -u root -p

# 2. 检查用户是否存在
USE mysql;
SELECT user, host FROM user WHERE user = 'aiot_user';

# 3. 如果用户不存在，创建用户
CREATE USER 'aiot_user'@'localhost' IDENTIFIED BY '你的密码';
GRANT ALL PRIVILEGES ON aiot.* TO 'aiot_user'@'localhost';
FLUSH PRIVILEGES;

# 4. 如果用户存在但密码忘记，重置密码
ALTER USER 'aiot_user'@'localhost' IDENTIFIED BY '新密码';
FLUSH PRIVILEGES;
```

### 问题2: 数据库不存在（Unknown database）

**症状**：
```
Unknown database 'aiot'
```

**解决方案**：

```bash
# 1. 登录 MySQL
mysql -u root -p

# 2. 创建数据库
CREATE DATABASE aiot CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# 3. 导入初始化脚本
USE aiot;
SOURCE /opt/CodeHubot/CodeHubot-main/SQL/init_database.sql;

# 4. 执行更新脚本（如果需要）
SOURCE /opt/CodeHubot/CodeHubot-main/SQL/update/19_make_email_optional.sql;
```

### 问题3: MySQL 服务未运行

**症状**：
```
Can't connect to MySQL server
```

**解决方案**：

```bash
# 检查 MySQL 服务状态
sudo systemctl status mysql

# 如果未运行，启动服务
sudo systemctl start mysql

# 设置开机自启
sudo systemctl enable mysql
```

### 问题4: .env 文件配置错误

**检查配置文件语法**：

```bash
# 查看配置（隐藏密码）
cat .env | grep -v PASSWORD

# 确保没有多余空格
cat .env | grep DB_ | cat -A
```

**正确的格式**：
```env
# ✅ 正确
DB_HOST=localhost
DB_PORT=3306
DB_NAME=aiot
DB_USER=aiot_user
DB_PASSWORD=your_password

# ❌ 错误（有空格）
DB_HOST = localhost
DB_PORT = 3306
```

### 问题5: Docker 环境下的数据库连接

如果使用 Docker Compose，数据库主机应该是容器名：

```env
# Docker 环境
DB_HOST=mysql  # 不是 localhost
DB_PORT=3306
DB_NAME=aiot
DB_USER=aiot_user
DB_PASSWORD=your_password
```

## 📋 完整配置步骤

### 方案A: 使用现有数据库

```bash
# 1. 进入目录
cd /opt/CodeHubot/CodeHubot-main/plugin-backend-service

# 2. 复制配置文件
cp env.example .env

# 3. 编辑配置
nano .env

# 修改以下内容：
# DB_HOST=localhost
# DB_PORT=3306
# DB_NAME=aiot
# DB_USER=aiot_user
# DB_PASSWORD=从 backend/.env 复制相同的密码

# 4. 保存并测试
python main.py
```

### 方案B: 从 backend 复制配置

```bash
# 1. 查看 backend 的数据库配置
cd /opt/CodeHubot/CodeHubot-main/backend
cat .env | grep DATABASE_URL

# 应该看到类似：
# DATABASE_URL=mysql+pymysql://aiot_user:密码@localhost:3306/aiot

# 2. 提取数据库信息
# 用户名: aiot_user
# 密码: (从 URL 中提取)
# 主机: localhost
# 端口: 3306
# 数据库: aiot

# 3. 配置 plugin-backend-service
cd ../plugin-backend-service
nano .env

# 填入相同的配置
```

## 🔧 一键配置脚本

创建配置脚本：

```bash
cd /opt/CodeHubot/CodeHubot-main/plugin-backend-service

# 创建配置脚本
cat > setup_db_config.sh << 'EOF'
#!/bin/bash

echo "🔧 配置 plugin-backend-service 数据库连接"
echo

# 从 backend 提取数据库配置
if [ -f "../backend/.env" ]; then
    DB_URL=$(grep DATABASE_URL ../backend/.env | cut -d'=' -f2)
    echo "从 backend 读取到数据库配置"
    
    # 解析 URL
    # mysql+pymysql://user:pass@host:port/db
    DB_USER=$(echo $DB_URL | sed 's/.*:\/\/\([^:]*\):.*/\1/')
    DB_PASSWORD=$(echo $DB_URL | sed 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/')
    DB_HOST=$(echo $DB_URL | sed 's/.*@\([^:]*\):.*/\1/')
    DB_PORT=$(echo $DB_URL | sed 's/.*:\([0-9]*\)\/.*/\1/')
    DB_NAME=$(echo $DB_URL | sed 's/.*\/\([^?]*\).*/\1/')
    
    echo "数据库配置："
    echo "  主机: $DB_HOST"
    echo "  端口: $DB_PORT"
    echo "  数据库: $DB_NAME"
    echo "  用户: $DB_USER"
    echo "  密码: [已隐藏]"
else
    echo "❌ 未找到 backend/.env 文件"
    echo "请手动配置"
    DB_HOST="localhost"
    DB_PORT="3306"
    DB_NAME="aiot"
    DB_USER="aiot_user"
    read -sp "请输入数据库密码: " DB_PASSWORD
    echo
fi

# 创建 .env 文件
cat > .env << ENVEOF
# ==================== 服务配置 ====================
SERVICE_PORT=9002
SERVICE_HOST=0.0.0.0

# ==================== 数据库配置 ====================
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD

# ==================== MQTT配置 ====================
MQTT_BROKER=localhost
MQTT_PORT=1883
MQTT_USERNAME=
MQTT_PASSWORD=
ENVEOF

echo "✅ 配置文件已创建"

# 测试连接
echo
echo "🔍 测试数据库连接..."
mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASSWORD -e "SELECT 'Database connection successful!' as result;" $DB_NAME 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ 数据库连接成功！"
else
    echo "❌ 数据库连接失败，请检查配置"
fi
EOF

# 添加执行权限
chmod +x setup_db_config.sh

# 执行脚本
./setup_db_config.sh
```

## 🧪 验证配置

```bash
# 1. 检查配置文件
cat .env

# 2. 测试 Python 数据库连接
python3 << 'EOF'
import os
from dotenv import load_dotenv

load_dotenv()

db_host = os.getenv("DB_HOST", "localhost")
db_port = os.getenv("DB_PORT", "3306")
db_name = os.getenv("DB_NAME", "aiot")
db_user = os.getenv("DB_USER", "aiot_user")
db_password = os.getenv("DB_PASSWORD", "password")

print(f"数据库配置:")
print(f"  主机: {db_host}")
print(f"  端口: {db_port}")
print(f"  数据库: {db_name}")
print(f"  用户: {db_user}")
print(f"  密码: {'*' * len(db_password)}")

try:
    import pymysql
    conn = pymysql.connect(
        host=db_host,
        port=int(db_port),
        user=db_user,
        password=db_password,
        database=db_name
    )
    print("\n✅ 数据库连接成功！")
    conn.close()
except Exception as e:
    print(f"\n❌ 数据库连接失败: {e}")
EOF
```

## 📞 获取帮助

如果以上方法都无法解决，请提供以下信息：

```bash
# 1. 查看错误日志
python main.py 2>&1 | head -50

# 2. 检查配置（隐藏密码）
cat .env | sed 's/PASSWORD=.*/PASSWORD=[HIDDEN]/'

# 3. MySQL 状态
sudo systemctl status mysql

# 4. 测试连接
mysql -h localhost -u aiot_user -p -e "SHOW DATABASES;"
```

---

**记住**：密码需要与 backend 服务使用的数据库密码一致！

