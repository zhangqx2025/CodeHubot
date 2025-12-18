#!/bin/bash

# CodeHubot-PBL 整合脚本
# 功能：将 CodeHubot-PBL 系统整合到 CodeHubot 主项目中
# 作者：AI Assistant
# 日期：2024-12-16

set -e  # 遇到错误立即退出

echo "=========================================="
echo "  CodeHubot-PBL 系统整合工具"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEHUBOT_DIR="$SCRIPT_DIR"
PBL_SOURCE_DIR="$(dirname "$CODEHUBOT_DIR")/CodeHubot-PBL"

echo -e "${BLUE}项目路径：${NC}"
echo "  CodeHubot: $CODEHUBOT_DIR"
echo "  PBL源码:   $PBL_SOURCE_DIR"
echo ""

# 检查PBL源码目录是否存在
if [ ! -d "$PBL_SOURCE_DIR" ]; then
    echo -e "${RED}❌ 错误：找不到 CodeHubot-PBL 目录${NC}"
    echo "   期望路径: $PBL_SOURCE_DIR"
    exit 1
fi

echo -e "${GREEN}✓ 找到 CodeHubot-PBL 源码${NC}"
echo ""

# 1. 备份当前项目
echo -e "${YELLOW}步骤 1/7: 创建备份...${NC}"
BACKUP_DIR="${CODEHUBOT_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
echo "  备份到: $BACKUP_DIR"
cp -r "$CODEHUBOT_DIR" "$BACKUP_DIR"
echo -e "${GREEN}✓ 备份完成${NC}"
echo ""

# 2. 创建必要的目录结构
echo -e "${YELLOW}步骤 2/7: 创建目录结构...${NC}"
mkdir -p "$CODEHUBOT_DIR/backend/app/api/pbl"
mkdir -p "$CODEHUBOT_DIR/backend/app/models/pbl"
mkdir -p "$CODEHUBOT_DIR/backend/app/schemas/pbl"
mkdir -p "$CODEHUBOT_DIR/backend/app/services/pbl"
echo -e "${GREEN}✓ 目录结构创建完成${NC}"
echo ""

# 3. 复制PBL前端
echo -e "${YELLOW}步骤 3/7: 整合PBL前端...${NC}"
if [ -d "$CODEHUBOT_DIR/frontend-pbl" ]; then
    echo "  frontend-pbl 已存在，跳过复制"
else
    echo "  复制 PBL 前端到 frontend-pbl..."
    cp -r "$PBL_SOURCE_DIR/frontend" "$CODEHUBOT_DIR/frontend-pbl"
    echo -e "${GREEN}✓ PBL前端复制完成${NC}"
fi
echo ""

# 4. 复制PBL后端API
echo -e "${YELLOW}步骤 4/7: 整合PBL后端API...${NC}"
echo "  复制 PBL API endpoints..."
cp -r "$PBL_SOURCE_DIR/backend/app/api/endpoints/"* "$CODEHUBOT_DIR/backend/app/api/pbl/" 2>/dev/null || true
echo -e "${GREEN}✓ PBL API复制完成${NC}"
echo ""

# 5. 复制PBL模型
echo -e "${YELLOW}步骤 5/7: 整合PBL数据模型...${NC}"
echo "  复制 PBL models..."
if [ -f "$PBL_SOURCE_DIR/backend/app/models/pbl.py" ]; then
    cp "$PBL_SOURCE_DIR/backend/app/models/pbl.py" "$CODEHUBOT_DIR/backend/app/models/pbl/"
fi
if [ -f "$PBL_SOURCE_DIR/backend/app/models/school.py" ]; then
    cp "$PBL_SOURCE_DIR/backend/app/models/school.py" "$CODEHUBOT_DIR/backend/app/models/pbl/"
fi
echo -e "${GREEN}✓ PBL模型复制完成${NC}"
echo ""

# 6. 复制PBL Schema
echo -e "${YELLOW}步骤 6/7: 整合PBL Schema...${NC}"
echo "  复制 PBL schemas..."
cp -r "$PBL_SOURCE_DIR/backend/app/schemas/"*.py "$CODEHUBOT_DIR/backend/app/schemas/pbl/" 2>/dev/null || true
echo -e "${GREEN}✓ PBL Schema复制完成${NC}"
echo ""

# 7. 复制PBL服务
echo -e "${YELLOW}步骤 7/7: 整合PBL服务...${NC}"
echo "  复制 PBL services..."
cp -r "$PBL_SOURCE_DIR/backend/app/services/"*.py "$CODEHUBOT_DIR/backend/app/services/pbl/" 2>/dev/null || true
echo -e "${GREEN}✓ PBL服务复制完成${NC}"
echo ""

# 8. 合并SQL脚本
echo -e "${YELLOW}额外步骤: 合并SQL脚本...${NC}"
mkdir -p "$CODEHUBOT_DIR/SQL/pbl"
if [ -f "$PBL_SOURCE_DIR/SQL/pbl_schema.sql" ]; then
    cp "$PBL_SOURCE_DIR/SQL/pbl_schema.sql" "$CODEHUBOT_DIR/SQL/pbl/"
    echo "  ✓ 复制 pbl_schema.sql"
fi
if [ -d "$PBL_SOURCE_DIR/SQL/update" ]; then
    cp -r "$PBL_SOURCE_DIR/SQL/update/"* "$CODEHUBOT_DIR/SQL/pbl/" 2>/dev/null || true
    echo "  ✓ 复制 PBL 更新脚本"
fi
echo -e "${GREEN}✓ SQL脚本合并完成${NC}"
echo ""

# 9. 复制PBL文档
echo -e "${YELLOW}额外步骤: 复制PBL文档...${NC}"
mkdir -p "$CODEHUBOT_DIR/docs/pbl"
if [ -d "$PBL_SOURCE_DIR/docs" ]; then
    cp -r "$PBL_SOURCE_DIR/docs/"* "$CODEHUBOT_DIR/docs/pbl/" 2>/dev/null || true
    echo -e "${GREEN}✓ PBL文档复制完成${NC}"
fi
echo ""

# 完成
echo "=========================================="
echo -e "${GREEN}✓ 整合完成！${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}下一步操作：${NC}"
echo ""
echo "1. 检查整合结果："
echo "   cd $CODEHUBOT_DIR"
echo "   tree -L 3 backend/app/api/pbl"
echo ""
echo "2. 更新 backend/main.py，注册PBL路由"
echo ""
echo "3. 更新 docker-compose.prod.yml，添加PBL前端服务"
echo ""
echo "4. 配置统一的环境变量（SSO配置）"
echo ""
echo "5. 合并数据库脚本（保留两个系统的表）"
echo ""
echo -e "${YELLOW}备份位置：${NC}"
echo "   $BACKUP_DIR"
echo ""
echo -e "${YELLOW}⚠️  注意事项：${NC}"
echo "   1. 请手动检查是否有文件冲突"
echo "   2. 需要手动修改导入路径（from app.api.endpoints 改为 from app.api.pbl）"
echo "   3. 确保两个系统使用相同的 SECRET_KEY（实现SSO）"
echo ""

