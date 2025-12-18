<template>
  <el-card class="quick-navigation-card">
    <template #header>
      <div class="card-header">
        <el-icon><Link /></el-icon>
        <span>快速导航</span>
      </div>
    </template>

    <div class="navigation-grid">
      <!-- 实时数据 -->
      <div class="nav-item" @click="navigateToRealtime">
        <div class="nav-icon realtime">
          <el-icon><TrendCharts /></el-icon>
        </div>
        <div class="nav-content">
          <h3>实时数据</h3>
          <p>查看设备传感器实时数据和历史趋势</p>
          <div class="nav-features">
            <el-tag size="small" type="primary">实时监控</el-tag>
            <el-tag size="small" type="info">数据图表</el-tag>
            <el-tag size="small" type="success">历史记录</el-tag>
          </div>
        </div>
        <el-icon class="nav-arrow"><ArrowRight /></el-icon>
      </div>

      <!-- 远程控制 -->
      <div class="nav-item" @click="navigateToControl">
        <div class="nav-icon control">
          <el-icon><Setting /></el-icon>
        </div>
        <div class="nav-content">
          <h3>远程控制</h3>
          <p>远程控制设备各种功能和参数设置</p>
          <div class="nav-features">
            <el-tag size="small" type="warning">设备控制</el-tag>
            <el-tag size="small" type="danger">参数调节</el-tag>
            <el-tag size="small" type="primary">批量操作</el-tag>
          </div>
        </div>
        <el-icon class="nav-arrow"><ArrowRight /></el-icon>
      </div>

      <!-- 数据分析 -->
      <div class="nav-item" @click="navigateToAnalysis">
        <div class="nav-icon analysis">
          <el-icon><DataAnalysis /></el-icon>
        </div>
        <div class="nav-content">
          <h3>数据分析</h3>
          <p>设备数据统计分析和报表生成</p>
          <div class="nav-features">
            <el-tag size="small" type="info">数据统计</el-tag>
            <el-tag size="small" type="success">趋势分析</el-tag>
            <el-tag size="small" type="warning">报表导出</el-tag>
          </div>
        </div>
        <el-icon class="nav-arrow"><ArrowRight /></el-icon>
      </div>

      <!-- 设备管理 -->
      <div class="nav-item" @click="navigateToManagement">
        <div class="nav-icon management">
          <el-icon><Tools /></el-icon>
        </div>
        <div class="nav-content">
          <h3>设备管理</h3>
          <p>设备配置、固件升级和维护管理</p>
          <div class="nav-features">
            <el-tag size="small" type="primary">配置管理</el-tag>
            <el-tag size="small" type="warning">固件升级</el-tag>
            <el-tag size="small" type="danger">故障诊断</el-tag>
          </div>
        </div>
        <el-icon class="nav-arrow"><ArrowRight /></el-icon>
      </div>
    </div>
  </el-card>
</template>

<script setup>
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { 
  Link, 
  TrendCharts, 
  Setting, 
  DataAnalysis, 
  Tools,
  ArrowRight 
} from '@element-plus/icons-vue'

const props = defineProps({
  deviceId: {
    type: [String, Number],
    required: true
  }
})

const router = useRouter()

// 导航方法
const navigateToRealtime = () => {
  router.push(`/device/${props.deviceId}/realtime`)
}

const navigateToControl = () => {
  router.push(`/device/${props.deviceId}/control`)
}

const navigateToAnalysis = () => {
  // 暂时显示消息，后续可以实现
  ElMessage.info('数据分析功能正在开发中...')
}

const navigateToManagement = () => {
  // 暂时显示消息，后续可以实现
  ElMessage.info('设备管理功能正在开发中...')
}
</script>

<style scoped>
.quick-navigation-card {
  margin-top: 24px;
}

.card-header {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 600;
}

.navigation-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 16px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 20px;
  border: 1px solid var(--el-border-color-light);
  border-radius: 12px;
  background: var(--el-bg-color-page);
  cursor: pointer;
  transition: all 0.3s ease;
}

.nav-item:hover {
  border-color: var(--el-color-primary);
  background: var(--el-color-primary-light-9);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.nav-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  color: white;
  flex-shrink: 0;
}

.nav-icon.realtime {
  background: linear-gradient(135deg, #409eff, #67c23a);
}

.nav-icon.control {
  background: linear-gradient(135deg, #e6a23c, #f56c6c);
}

.nav-icon.analysis {
  background: linear-gradient(135deg, #909399, #409eff);
}

.nav-icon.management {
  background: linear-gradient(135deg, #f56c6c, #e6a23c);
}

.nav-content {
  flex: 1;
}

.nav-content h3 {
  margin: 0 0 8px 0;
  font-size: 18px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.nav-content p {
  margin: 0 0 12px 0;
  font-size: 14px;
  color: var(--el-text-color-regular);
  line-height: 1.5;
}

.nav-features {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}

.nav-arrow {
  font-size: 20px;
  color: var(--el-text-color-placeholder);
  transition: all 0.3s ease;
}

.nav-item:hover .nav-arrow {
  color: var(--el-color-primary);
  transform: translateX(4px);
}

@media (max-width: 768px) {
  .navigation-grid {
    grid-template-columns: 1fr;
  }
  
  .nav-item {
    padding: 16px;
  }
  
  .nav-icon {
    width: 40px;
    height: 40px;
    font-size: 20px;
  }
  
  .nav-content h3 {
    font-size: 16px;
  }
  
  .nav-content p {
    font-size: 13px;
  }
}
</style>