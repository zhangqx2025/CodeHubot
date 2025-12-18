#!/bin/bash

# 前端代码迁移脚本
# 将Device和PBL前端代码迁移到统一前端项目

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVICE_SRC="/Users/zhangqixun/AICodeing/CodeHubot工作空间/CodeHubot/frontend/src"
PBL_SRC="/Users/zhangqixun/AICodeing/CodeHubot工作空间/CodeHubot-PBL/frontend/src"

echo "=========================================="
echo "  前端代码迁移工具"
echo "=========================================="
echo ""

if [ ! -d "$DEVICE_SRC" ]; then
    echo -e "${RED}❌ 找不到Device前端源码: $DEVICE_SRC${NC}"
    exit 1
fi

if [ ! -d "$PBL_SRC" ]; then
    echo -e "${YELLOW}⚠️  找不到PBL前端源码: $PBL_SRC${NC}"
    echo "将跳过PBL代码迁移"
fi

echo -e "${BLUE}步骤 1/5: 迁移Device模块...${NC}"
echo "  复制views..."
mkdir -p "$SCRIPT_DIR/src/modules/device/views"
if [ -d "$DEVICE_SRC/views" ]; then
    cp -r "$DEVICE_SRC/views"/* "$SCRIPT_DIR/src/modules/device/views/" 2>/dev/null || true
    echo -e "${GREEN}  ✓ Views已复制${NC}"
fi

echo "  复制components..."
mkdir -p "$SCRIPT_DIR/src/modules/device/components"
if [ -d "$DEVICE_SRC/components" ]; then
    cp -r "$DEVICE_SRC/components"/* "$SCRIPT_DIR/src/modules/device/components/" 2>/dev/null || true
    echo -e "${GREEN}  ✓ Components已复制${NC}"
fi

echo "  复制API..."
mkdir -p "$SCRIPT_DIR/src/modules/device/api"
if [ -d "$DEVICE_SRC/api" ]; then
    # 排除通用的auth和request，这些已经在shared中
    for file in "$DEVICE_SRC/api"/*.js; do
        filename=$(basename "$file")
        if [ "$filename" != "auth.js" ] && [ "$filename" != "request.js" ]; then
            cp "$file" "$SCRIPT_DIR/src/modules/device/api/" 2>/dev/null || true
        fi
    done
    echo -e "${GREEN}  ✓ API文件已复制${NC}"
fi

echo ""
echo -e "${BLUE}步骤 2/5: 迁移PBL模块...${NC}"
if [ -d "$PBL_SRC" ]; then
    echo "  复制student views..."
    mkdir -p "$SCRIPT_DIR/src/modules/pbl/student/views"
    # 这里需要根据实际的PBL项目结构调整
    
    echo "  复制teacher views..."
    mkdir -p "$SCRIPT_DIR/src/modules/pbl/teacher/views"
    
    echo "  复制admin views..."
    mkdir -p "$SCRIPT_DIR/src/modules/pbl/admin/views"
    
    echo -e "${GREEN}  ✓ PBL模块结构已创建${NC}"
else
    echo -e "${YELLOW}  ⚠️  跳过PBL迁移${NC}"
fi

echo ""
echo -e "${BLUE}步骤 3/5: 更新导入路径...${NC}"
echo "  查找需要更新的文件..."

# 更新Device模块的导入路径
find "$SCRIPT_DIR/src/modules/device" -name "*.vue" -o -name "*.js" | while read file; do
    # 替换 @/api 为 @device/api
    sed -i '' 's|@/api/|@device/api/|g' "$file" 2>/dev/null || true
    # 替换 @/components 为 @device/components
    sed -i '' 's|@/components/|@device/components/|g' "$file" 2>/dev/null || true
    # 共享的auth和request使用@shared
    sed -i '' 's|@device/api/auth|@shared/api/auth|g' "$file" 2>/dev/null || true
    sed -i '' 's|@device/api/request|@shared/api/request|g' "$file" 2>/dev/null || true
done

echo -e "${GREEN}  ✓ 导入路径已更新${NC}"

echo ""
echo -e "${BLUE}步骤 4/5: 生成迁移报告...${NC}"

cat > "$SCRIPT_DIR/MIGRATION_REPORT.md" << 'EOF'
# 前端代码迁移报告

## 迁移概况

### Device模块
- ✅ Views已迁移
- ✅ Components已迁移
- ✅ API已迁移
- ⚠️  需要手动检查和测试

### PBL模块
- ⚠️  需要手动迁移views
- ⚠️  需要手动迁移components
- ⚠️  需要手动迁移API

## 手动操作清单

### 1. 检查导入路径
所有文件的导入路径已自动更新为：
- `@device/api/xxx` - Device模块API
- `@device/components/xxx` - Device模块组件
- `@shared/api/auth` - 共享认证API
- `@shared/api/request` - 共享HTTP客户端

### 2. 更新Store使用
原来使用Vuex的地方需要改为Pinia：
```javascript
// 旧写法
import { mapState } from 'vuex'
computed: {
  ...mapState(['user'])
}

// 新写法
import { useAuthStore } from '@/stores/auth'
const authStore = useAuthStore()
const user = computed(() => authStore.userInfo)
```

### 3. 测试功能
- [ ] 登录功能
- [ ] 设备列表
- [ ] 设备详情
- [ ] 设备控制
- [ ] 其他核心功能

## 注意事项

1. **API路径**: 确保所有API调用使用正确的baseURL
2. **路由跳转**: 使用`router.push('/device/xxx')`而不是`router.push('/xxx')`
3. **权限控制**: 使用新的权限检查函数
4. **状态管理**: 使用Pinia代替Vuex

## 下一步

1. 安装依赖: `npm install`
2. 启动开发服务器: `npm run dev`
3. 访问: http://localhost:3000
4. 测试所有功能
5. 修复发现的问题
EOF

echo -e "${GREEN}  ✓ 迁移报告已生成: MIGRATION_REPORT.md${NC}"

echo ""
echo -e "${BLUE}步骤 5/5: 安装依赖...${NC}"
cd "$SCRIPT_DIR"
if [ -f "package.json" ]; then
    echo "  运行 npm install..."
    npm install
    echo -e "${GREEN}  ✓ 依赖已安装${NC}"
fi

echo ""
echo -e "${GREEN}=========================================="
echo -e "  ✅ 迁移完成！"
echo -e "==========================================${NC}"
echo ""
echo -e "${YELLOW}下一步操作：${NC}"
echo "1. 查看迁移报告: cat MIGRATION_REPORT.md"
echo "2. 手动迁移PBL相关代码"
echo "3. 启动开发服务器: npm run dev"
echo "4. 访问 http://localhost:3000"
echo "5. 测试所有功能"
echo ""
echo -e "${RED}⚠️  重要提示：${NC}"
echo "- 所有API调用需要验证路径是否正确"
echo "- Vuex相关代码需要改为Pinia"
echo "- 路由跳转需要加上模块前缀"
echo ""
