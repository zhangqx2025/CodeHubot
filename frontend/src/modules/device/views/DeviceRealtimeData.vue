<template>
  <div class="device-realtime-data-page">
    <!-- 页面头部 -->
    <div class="page-header">
      <div class="header-left">
        <el-button @click="goBack" type="text" class="back-btn">
          <el-icon><ArrowLeft /></el-icon>
          返回设备列表
        </el-button>
        <div class="page-title">
          <h2>{{ device?.name || '设备' }} - 实时数据</h2>
          <div class="device-tags" v-if="device">
            <el-tag :type="device.is_online ? 'success' : 'danger'" size="small">
              {{ device.is_online ? '在线' : '离线' }}
            </el-tag>
            <el-tag type="info" size="small">UUID: {{ device.uuid }}</el-tag>
          </div>
        </div>
      </div>
    </div>

    <!-- 主要内容区域 -->
    <div class="page-content" v-if="device">
      <!-- 实时传感器数据卡片 -->
      <div class="sensor-data-section" v-if="productConfig && productConfig.sensor_types && Object.keys(productConfig.sensor_types).length > 0">
        <div class="sensor-cards">
          <el-card 
            v-for="(sensorConfig, sensorKey) in productConfig.sensor_types" 
            :key="sensorKey"
            class="sensor-card"
            shadow="hover"
            v-show="sensorConfig.enabled !== false"
          >
            <div class="sensor-name">
              {{ getSensorDisplayName(sensorKey, sensorConfig) }}
            </div>
            <div class="sensor-value">
              {{ getSensorValue(sensorKey, sensorConfig) }}
            </div>
            <div class="sensor-time" v-if="latestTimestamp">
              {{ formatTime(latestTimestamp) }}
            </div>
          </el-card>
        </div>
      </div>

      <!-- 无数据提示 -->
      <el-empty 
        v-if="!loading && (!latestData || Object.keys(latestData).length === 0)" 
        description="暂无传感器数据"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, onUnmounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { ArrowLeft } from '@element-plus/icons-vue'
import { getDeviceRealtimeData, getDeviceProductConfig } from '@/api/device'
import { getDevicesWithProductInfo } from '@/api/device'
import logger from '../utils/logger'

const route = useRoute()
const router = useRouter()

const device = ref(null)
const productConfig = ref(null)
const loading = ref(false)
const latestData = ref(null)
const latestTimestamp = ref(null)

// 从路由参数获取设备UUID
const deviceUuid = computed(() => route.params.uuid)

// 加载设备信息
const loadDeviceInfo = async () => {
  try {
    const response = await getDevicesWithProductInfo()
    if (response.data) {
      device.value = response.data.find(d => d.uuid === deviceUuid.value)
      if (!device.value) {
        ElMessage.error('设备不存在')
        goBack()
        return
      }
      
      // 加载产品配置
      if (device.value.uuid) {
        await loadProductConfig(device.value.uuid)
      }
    }
  } catch (error) {
    logger.error('加载设备信息失败:', error)
    ElMessage.error('加载设备信息失败')
  }
}

// 加载产品配置
const loadProductConfig = async (deviceUuid) => {
  try {
    const response = await getDeviceProductConfig(deviceUuid)
    if (response.data) {
      productConfig.value = response.data
      logger.info('产品配置加载成功:', response.data)
    }
  } catch (error) {
    logger.error('加载产品配置失败:', error)
    // 不显示错误消息，使用默认显示方式
    productConfig.value = {
      sensor_types: {},
      control_ports: {}
    }
  }
}

// 加载实时数据
const loadRealtimeData = async () => {
  if (!deviceUuid.value) return
  
  loading.value = true
  try {
    const response = await getDeviceRealtimeData(deviceUuid.value, 1)
    if (response.data) {
      // 优先使用latest字段（最新数据）
      if (response.data.latest) {
        latestData.value = response.data.latest.data
        latestTimestamp.value = response.data.latest.timestamp
      } else if (response.data.data && response.data.data.length > 0) {
        // 向后兼容：如果没有latest字段，使用第一条数据
        latestData.value = response.data.data[0].data
        latestTimestamp.value = response.data.data[0].timestamp
      } else {
        latestData.value = null
        latestTimestamp.value = null
      }
    }
  } catch (error) {
    logger.error('加载实时数据失败:', error)
    ElMessage.error('加载实时数据失败')
  } finally {
    loading.value = false
  }
}

// 获取传感器显示名称（优先使用用户自定义的功能描述）
const getSensorDisplayName = (sensorKey, sensorConfig) => {
  // 如果有加载设备配置，尝试获取custom_name
  if (device.value && device.value.device_sensor_config) {
    const deviceSensorConfig = device.value.device_sensor_config[sensorKey]
    if (deviceSensorConfig && deviceSensorConfig.custom_name) {
      return deviceSensorConfig.custom_name // 用户自定义的功能描述
    }
  }
  // 否则使用产品配置中的名称
  return sensorConfig.name || sensorKey
}

// 根据产品配置获取传感器值
const getSensorValue = (sensorKey, sensorConfig) => {
  if (!latestData.value) {
    return '暂无数据'
  }
  
  // 尝试匹配传感器数据
  // 支持多种匹配方式：完全匹配、部分匹配
  let value = latestData.value[sensorKey]
  
  if (value === undefined) {
    // 尝试模糊匹配
    const lowerKey = sensorKey.toLowerCase()
    for (const dataKey in latestData.value) {
      if (dataKey.toLowerCase().includes(lowerKey) || lowerKey.includes(dataKey.toLowerCase())) {
        value = latestData.value[dataKey]
        break
      }
    }
  }
  
  if (value === undefined || value === null) {
    return '无数据'
  }
  
  // 特殊处理：雨水传感器显示布尔值
  if (sensorConfig.type === 'RAIN_SENSOR' && typeof value === 'boolean') {
    return value ? '有雨水' : '无雨水'
  }
  
  // 格式化数值
  if (typeof value === 'number') {
    const precision = sensorConfig.accuracy ? Math.max(0, -Math.floor(Math.log10(sensorConfig.accuracy))) : 1
    return `${value.toFixed(precision)}${sensorConfig.unit || ''}`
  }
  
  // 布尔值处理（非雨水传感器）
  if (typeof value === 'boolean') {
    return value ? '是' : '否'
  }
  
  return `${value}${sensorConfig.unit || ''}`
}

// 格式化时间（简化版）
const formatTime = (timestamp) => {
  if (!timestamp) return '-'
  return new Date(timestamp).toLocaleString('zh-CN')
}

// 返回设备列表
const goBack = () => {
  router.push('/device/devices')
}

// 生命周期
onMounted(async () => {
  await loadDeviceInfo()
  await loadRealtimeData()
})

onUnmounted(() => {
  // 清理资源
})
</script>

<style scoped>
.device-realtime-data-page {
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

.device-tags {
  margin-top: 8px;
  display: flex;
  gap: 8px;
}

.header-controls {
  display: flex;
  gap: 12px;
}

.page-content {
  padding-top: 8px;
}

.sensor-cards {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 16px;
}

.sensor-card {
  text-align: center;
  padding: 24px 16px;
}

.sensor-name {
  font-size: 14px;
  color: #909399;
  margin-bottom: 12px;
}

.sensor-value {
  font-size: 36px;
  font-weight: 600;
  color: #409eff;
  margin: 12px 0;
}

.sensor-time {
  font-size: 12px;
  color: #c0c4cc;
  margin-top: 8px;
}
</style>

