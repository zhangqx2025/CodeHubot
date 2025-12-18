<template>
  <div class="device-detail-info-page">
    <!-- 页面头部 -->
    <div class="page-header">
      <div class="header-left">
        <el-button @click="goBack" type="text" class="back-btn">
          <el-icon><ArrowLeft /></el-icon>
          返回设备列表
        </el-button>
        <div class="page-title">
          <h2>{{ device?.name || '设备' }} - 设备详情</h2>
        </div>
      </div>
    </div>

    <!-- 主要内容区域 -->
    <div class="page-content" v-if="device">
      <el-card shadow="never" class="info-card">
        <div class="info-item">
          <span class="label">设备名称</span>
          <span class="value">{{ device.name }}</span>
        </div>
        <div class="info-item">
          <span class="label">在线状态</span>
          <el-tag :type="device.is_online ? 'success' : 'danger'" size="small">
            {{ device.is_online ? '在线' : '离线' }}
          </el-tag>
        </div>
        <div class="info-item">
          <span class="label">产品名称</span>
          <span class="value">{{ device.product_name || '未分配' }}</span>
        </div>
        <div class="info-item">
          <span class="label">设备UUID</span>
          <span class="value uuid">{{ device.uuid }}</span>
        </div>
        <div class="info-item" v-if="device.mac_address">
          <span class="label">MAC地址</span>
          <span class="value">{{ device.mac_address }}</span>
        </div>
        <div class="info-item">
          <span class="label">最后上报</span>
          <span class="value time">{{ formatBeijingTime(device.last_seen) }}</span>
        </div>
      </el-card>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { ArrowLeft } from '@element-plus/icons-vue'
import { getDevicesWithProductInfo } from '@/api/device'
import logger from '../utils/logger'

const route = useRoute()
const router = useRouter()

const device = ref(null)
const loading = ref(false)

// 从路由参数获取设备UUID
const deviceUuid = computed(() => route.params.uuid)

// 加载设备信息
const loadDeviceInfo = async () => {
  loading.value = true
  try {
    const response = await getDevicesWithProductInfo()
    if (response.data) {
      device.value = response.data.find(d => d.uuid === deviceUuid.value)
      if (!device.value) {
        ElMessage.error('设备不存在')
        goBack()
      }
    }
  } catch (error) {
    logger.error('加载设备信息失败:', error)
    ElMessage.error('加载设备信息失败')
  } finally {
    loading.value = false
  }
}

// 格式化时间（简化版）
const formatBeijingTime = (timestamp) => {
  if (!timestamp) return '-'
  return new Date(timestamp).toLocaleString('zh-CN', { 
    hour12: false,
    timeZone: 'Asia/Shanghai'
  })
}

// 返回设备列表
const goBack = () => {
  router.push('/device/devices')
}

// 生命周期
onMounted(() => {
  loadDeviceInfo()
})
</script>

<style scoped>
.device-detail-info-page {
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  padding-bottom: 16px;
  border-bottom: 1px solid #ebeef5;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.back-btn {
  font-size: 14px;
}

.page-title h2 {
  margin: 0;
  font-size: 20px;
  font-weight: 600;
}

.page-content {
  padding-top: 8px;
}

.info-card {
  max-width: 800px;
}

.info-item {
  display: flex;
  align-items: center;
  padding: 16px 0;
  border-bottom: 1px solid #f0f0f0;
}

.info-item:last-child {
  border-bottom: none;
}

.info-item .label {
  width: 120px;
  color: #909399;
  font-size: 14px;
  flex-shrink: 0;
}

.info-item .value {
  flex: 1;
  color: #303133;
  font-size: 14px;
  word-break: break-all;
}

.info-item .value.uuid {
  font-family: monospace;
  font-size: 13px;
  color: #606266;
}

.info-item .value.time {
  color: #606266;
}
</style>

