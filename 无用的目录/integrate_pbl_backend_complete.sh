#!/bin/bash

# ============================================================
# PBL后端完整整合脚本
# 功能：自动整合所有PBL后端代码到主backend
# ============================================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PBL_DIR="$SCRIPT_DIR/CodeHubot-PBL/backend"
BACKEND_DIR="$SCRIPT_DIR/backend"
BACKUP_DIR="$SCRIPT_DIR/backup_$(date +%Y%m%d_%H%M%S)"

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}   PBL后端完整整合脚本${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

# 检查目录
if [ ! -d "$PBL_DIR" ]; then
    echo -e "${RED}错误: 找不到PBL后端目录: $PBL_DIR${NC}"
    exit 1
fi

if [ ! -d "$BACKEND_DIR" ]; then
    echo -e "${RED}错误: 找不到主后端目录: $BACKEND_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 目录检查通过${NC}"
echo ""

# 创建备份
echo -e "${YELLOW}[1/8] 创建备份...${NC}"
mkdir -p "$BACKUP_DIR"
cp -r "$BACKEND_DIR" "$BACKUP_DIR/"
echo -e "${GREEN}✓ 备份完成: $BACKUP_DIR${NC}"
echo ""

# 创建PBL API目录
echo -e "${YELLOW}[2/8] 创建PBL API目录...${NC}"
mkdir -p "$BACKEND_DIR/app/api/pbl"
touch "$BACKEND_DIR/app/api/pbl/__init__.py"
echo -e "${GREEN}✓ 目录创建完成${NC}"
echo ""

# 复制所有PBL API文件
echo -e "${YELLOW}[3/8] 复制PBL API文件...${NC}"
if [ -d "$PBL_DIR/app/api/endpoints" ]; then
    cp -r "$PBL_DIR/app/api/endpoints/"*.py "$BACKEND_DIR/app/api/pbl/" 2>/dev/null || echo "部分文件可能不存在"
    echo -e "${GREEN}✓ 复制了 $(ls -1 $BACKEND_DIR/app/api/pbl/*.py 2>/dev/null | wc -l) 个API文件${NC}"
else
    echo -e "${YELLOW}⚠ PBL endpoints目录不存在${NC}"
fi
echo ""

# 复制PBL models
echo -e "${YELLOW}[4/8] 整合PBL models...${NC}"
if [ -d "$PBL_DIR/app/models" ]; then
    for model_file in "$PBL_DIR/app/models"/*.py; do
        if [ -f "$model_file" ]; then
            filename=$(basename "$model_file")
            # 跳过__init__.py
            if [ "$filename" != "__init__.py" ]; then
                # 检查是否已存在
                if [ ! -f "$BACKEND_DIR/app/models/$filename" ]; then
                    cp "$model_file" "$BACKEND_DIR/app/models/"
                    echo "  复制: $filename"
                else
                    echo "  跳过: $filename (已存在)"
                fi
            fi
        fi
    done
    echo -e "${GREEN}✓ Models整合完成${NC}"
else
    echo -e "${YELLOW}⚠ PBL models目录不存在${NC}"
fi
echo ""

# 复制PBL schemas
echo -e "${YELLOW}[5/8] 整合PBL schemas...${NC}"
if [ -d "$PBL_DIR/app/schemas" ]; then
    for schema_file in "$PBL_DIR/app/schemas"/*.py; do
        if [ -f "$schema_file" ]; then
            filename=$(basename "$schema_file")
            if [ "$filename" != "__init__.py" ]; then
                if [ ! -f "$BACKEND_DIR/app/schemas/$filename" ]; then
                    cp "$schema_file" "$BACKEND_DIR/app/schemas/"
                    echo "  复制: $filename"
                else
                    echo "  跳过: $filename (已存在)"
                fi
            fi
        fi
    done
    echo -e "${GREEN}✓ Schemas整合完成${NC}"
else
    echo -e "${YELLOW}⚠ PBL schemas目录不存在${NC}"
fi
echo ""

# 复制PBL services
echo -e "${YELLOW}[6/8] 整合PBL services...${NC}"
if [ -d "$PBL_DIR/app/services" ]; then
    mkdir -p "$BACKEND_DIR/app/services/pbl"
    touch "$BACKEND_DIR/app/services/pbl/__init__.py"
    
    for service_file in "$PBL_DIR/app/services"/*.py; do
        if [ -f "$service_file" ]; then
            filename=$(basename "$service_file")
            if [ "$filename" != "__init__.py" ]; then
                cp "$service_file" "$BACKEND_DIR/app/services/pbl/"
                echo "  复制: $filename"
            fi
        fi
    done
    echo -e "${GREEN}✓ Services整合完成${NC}"
else
    echo -e "${YELLOW}⚠ PBL services目录不存在${NC}"
fi
echo ""

# 更新导入路径
echo -e "${YELLOW}[7/8] 更新导入路径...${NC}"

# 更新PBL API文件中的导入路径
if [ -d "$BACKEND_DIR/app/api/pbl" ]; then
    find "$BACKEND_DIR/app/api/pbl" -type f -name "*.py" -exec sed -i '' \
        -e 's|from app\.api\.endpoints|from app.api.pbl|g' \
        -e 's|from app\.schemas|from app.schemas|g' \
        -e 's|from app\.models|from app.models|g' \
        -e 's|from app\.services|from app.services.pbl|g' \
        -e 's|from app\.core|from app.core|g' \
        {} +
    echo -e "${GREEN}✓ API导入路径更新完成${NC}"
fi

# 更新PBL services中的导入路径
if [ -d "$BACKEND_DIR/app/services/pbl" ]; then
    find "$BACKEND_DIR/app/services/pbl" -type f -name "*.py" -exec sed -i '' \
        -e 's|from app\.services|from app.services.pbl|g' \
        -e 's|from app\.models|from app.models|g' \
        -e 's|from app\.schemas|from app.schemas|g' \
        {} +
    echo -e "${GREEN}✓ Services导入路径更新完成${NC}"
fi
echo ""

# 创建PBL路由注册文件
echo -e "${YELLOW}[8/8] 创建PBL路由注册文件...${NC}"

cat > "$BACKEND_DIR/app/api/pbl/__init__.py" << 'EOF'
"""
PBL系统API路由
自动整合所有PBL相关的API端点
"""
from fastapi import APIRouter

# 创建PBL主路由
pbl_router = APIRouter()

# 尝试导入所有PBL endpoint
# 学生端路由
try:
    from app.api.pbl.student_auth import router as student_auth_router
    pbl_router.include_router(student_auth_router, prefix="/student/auth", tags=["PBL-学生认证"])
except ImportError as e:
    print(f"警告: 无法导入student_auth: {e}")

try:
    from app.api.pbl.student_courses import router as student_courses_router
    pbl_router.include_router(student_courses_router, prefix="/student/courses", tags=["PBL-学生课程"])
except ImportError as e:
    print(f"警告: 无法导入student_courses: {e}")

try:
    from app.api.pbl.student_tasks import router as student_tasks_router
    pbl_router.include_router(student_tasks_router, prefix="/student/tasks", tags=["PBL-学生任务"])
except ImportError as e:
    print(f"警告: 无法导入student_tasks: {e}")

try:
    from app.api.pbl.student_club import router as student_club_router
    pbl_router.include_router(student_club_router, prefix="/student/club", tags=["PBL-学生社团"])
except ImportError as e:
    print(f"警告: 无法导入student_club: {e}")

# 教师端路由
try:
    from app.api.pbl.teacher_auth import router as teacher_auth_router
    pbl_router.include_router(teacher_auth_router, prefix="/teacher/auth", tags=["PBL-教师认证"])
except ImportError as e:
    print(f"警告: 无法导入teacher_auth: {e}")

try:
    from app.api.pbl.teacher_courses import router as teacher_courses_router
    pbl_router.include_router(teacher_courses_router, prefix="/teacher/courses", tags=["PBL-教师课程"])
except ImportError as e:
    print(f"警告: 无法导入teacher_courses: {e}")

# 管理员路由
try:
    from app.api.pbl.admin_auth import router as admin_auth_router
    pbl_router.include_router(admin_auth_router, prefix="/admin/auth", tags=["PBL-管理认证"])
except ImportError as e:
    print(f"警告: 无法导入admin_auth: {e}")

try:
    from app.api.pbl.admin_users import router as admin_users_router
    pbl_router.include_router(admin_users_router, prefix="/admin/users", tags=["PBL-用户管理"])
except ImportError as e:
    print(f"警告: 无法导入admin_users: {e}")

try:
    from app.api.pbl.admin_courses import router as admin_courses_router
    pbl_router.include_router(admin_courses_router, prefix="/admin/courses", tags=["PBL-课程管理"])
except ImportError as e:
    print(f"警告: 无法导入admin_courses: {e}")

try:
    from app.api.pbl.admin_tasks import router as admin_tasks_router
    pbl_router.include_router(admin_tasks_router, prefix="/admin/tasks", tags=["PBL-任务管理"])
except ImportError as e:
    print(f"警告: 无法导入admin_tasks: {e}")

try:
    from app.api.pbl.admin_units import router as admin_units_router
    pbl_router.include_router(admin_units_router, prefix="/admin/units", tags=["PBL-单元管理"])
except ImportError as e:
    print(f"警告: 无法导入admin_units: {e}")

try:
    from app.api.pbl.admin_resources import router as admin_resources_router
    pbl_router.include_router(admin_resources_router, prefix="/admin/resources", tags=["PBL-资源管理"])
except ImportError as e:
    print(f"警告: 无法导入admin_resources: {e}")

try:
    from app.api.pbl.admin_outputs import router as admin_outputs_router
    pbl_router.include_router(admin_outputs_router, prefix="/admin/outputs", tags=["PBL-成果管理"])
except ImportError as e:
    print(f"警告: 无法导入admin_outputs: {e}")

# 其他PBL功能路由
try:
    from app.api.pbl.schools import router as schools_router
    pbl_router.include_router(schools_router, prefix="/schools", tags=["PBL-学校管理"])
except ImportError as e:
    print(f"警告: 无法导入schools: {e}")

try:
    from app.api.pbl.classes_groups import router as classes_groups_router
    pbl_router.include_router(classes_groups_router, prefix="/classes-groups", tags=["PBL-班级分组"])
except ImportError as e:
    print(f"警告: 无法导入classes_groups: {e}")

try:
    from app.api.pbl.projects import router as projects_router
    pbl_router.include_router(projects_router, prefix="/projects", tags=["PBL-项目管理"])
except ImportError as e:
    print(f"警告: 无法导入projects: {e}")

try:
    from app.api.pbl.assessments import router as assessments_router
    pbl_router.include_router(assessments_router, prefix="/assessments", tags=["PBL-评估管理"])
except ImportError as e:
    print(f"警告: 无法导入assessments: {e}")

try:
    from app.api.pbl.portfolios import router as portfolios_router
    pbl_router.include_router(portfolios_router, prefix="/portfolios", tags=["PBL-作品集"])
except ImportError as e:
    print(f"警告: 无法导入portfolios: {e}")

try:
    from app.api.pbl.learning_progress import router as learning_progress_router
    pbl_router.include_router(learning_progress_router, prefix="/learning-progress", tags=["PBL-学习进度"])
except ImportError as e:
    print(f"警告: 无法导入learning_progress: {e}")

try:
    from app.api.pbl.social_activities import router as social_activities_router
    pbl_router.include_router(social_activities_router, prefix="/social-activities", tags=["PBL-社会活动"])
except ImportError as e:
    print(f"警告: 无法导入social_activities: {e}")

try:
    from app.api.pbl.ethics import router as ethics_router
    pbl_router.include_router(ethics_router, prefix="/ethics", tags=["PBL-伦理教育"])
except ImportError as e:
    print(f"警告: 无法导入ethics: {e}")

try:
    from app.api.pbl.experts import router as experts_router
    pbl_router.include_router(experts_router, prefix="/experts", tags=["PBL-专家资源"])
except ImportError as e:
    print(f"警告: 无法导入experts: {e}")

try:
    from app.api.pbl.datasets import router as datasets_router
    pbl_router.include_router(datasets_router, prefix="/datasets", tags=["PBL-数据集"])
except ImportError as e:
    print(f"警告: 无法导入datasets: {e}")

try:
    from app.api.pbl.video_play import router as video_play_router
    pbl_router.include_router(video_play_router, prefix="/video-play", tags=["PBL-视频播放"])
except ImportError as e:
    print(f"警告: 无法导入video_play: {e}")

try:
    from app.api.pbl.video_progress import router as video_progress_router
    pbl_router.include_router(video_progress_router, prefix="/video-progress", tags=["PBL-视频进度"])
except ImportError as e:
    print(f"警告: 无法导入video_progress: {e}")

try:
    from app.api.pbl.assessment_templates import router as assessment_templates_router
    pbl_router.include_router(assessment_templates_router, prefix="/assessment-templates", tags=["PBL-评估模板"])
except ImportError as e:
    print(f"警告: 无法导入assessment_templates: {e}")

try:
    from app.api.pbl.available_templates import router as available_templates_router
    pbl_router.include_router(available_templates_router, prefix="/available-templates", tags=["PBL-可用模板"])
except ImportError as e:
    print(f"警告: 无法导入available_templates: {e}")

try:
    from app.api.pbl.template_permissions import router as template_permissions_router
    pbl_router.include_router(template_permissions_router, prefix="/template-permissions", tags=["PBL-模板权限"])
except ImportError as e:
    print(f"警告: 无法导入template_permissions: {e}")

try:
    from app.api.pbl.school_courses import router as school_courses_router
    pbl_router.include_router(school_courses_router, prefix="/school-courses", tags=["PBL-校本课程"])
except ImportError as e:
    print(f"警告: 无法导入school_courses: {e}")

try:
    from app.api.pbl.club_classes import router as club_classes_router
    pbl_router.include_router(club_classes_router, prefix="/club-classes", tags=["PBL-社团课程"])
except ImportError as e:
    print(f"警告: 无法导入club_classes: {e}")

try:
    from app.api.pbl.class_analytics import router as class_analytics_router
    pbl_router.include_router(class_analytics_router, prefix="/class-analytics", tags=["PBL-班级分析"])
except ImportError as e:
    print(f"警告: 无法导入class_analytics: {e}")

try:
    from app.api.pbl.channel_auth import router as channel_auth_router
    pbl_router.include_router(channel_auth_router, prefix="/channel/auth", tags=["PBL-渠道认证"])
except ImportError as e:
    print(f"警告: 无法导入channel_auth: {e}")

try:
    from app.api.pbl.channel_schools import router as channel_schools_router
    pbl_router.include_router(channel_schools_router, prefix="/channel/schools", tags=["PBL-渠道学校"])
except ImportError as e:
    print(f"警告: 无法导入channel_schools: {e}")

print(f"✓ PBL路由注册完成，已注册 {len(pbl_router.routes)} 个路由")
EOF

echo -e "${GREEN}✓ PBL路由注册文件创建完成${NC}"
echo ""

# 生成整合报告
echo -e "${YELLOW}生成整合报告...${NC}"

REPORT_FILE="$SCRIPT_DIR/PBL_BACKEND_INTEGRATION_REPORT.md"

cat > "$REPORT_FILE" << EOF
# PBL后端整合报告

## 整合时间
$(date '+%Y-%m-%d %H:%M:%S')

## 整合内容

### 1. API文件
复制了以下API文件到 \`backend/app/api/pbl/\`:
EOF

if [ -d "$BACKEND_DIR/app/api/pbl" ]; then
    ls -1 "$BACKEND_DIR/app/api/pbl"/*.py 2>/dev/null | while read file; do
        echo "- $(basename "$file")" >> "$REPORT_FILE"
    done
fi

cat >> "$REPORT_FILE" << EOF

总计: $(ls -1 "$BACKEND_DIR/app/api/pbl"/*.py 2>/dev/null | wc -l) 个API文件

### 2. Models文件
整合了以下Model文件:
EOF

# 列出PBL相关的models（需要手动确认）
echo "- (请手动检查 backend/app/models/ 目录)" >> "$REPORT_FILE"

cat >> "$REPORT_FILE" << EOF

### 3. Schemas文件
整合了以下Schema文件:
EOF

# 列出PBL相关的schemas
echo "- (请手动检查 backend/app/schemas/ 目录)" >> "$REPORT_FILE"

cat >> "$REPORT_FILE" << EOF

### 4. Services文件
复制了Services文件到 \`backend/app/services/pbl/\`

### 5. 路由注册
创建了 \`backend/app/api/pbl/__init__.py\` 文件，注册了所有PBL路由

## 下一步操作

### 1. 更新主路由文件（重要！）

编辑 \`backend/app/api/__init__.py\`，添加PBL路由：

\`\`\`python
from app.api.pbl import pbl_router

# 在api_router中添加
api_router.include_router(pbl_router, prefix="/pbl", tags=["PBL系统"])
\`\`\`

### 2. 检查依赖

检查 \`backend/requirements.txt\` 是否包含PBL所需的所有依赖包。

### 3. 更新数据库

确保数据库包含所有PBL相关的表。参考：
- \`SQL/pbl_schema.sql\`
- \`SQL/update/27_add_pbl_group_device_authorizations.sql\`

### 4. 测试API

启动后端服务：
\`\`\`bash
cd backend
python main.py
\`\`\`

访问API文档：http://localhost:8000/docs

检查PBL相关的API端点是否正常显示。

### 5. 修复导入错误

如果启动时有导入错误，需要：
1. 检查缺失的依赖包
2. 检查导入路径是否正确
3. 检查models和schemas是否完整

## 备份信息

原backend已备份到：
\`$BACKUP_DIR\`

如需恢复，运行：
\`\`\`bash
rm -rf backend
cp -r $BACKUP_DIR/backend .
\`\`\`

## 常见问题

### Q: 启动时报导入错误
A: 检查 \`backend/app/api/pbl/__init__.py\` 中的导入，注释掉有问题的路由

### Q: API端点不显示
A: 确保在 \`backend/app/api/__init__.py\` 中注册了pbl_router

### Q: 数据库连接错误
A: 检查PBL相关的表是否存在，参考SQL文件创建

---

**整合完成！** 🎉
EOF

echo -e "${GREEN}✓ 整合报告已生成: $REPORT_FILE${NC}"
echo ""

# 完成
echo -e "${BLUE}============================================================${NC}"
echo -e "${GREEN}✅ PBL后端整合完成！${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""
echo -e "${YELLOW}📊 整合统计：${NC}"
echo -e "  - API文件: $(ls -1 "$BACKEND_DIR/app/api/pbl"/*.py 2>/dev/null | wc -l | tr -d ' ') 个"
echo -e "  - 备份目录: $BACKUP_DIR"
echo -e "  - 整合报告: $REPORT_FILE"
echo ""
echo -e "${YELLOW}📝 下一步操作：${NC}"
echo -e "  1. 查看整合报告: cat $REPORT_FILE"
echo -e "  2. 更新主路由文件: backend/app/api/__init__.py"
echo -e "  3. 测试后端: cd backend && python main.py"
echo -e "  4. 访问API文档: http://localhost:8000/docs"
echo ""
echo -e "${GREEN}祝整合顺利！🚀${NC}"
