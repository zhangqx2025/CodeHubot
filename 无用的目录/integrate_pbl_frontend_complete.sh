#!/bin/bash

# ============================================================
# PBL前端完整整合脚本
# 功能：自动整合所有PBL前端代码到frontend
# ============================================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 项目目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PBL_FRONTEND_DIR="$SCRIPT_DIR/CodeHubot-PBL/frontend"
DEVICE_FRONTEND_DIR="$SCRIPT_DIR/frontend"
UNIFIED_FRONTEND_DIR="$SCRIPT_DIR/frontend"

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}   PBL前端完整整合脚本${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

# 检查目录
if [ ! -d "$PBL_FRONTEND_DIR" ]; then
    echo -e "${RED}错误: 找不到PBL前端目录: $PBL_FRONTEND_DIR${NC}"
    exit 1
fi

if [ ! -d "$UNIFIED_FRONTEND_DIR" ]; then
    echo -e "${RED}错误: 找不到统一前端目录: $UNIFIED_FRONTEND_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 目录检查通过${NC}"
echo ""

# ============================================================
# 第一部分：迁移Device前端
# ============================================================

echo -e "${YELLOW}[1/6] 迁移Device前端代码...${NC}"

if [ -d "$DEVICE_FRONTEND_DIR/src/views" ]; then
    echo "  复制Device views..."
    mkdir -p "$UNIFIED_FRONTEND_DIR/src/modules/device/views"
    cp -r "$DEVICE_FRONTEND_DIR/src/views/"*.vue "$UNIFIED_FRONTEND_DIR/src/modules/device/views/" 2>/dev/null || echo "  部分文件可能不存在"
fi

if [ -d "$DEVICE_FRONTEND_DIR/src/components" ]; then
    echo "  复制Device components..."
    mkdir -p "$UNIFIED_FRONTEND_DIR/src/modules/device/components"
    cp -r "$DEVICE_FRONTEND_DIR/src/components/"*.vue "$UNIFIED_FRONTEND_DIR/src/modules/device/components/" 2>/dev/null || echo "  部分文件可能不存在"
fi

if [ -d "$DEVICE_FRONTEND_DIR/src/api" ]; then
    echo "  复制Device API..."
    mkdir -p "$UNIFIED_FRONTEND_DIR/src/modules/device/api"
    cp -r "$DEVICE_FRONTEND_DIR/src/api/"*.js "$UNIFIED_FRONTEND_DIR/src/modules/device/api/" 2>/dev/null || echo "  部分文件可能不存在"
fi

if [ -d "$DEVICE_FRONTEND_DIR/src/utils" ]; then
    echo "  复制Device utils..."
    mkdir -p "$UNIFIED_FRONTEND_DIR/src/modules/device/utils"
    cp -r "$DEVICE_FRONTEND_DIR/src/utils/"*.js "$UNIFIED_FRONTEND_DIR/src/modules/device/utils/" 2>/dev/null || echo "  部分文件可能不存在"
fi

echo -e "${GREEN}✓ Device前端迁移完成${NC}"
echo ""

# ============================================================
# 第二部分：迁移PBL前端
# ============================================================

echo -e "${YELLOW}[2/6] 迁移PBL前端代码...${NC}"

# 创建PBL目录结构
mkdir -p "$UNIFIED_FRONTEND_DIR/src/modules/pbl/student/views"
mkdir -p "$UNIFIED_FRONTEND_DIR/src/modules/pbl/student/components"
mkdir -p "$UNIFIED_FRONTEND_DIR/src/modules/pbl/student/api"
mkdir -p "$UNIFIED_FRONTEND_DIR/src/modules/pbl/teacher/views"
mkdir -p "$UNIFIED_FRONTEND_DIR/src/modules/pbl/teacher/components"
mkdir -p "$UNIFIED_FRONTEND_DIR/src/modules/pbl/teacher/api"
mkdir -p "$UNIFIED_FRONTEND_DIR/src/modules/pbl/admin/views"
mkdir -p "$UNIFIED_FRONTEND_DIR/src/modules/pbl/admin/components"
mkdir -p "$UNIFIED_FRONTEND_DIR/src/modules/pbl/admin/api"

# 复制PBL学生端
if [ -d "$PBL_FRONTEND_DIR/src/views" ]; then
    echo "  分析PBL views文件..."
    
    # 学生相关页面
    for file in "$PBL_FRONTEND_DIR/src/views"/*; do
        filename=$(basename "$file")
        case "$filename" in
            Student*.vue|MyCourses.vue|MyTasks.vue|MyProjects.vue|MyPortfolio.vue)
                echo "    → 学生端: $filename"
                cp "$file" "$UNIFIED_FRONTEND_DIR/src/modules/pbl/student/views/"
                ;;
            Teacher*.vue|TeachingDashboard.vue|CourseManage.vue|TaskManage.vue)
                echo "    → 教师端: $filename"
                cp "$file" "$UNIFIED_FRONTEND_DIR/src/modules/pbl/teacher/views/"
                ;;
            Admin*.vue|UserManage.vue|SchoolManage.vue|SystemSettings.vue)
                echo "    → 管理端: $filename"
                cp "$file" "$UNIFIED_FRONTEND_DIR/src/modules/pbl/admin/views/"
                ;;
            *)
                echo "    ⚠ 未分类: $filename (需手动分类)"
                ;;
        esac
    done
fi

# 复制PBL components
if [ -d "$PBL_FRONTEND_DIR/src/components" ]; then
    echo "  复制PBL共享组件..."
    cp -r "$PBL_FRONTEND_DIR/src/components/"*.vue "$UNIFIED_FRONTEND_DIR/src/modules/pbl/student/components/" 2>/dev/null || true
fi

# 复制PBL API
if [ -d "$PBL_FRONTEND_DIR/src/api" ]; then
    echo "  复制PBL API..."
    cp -r "$PBL_FRONTEND_DIR/src/api/"*.js "$UNIFIED_FRONTEND_DIR/src/modules/pbl/student/api/" 2>/dev/null || true
fi

echo -e "${GREEN}✓ PBL前端迁移完成${NC}"
echo ""

# ============================================================
# 第三部分：更新导入路径
# ============================================================

echo -e "${YELLOW}[3/6] 更新导入路径...${NC}"

# 更新Device模块的导入路径
if [ -d "$UNIFIED_FRONTEND_DIR/src/modules/device" ]; then
    echo "  更新Device导入路径..."
    find "$UNIFIED_FRONTEND_DIR/src/modules/device" -type f \( -name "*.vue" -o -name "*.js" \) -exec sed -i '' \
        -e "s|from '@/api|from '@device/api|g" \
        -e "s|from '@/components|from '@device/components|g" \
        -e "s|from '@/utils|from '@device/utils|g" \
        -e "s|import '@/api|import '@device/api|g" \
        -e "s|import '@/components|import '@device/components|g" \
        -e "s|import '@/utils|import '@device/utils|g" \
        {} +
fi

# 更新PBL模块的导入路径
if [ -d "$UNIFIED_FRONTEND_DIR/src/modules/pbl" ]; then
    echo "  更新PBL导入路径..."
    
    # 学生端
    find "$UNIFIED_FRONTEND_DIR/src/modules/pbl/student" -type f \( -name "*.vue" -o -name "*.js" \) -exec sed -i '' \
        -e "s|from '@/api|from '@pbl/student/api|g" \
        -e "s|from '@/components|from '@pbl/student/components|g" \
        -e "s|import '@/api|import '@pbl/student/api|g" \
        -e "s|import '@/components|import '@pbl/student/components|g" \
        {} + 2>/dev/null || true
    
    # 教师端
    find "$UNIFIED_FRONTEND_DIR/src/modules/pbl/teacher" -type f \( -name "*.vue" -o -name "*.js" \) -exec sed -i '' \
        -e "s|from '@/api|from '@pbl/teacher/api|g" \
        -e "s|from '@/components|from '@pbl/teacher/components|g" \
        {} + 2>/dev/null || true
    
    # 管理端
    find "$UNIFIED_FRONTEND_DIR/src/modules/pbl/admin" -type f \( -name "*.vue" -o -name "*.js" \) -exec sed -i '' \
        -e "s|from '@/api|from '@pbl/admin/api|g" \
        -e "s|from '@/components|from '@pbl/admin/components|g" \
        {} + 2>/dev/null || true
fi

echo -e "${GREEN}✓ 导入路径更新完成${NC}"
echo ""

# ============================================================
# 第四部分：更新路由配置
# ============================================================

echo -e "${YELLOW}[4/6] 更新路由配置...${NC}"

cat > "$UNIFIED_FRONTEND_DIR/src/router/device.js" << 'EOF'
/**
 * Device系统路由配置
 */
export default [
  {
    path: '/device',
    component: () => import('@/layouts/DeviceLayout.vue'),
    meta: { requiresAuth: true },
    redirect: '/device/dashboard',
    children: [
      {
        path: 'dashboard',
        name: 'DeviceDashboard',
        component: () => import('@device/views/Dashboard.vue'),
        meta: { title: '仪表盘' }
      },
      {
        path: 'devices',
        name: 'DeviceList',
        component: () => import('@device/views/DeviceList.vue'),
        meta: { title: '设备列表' }
      },
      {
        path: 'devices/:id',
        name: 'DeviceDetail',
        component: () => import('@device/views/DeviceDetail.vue'),
        meta: { title: '设备详情' }
      },
      {
        path: 'products',
        name: 'ProductList',
        component: () => import('@device/views/ProductList.vue'),
        meta: { title: '产品管理' }
      },
      {
        path: 'agents',
        name: 'AgentList',
        component: () => import('@device/views/AgentList.vue'),
        meta: { title: '智能体管理' }
      },
      {
        path: 'knowledge-bases',
        name: 'KnowledgeBaseList',
        component: () => import('@device/views/KnowledgeBaseList.vue'),
        meta: { title: '知识库管理' }
      }
    ]
  }
]
EOF

cat > "$UNIFIED_FRONTEND_DIR/src/router/pbl.js" << 'EOF'
/**
 * PBL系统路由配置
 */

// PBL学生端路由
const studentRoutes = {
  path: '/pbl/student',
  component: () => import('@/layouts/PBLStudentLayout.vue'),
  meta: { requiresAuth: true, roles: ['pbl_student'] },
  redirect: '/pbl/student/courses',
  children: [
    {
      path: 'courses',
      name: 'StudentCourses',
      component: () => import('@pbl/student/views/StudentCourses.vue'),
      meta: { title: '我的课程' }
    },
    {
      path: 'courses/:id',
      name: 'StudentCourseDetail',
      component: () => import('@pbl/student/views/StudentCourseDetail.vue'),
      meta: { title: '课程详情' }
    },
    {
      path: 'tasks',
      name: 'StudentTasks',
      component: () => import('@pbl/student/views/StudentTasks.vue'),
      meta: { title: '我的任务' }
    },
    {
      path: 'projects',
      name: 'StudentProjects',
      component: () => import('@pbl/student/views/StudentProjects.vue'),
      meta: { title: '我的项目' }
    },
    {
      path: 'portfolio',
      name: 'StudentPortfolio',
      component: () => import('@pbl/student/views/StudentPortfolio.vue'),
      meta: { title: '我的作品集' }
    }
  ]
}

// PBL教师端路由
const teacherRoutes = {
  path: '/pbl/teacher',
  component: () => import('@/layouts/PBLTeacherLayout.vue'),
  meta: { requiresAuth: true, roles: ['pbl_teacher'] },
  redirect: '/pbl/teacher/dashboard',
  children: [
    {
      path: 'dashboard',
      name: 'TeacherDashboard',
      component: () => import('@pbl/teacher/views/TeacherDashboard.vue'),
      meta: { title: '教学仪表盘' }
    },
    {
      path: 'courses',
      name: 'TeacherCourses',
      component: () => import('@pbl/teacher/views/TeacherCourses.vue'),
      meta: { title: '课程管理' }
    },
    {
      path: 'tasks',
      name: 'TeacherTasks',
      component: () => import('@pbl/teacher/views/TeacherTasks.vue'),
      meta: { title: '任务管理' }
    },
    {
      path: 'students',
      name: 'TeacherStudents',
      component: () => import('@pbl/teacher/views/TeacherStudents.vue'),
      meta: { title: '学生管理' }
    }
  ]
}

// PBL管理端路由
const adminRoutes = {
  path: '/pbl/admin',
  component: () => import('@/layouts/PBLAdminLayout.vue'),
  meta: { requiresAuth: true, roles: ['pbl_admin'] },
  redirect: '/pbl/admin/dashboard',
  children: [
    {
      path: 'dashboard',
      name: 'AdminDashboard',
      component: () => import('@pbl/admin/views/AdminDashboard.vue'),
      meta: { title: '管理仪表盘' }
    },
    {
      path: 'users',
      name: 'AdminUsers',
      component: () => import('@pbl/admin/views/AdminUsers.vue'),
      meta: { title: '用户管理' }
    },
    {
      path: 'schools',
      name: 'AdminSchools',
      component: () => import('@pbl/admin/views/AdminSchools.vue'),
      meta: { title: '学校管理' }
    },
    {
      path: 'courses',
      name: 'AdminCourses',
      component: () => import('@pbl/admin/views/AdminCourses.vue'),
      meta: { title: '课程管理' }
    }
  ]
}

export default [studentRoutes, teacherRoutes, adminRoutes]
EOF

echo -e "${GREEN}✓ 路由配置更新完成${NC}"
echo ""

# ============================================================
# 第五部分：复制静态资源
# ============================================================

echo -e "${YELLOW}[5/6] 复制静态资源...${NC}"

# 复制Device静态资源
if [ -d "$DEVICE_FRONTEND_DIR/src/assets" ]; then
    echo "  复制Device assets..."
    mkdir -p "$UNIFIED_FRONTEND_DIR/src/assets/device"
    cp -r "$DEVICE_FRONTEND_DIR/src/assets/"* "$UNIFIED_FRONTEND_DIR/src/assets/device/" 2>/dev/null || true
fi

# 复制PBL静态资源
if [ -d "$PBL_FRONTEND_DIR/src/assets" ]; then
    echo "  复制PBL assets..."
    mkdir -p "$UNIFIED_FRONTEND_DIR/src/assets/pbl"
    cp -r "$PBL_FRONTEND_DIR/src/assets/"* "$UNIFIED_FRONTEND_DIR/src/assets/pbl/" 2>/dev/null || true
fi

echo -e "${GREEN}✓ 静态资源复制完成${NC}"
echo ""

# ============================================================
# 第六部分：生成迁移报告
# ============================================================

echo -e "${YELLOW}[6/6] 生成迁移报告...${NC}"

REPORT_FILE="$UNIFIED_FRONTEND_DIR/MIGRATION_REPORT.md"

cat > "$REPORT_FILE" << EOF
# 前端代码迁移报告

## 迁移时间
$(date '+%Y-%m-%d %H:%M:%S')

## 迁移内容

### 1. Device模块

#### Views
\`\`\`
$(find "$UNIFIED_FRONTEND_DIR/src/modules/device/views" -name "*.vue" 2>/dev/null | wc -l | tr -d ' ') 个文件
\`\`\`

#### Components
\`\`\`
$(find "$UNIFIED_FRONTEND_DIR/src/modules/device/components" -name "*.vue" 2>/dev/null | wc -l | tr -d ' ') 个文件
\`\`\`

#### API
\`\`\`
$(find "$UNIFIED_FRONTEND_DIR/src/modules/device/api" -name "*.js" 2>/dev/null | wc -l | tr -d ' ') 个文件
\`\`\`

### 2. PBL学生端

#### Views
\`\`\`
$(find "$UNIFIED_FRONTEND_DIR/src/modules/pbl/student/views" -name "*.vue" 2>/dev/null | wc -l | tr -d ' ') 个文件
\`\`\`

#### Components
\`\`\`
$(find "$UNIFIED_FRONTEND_DIR/src/modules/pbl/student/components" -name "*.vue" 2>/dev/null | wc -l | tr -d ' ') 个文件
\`\`\`

### 3. PBL教师端

#### Views
\`\`\`
$(find "$UNIFIED_FRONTEND_DIR/src/modules/pbl/teacher/views" -name "*.vue" 2>/dev/null | wc -l | tr -d ' ') 个文件
\`\`\`

### 4. PBL管理端

#### Views
\`\`\`
$(find "$UNIFIED_FRONTEND_DIR/src/modules/pbl/admin/views" -name "*.vue" 2>/dev/null | wc -l | tr -d ' ') 个文件
\`\`\`

## 下一步操作

### 1. 安装依赖

\`\`\`bash
cd frontend
npm install
\`\`\`

### 2. 检查并修复导入错误

由于自动化脚本可能无法完美识别所有导入路径，请手动检查：

\`\`\`bash
# 查找可能的导入错误
grep -r "from '@/" src/modules/
\`\`\`

### 3. 创建缺失的页面

某些页面可能在原项目中不存在，需要创建：

- DeviceDashboard.vue
- StudentCourses.vue
- TeacherDashboard.vue
- AdminDashboard.vue

### 4. 启动开发服务器

\`\`\`bash
npm run dev
\`\`\`

访问：http://localhost:3000

### 5. 测试功能

- [ ] 登录功能
- [ ] 门户页面
- [ ] Device系统各页面
- [ ] PBL学生端各页面
- [ ] PBL教师端各页面
- [ ] PBL管理端各页面

## 已知问题

### 1. 页面文件缺失

某些页面可能在原项目中不存在，需要手动创建或使用占位组件。

### 2. API路径可能需要调整

前端API调用的路径需要与后端API路径匹配，可能需要手动调整。

### 3. 组件导入路径

某些复杂的组件导入可能需要手动调整。

## 迁移统计

- Device Views: $(find "$UNIFIED_FRONTEND_DIR/src/modules/device/views" -name "*.vue" 2>/dev/null | wc -l | tr -d ' ')
- Device Components: $(find "$UNIFIED_FRONTEND_DIR/src/modules/device/components" -name "*.vue" 2>/dev/null | wc -l | tr -d ' ')
- PBL Views: $(find "$UNIFIED_FRONTEND_DIR/src/modules/pbl" -name "*.vue" 2>/dev/null | wc -l | tr -d ' ')
- PBL Components: $(find "$UNIFIED_FRONTEND_DIR/src/modules/pbl" -type d -name "components" -exec find {} -name "*.vue" \; 2>/dev/null | wc -l | tr -d ' ')

---

**迁移完成！** 🎉
EOF

echo -e "${GREEN}✓ 迁移报告已生成: $REPORT_FILE${NC}"
echo ""

# 完成
echo -e "${BLUE}============================================================${NC}"
echo -e "${GREEN}✅ 前端代码迁移完成！${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""
echo -e "${YELLOW}📊 迁移统计：${NC}"
echo -e "  - Device Views: $(find "$UNIFIED_FRONTEND_DIR/src/modules/device/views" -name "*.vue" 2>/dev/null | wc -l | tr -d ' ')"
echo -e "  - Device Components: $(find "$UNIFIED_FRONTEND_DIR/src/modules/device/components" -name "*.vue" 2>/dev/null | wc -l | tr -d ' ')"
echo -e "  - PBL Views: $(find "$UNIFIED_FRONTEND_DIR/src/modules/pbl" -name "*.vue" 2>/dev/null | wc -l | tr -d ' ')"
echo -e "  - 迁移报告: $REPORT_FILE"
echo ""
echo -e "${YELLOW}📝 下一步操作：${NC}"
echo -e "  1. 查看迁移报告: cat $REPORT_FILE"
echo -e "  2. 安装依赖: cd frontend && npm install"
echo -e "  3. 启动开发服务器: npm run dev"
echo -e "  4. 访问: http://localhost:3000"
echo ""
echo -e "${GREEN}祝迁移顺利！🚀${NC}"
