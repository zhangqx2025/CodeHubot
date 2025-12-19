#!/bin/bash
# ============================================================================
# 执行数据库更新脚本 32
# 创建 aiot_access_logs 表
# ============================================================================

set -e  # 遇到错误立即退出

echo "=========================================="
echo "  执行数据库更新: 32_add_aiot_access_logs_table.sql"
echo "=========================================="
echo ""

# 读取数据库配置
read -p "请输入数据库主机 (默认: rm-2ze6kg4ws2dii977b.mysql.rds.aliyuncs.com): " DB_HOST
DB_HOST=${DB_HOST:-rm-2ze6kg4ws2dii977b.mysql.rds.aliyuncs.com}

read -p "请输入数据库名称 (默认: pbl-powertechhub-com): " DB_NAME
DB_NAME=${DB_NAME:-pbl-powertechhub-com}

read -p "请输入数据库用户名 (默认: saas): " DB_USER
DB_USER=${DB_USER:-saas}

read -sp "请输入数据库密码: " DB_PASSWORD
echo ""

# 执行SQL脚本
echo ""
echo "正在执行SQL脚本..."
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < 32_add_aiot_access_logs_table.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 数据库更新成功！"
    echo ""
    echo "验证表是否创建成功..."
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SHOW TABLES LIKE 'aiot_access_logs';"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "DESC aiot_access_logs;"
else
    echo ""
    echo "❌ 数据库更新失败！"
    exit 1
fi

echo ""
echo "=========================================="
echo "  更新完成！"
echo "=========================================="
