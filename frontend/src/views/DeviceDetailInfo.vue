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
      <div class="header-controls">
        <el-button type="primary" @click="loadDeviceInfo" :loading="loading">
          <el-icon><Refresh /></el-icon>
          刷新
        </el-button>
        <el-button type="danger" plain @click="handleUnbind" :loading="unbinding">
          <el-icon><RemoveFilled /></el-icon>
          解绑设备
        </el-button>
      </div>
    </div>

    <!-- 主要内容区域 -->
    <div class="page-content" v-if="device">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="设备名称">{{ device.name }}</el-descriptions-item>
        <el-descriptions-item label="设备UUID">{{ device.uuid }}</el-descriptions-item>
        <el-descriptions-item label="设备ID">{{ device.device_id }}</el-descriptions-item>
        <el-descriptions-item label="MAC地址">{{ device.mac_address || '-' }}</el-descriptions-item>
        <el-descriptions-item label="产品名称">
          {{ device.product_name || '未分配' }}
        </el-descriptions-item>
        <el-descriptions-item label="在线状态">
          <el-tag :type="device.is_online ? 'success' : 'danger'">
            {{ device.is_online ? '在线' : '离线' }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="最后上报时间" :span="2">
          {{ formatBeijingTime(device.last_seen) }}
        </el-descriptions-item>
        <el-descriptions-item label="描述" :span="2">
          {{ device.description || '-' }}
        </el-descriptions-item>
      </el-descriptions>

      <!-- 产品信息 -->
      <div class="product-info-section" v-if="device.product_name">
        <h3>产品信息</h3>
        <el-descriptions :column="2" border>
          <el-descriptions-item label="产品名称">{{ device.product_name }}</el-descriptions-item>
          <el-descriptions-item label="产品编码">{{ device.product_code || '-' }}</el-descriptions-item>
        </el-descriptions>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ArrowLeft, Refresh, RemoveFilled } from '@element-plus/icons-vue'
import { getDevicesWithProductInfo, unbindDevice } from '@/api/device'
import logger from '../utils/logger'

const route = useRoute()
const router = useRouter()

const device = ref(null)
const loading = ref(false)
const unbinding = ref(false)

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

// 格式化北京时间
const formatBeijingTime = (timestamp) => {
  if (!timestamp) return '-'
  
  // 将UTC时间转换为北京时间（UTC+8）
  const date = new Date(timestamp)
  
  // 使用北京时区格式化
  return date.toLocaleString('zh-CN', {
    timeZone: 'Asia/Shanghai',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false
  })
}

// 解绑设备
const handleUnbind = async () => {
  if (!device.value) {
    ElMessage.warning('设备信息未加载')
    return
  }

  try {
    // 确认解绑（自动清除所有历史数据）
    await ElMessageBox.confirm(
      '确定要解绑此设备吗？\n\n⚠️ 解绑后将自动清除所有历史数据（传感器数据、交互日志等），此操作不可恢复。\n\n解绑后设备将不再属于您，其他用户可以重新绑定该设备（重新绑定时会生成新的UUID和密钥）。',
      '解绑设备',
      {
        confirmButtonText: '确认解绑',
        cancelButtonText: '取消',
        type: 'warning',
        distinguishCancelAndClose: true
      }
    )
    
    // 调用解绑API（自动清除所有历史数据）
    unbinding.value = true
    await unbindDevice(deviceUuid.value)
    
    ElMessage.success({
      message: '设备解绑成功，所有历史数据已清除',
      duration: 3000
    })
    
    // 延迟跳转到设备列表
    setTimeout(() => {
      router.push('/devices')
    }, 1500)
    
  } catch (error) {
    if (error === 'cancel' || error === 'close') {
      // 用户取消操作
      ElMessage.info('已取消解绑')
      return
    }
    
    logger.error('解绑设备失败:', error)
    ElMessage.error(error.response?.data?.detail || '解绑设备失败')
  } finally {
    unbinding.value = false
  }
}

// 返回设备列表
const goBack = () => {
  router.push('/devices')
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

.header-controls {
  display: flex;
  gap: 12px;
}

.page-content {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.product-info-section {
  margin-top: 24px;
}

.product-info-section h3 {
  margin: 0 0 16px 0;
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}
</style>

