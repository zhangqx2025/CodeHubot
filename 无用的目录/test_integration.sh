#!/bin/bash

# ============================================================
# 整合测试脚本
# 功能：测试整合后的系统是否正常工作
# ============================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}   整合测试脚本${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

PASSED=0
FAILED=0

# 测试函数
test_passed() {
    echo -e "${GREEN}✓ $1${NC}"
    ((PASSED++))
}

test_failed() {
    echo -e "${RED}✗ $1${NC}"
    ((FAILED++))
}

# ============================================================
# 1. 检查目录结构
# ============================================================

echo -e "${YELLOW}[1/7] 检查目录结构...${NC}"

if [ -d "backend/app/api/pbl" ]; then
    test_passed "backend/app/api/pbl 目录存在"
else
    test_failed "backend/app/api/pbl 目录不存在"
fi

if [ -d "frontend/src/modules/device" ]; then
    test_passed "frontend/src/modules/device 目录存在"
else
    test_failed "frontend/src/modules/device 目录不存在"
fi

if [ -d "frontend/src/modules/pbl" ]; then
    test_passed "frontend/src/modules/pbl 目录存在"
else
    test_failed "frontend/src/modules/pbl 目录不存在"
fi

echo ""

# ============================================================
# 2. 检查后端文件
# ============================================================

echo -e "${YELLOW}[2/7] 检查后端文件...${NC}"

PBL_API_COUNT=$(ls -1 backend/app/api/pbl/*.py 2>/dev/null | wc -l | tr -d ' ')
if [ "$PBL_API_COUNT" -gt 10 ]; then
    test_passed "PBL API文件数量: $PBL_API_COUNT"
else
    test_failed "PBL API文件数量不足: $PBL_API_COUNT (应该>10)"
fi

if [ -f "backend/app/api/pbl/__init__.py" ]; then
    test_passed "PBL路由注册文件存在"
else
    test_failed "PBL路由注册文件不存在"
fi

if grep -q "pbl_router" backend/app/api/__init__.py 2>/dev/null; then
    test_passed "主路由已注册PBL路由"
else
    test_failed "主路由未注册PBL路由"
fi

echo ""

# ============================================================
# 3. 检查前端文件
# ============================================================

echo -e "${YELLOW}[3/7] 检查前端文件...${NC}"

if [ -f "frontend/package.json" ]; then
    test_passed "package.json存在"
else
    test_failed "package.json不存在"
fi

if [ -f "frontend/src/main.js" ]; then
    test_passed "main.js存在"
else
    test_failed "main.js不存在"
fi

if [ -f "frontend/src/router/index.js" ]; then
    test_passed "路由配置存在"
else
    test_failed "路由配置不存在"
fi

if [ -f "frontend/src/stores/auth.js" ]; then
    test_passed "认证store存在"
else
    test_failed "认证store不存在"
fi

echo ""

# ============================================================
# 4. 检查布局组件
# ============================================================

echo -e "${YELLOW}[4/7] 检查布局组件...${NC}"

LAYOUTS=("DeviceLayout.vue" "PBLStudentLayout.vue" "PBLTeacherLayout.vue" "PBLAdminLayout.vue")
for layout in "${LAYOUTS[@]}"; do
    if [ -f "frontend/src/layouts/$layout" ]; then
        test_passed "$layout 存在"
    else
        test_failed "$layout 不存在"
    fi
done

echo ""

# ============================================================
# 5. 检查页面组件
# ============================================================

echo -e "${YELLOW}[5/7] 检查页面组件...${NC}"

VIEWS=("Login.vue" "Portal.vue" "NotFound.vue")
for view in "${VIEWS[@]}"; do
    if [ -f "frontend/src/views/$view" ]; then
        test_passed "$view 存在"
    else
        test_failed "$view 不存在"
    fi
done

echo ""

# ============================================================
# 6. 检查依赖
# ============================================================

echo -e "${YELLOW}[6/7] 检查依赖...${NC}"

if [ -f "backend/requirements.txt" ]; then
    test_passed "backend/requirements.txt存在"
    
    # 检查关键依赖
    if grep -q "fastapi" backend/requirements.txt; then
        test_passed "FastAPI依赖存在"
    else
        test_failed "FastAPI依赖缺失"
    fi
else
    test_failed "backend/requirements.txt不存在"
fi

if [ -f "frontend/package.json" ]; then
    if grep -q "vue" frontend/package.json; then
        test_passed "Vue依赖存在"
    else
        test_failed "Vue依赖缺失"
    fi
    
    if grep -q "element-plus" frontend/package.json; then
        test_passed "Element Plus依赖存在"
    else
        test_failed "Element Plus依赖缺失"
    fi
    
    if grep -q "pinia" frontend/package.json; then
        test_passed "Pinia依赖存在"
    else
        test_failed "Pinia依赖缺失"
    fi
fi

echo ""

# ============================================================
# 7. 尝试语法检查
# ============================================================

echo -e "${YELLOW}[7/7] 语法检查...${NC}"

# Python语法检查
if command -v python3 &> /dev/null; then
    if python3 -m py_compile backend/app/api/__init__.py 2>/dev/null; then
        test_passed "后端主路由语法正确"
    else
        test_failed "后端主路由语法错误"
    fi
else
    echo -e "${YELLOW}⚠ Python3未安装，跳过语法检查${NC}"
fi

# JavaScript语法检查
if command -v node &> /dev/null; then
    if node -c frontend/src/main.js 2>/dev/null; then
        test_passed "前端入口文件语法正确"
    else
        test_failed "前端入口文件语法错误"
    fi
else
    echo -e "${YELLOW}⚠ Node.js未安装，跳过语法检查${NC}"
fi

echo ""

# ============================================================
# 测试结果
# ============================================================

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}   测试结果${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""
echo -e "通过: ${GREEN}$PASSED${NC}"
echo -e "失败: ${RED}$FAILED${NC}"
echo -e "总计: $((PASSED + FAILED))"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ 所有测试通过！系统已准备就绪！${NC}"
    echo ""
    echo -e "${YELLOW}下一步：${NC}"
    echo -e "  1. 启动后端: cd backend && python main.py"
    echo -e "  2. 启动前端: cd frontend && npm run dev"
    echo -e "  3. 访问: http://localhost:3000"
    exit 0
else
    echo -e "${RED}⚠️ 有 $FAILED 个测试失败${NC}"
    echo ""
    echo -e "${YELLOW}建议：${NC}"
    echo -e "  1. 检查失败的测试项"
    echo -e "  2. 重新运行整合脚本: ./integrate_all.sh"
    echo -e "  3. 查看详细报告: cat COMPLETE_INTEGRATION_REPORT.md"
    exit 1
fi
