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
      <div class="header-controls">
        <el-button type="primary" @click="loadRealtimeData" :loading="loading">
          <el-icon><Refresh /></el-icon>
          手动刷新
        </el-button>
      </div>
    </div>

    <!-- 主要内容区域 -->
    <div class="page-content" v-if="device">
      <!-- 实时传感器数据卡片 - 根据产品配置显示 -->
      <div class="sensor-data-section" v-if="productConfig && productConfig.sensor_types">
        <h3>最新传感器数据 - {{ productConfig.product_name }}</h3>
        <div class="sensor-cards">
          <el-card 
            v-for="(sensorConfig, sensorKey) in productConfig.sensor_types" 
            :key="sensorKey"
            class="sensor-card"
            shadow="hover"
            v-show="sensorConfig.enabled !== false"
          >
            <div class="sensor-header">
              <span class="sensor-name">
                {{ getSensorDisplayName(sensorKey, sensorConfig) }}
              </span>
              <el-tag size="small" type="info">{{ sensorConfig.type }}</el-tag>
            </div>
            <div class="sensor-value">
              {{ getSensorValue(sensorKey, sensorConfig) }}
            </div>
            <div class="sensor-info" v-if="sensorConfig.range">
              <span class="sensor-range">
                范围: {{ sensorConfig.range.min }}~{{ sensorConfig.range.max }}{{ sensorConfig.unit }}
              </span>
            </div>
            <div class="sensor-timestamp" v-if="latestTimestamp">
              {{ formatTime(latestTimestamp) }}
            </div>
          </el-card>
        </div>
        
        <!-- 无产品配置时显示原始数据 -->
        <el-alert
          v-if="Object.keys(productConfig.sensor_types).length === 0 && latestData"
          title="未配置传感器"
          type="warning"
          description="该产品未配置传感器，显示原始数据"
          show-icon
          style="margin-bottom: 16px;"
        />
      </div>

      <!-- 数据历史记录 -->
      <div class="data-history-section">
        <h3>数据历史记录</h3>
        <el-table 
          :data="historyData" 
          v-loading="loading"
          style="width: 100%"
          max-height="400"
        >
          <el-table-column prop="timestamp" label="时间" width="180">
            <template #default="scope">
              {{ formatTime(scope.row.timestamp) }}
            </template>
          </el-table-column>
          <el-table-column label="传感器数据" min-width="300">
            <template #default="scope">
              <div class="data-content">
                <el-tag 
                  v-for="(value, key) in scope.row.data" 
                  :key="key"
                  size="small"
                  style="margin-right: 8px; margin-bottom: 4px;"
                >
                  {{ formatSensorName(key) }}: {{ formatSensorValue(key, value) }}
                </el-tag>
              </div>
            </template>
          </el-table-column>
        </el-table>
      </div>

      <!-- 无数据提示 -->
      <el-empty 
        v-if="!loading && historyData.length === 0" 
        description="暂无传感器数据"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, onUnmounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { ArrowLeft, Refresh } from '@element-plus/icons-vue'
import { getDeviceRealtimeData, getDeviceProductConfig } from '@/api/device'
import { getDevicesWithProductInfo } from '@/api/device'
import logger from '../utils/logger'

const route = useRoute()
const router = useRouter()

const device = ref(null)
const productConfig = ref(null)
const loading = ref(false)
const historyData = ref([])
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
    const response = await getDeviceRealtimeData(deviceUuid.value, 20)
    if (response.data) {
      historyData.value = response.data.data || []
      
      // 优先使用latest字段（最新数据）
      if (response.data.latest) {
        latestData.value = response.data.latest.data
        latestTimestamp.value = response.data.latest.timestamp
      } else if (historyData.value.length > 0) {
        // 向后兼容：如果没有latest字段，使用第一条数据
        latestData.value = historyData.value[0].data
        latestTimestamp.value = historyData.value[0].timestamp
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

// 自动刷新功能已移除，只保留手动刷新

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

// 格式化传感器名称（用于历史记录表格）
const formatSensorName = (key) => {
  // 如果有产品配置，使用配置的名称
  if (productConfig.value && productConfig.value.sensor_types) {
    for (const sensorKey in productConfig.value.sensor_types) {
      const config = productConfig.value.sensor_types[sensorKey]
      if (sensorKey === key || key.toLowerCase().includes(sensorKey.toLowerCase())) {
        return config.name || key
      }
    }
  }
  
  // 否则使用默认映射
  const nameMap = {
    'temperature': '温度',
    'humidity': '湿度',
    'pressure': '压力',
    'light': '光照',
    'dht11_temperature': 'DHT11温度',
    'dht11_humidity': 'DHT11湿度',
    'ds18b20_temperature': 'DS18B20温度'
  }
  return nameMap[key] || key
}

// 格式化传感器值（用于历史记录表格）
const formatSensorValue = (key, value) => {
  // 如果有产品配置，使用配置的单位
  if (productConfig.value && productConfig.value.sensor_types) {
    for (const sensorKey in productConfig.value.sensor_types) {
      const config = productConfig.value.sensor_types[sensorKey]
      if (sensorKey === key || key.toLowerCase().includes(sensorKey.toLowerCase())) {
        if (typeof value === 'number') {
          const precision = config.accuracy ? Math.max(0, -Math.floor(Math.log10(config.accuracy))) : 1
          return `${value.toFixed(precision)}${config.unit || ''}`
        }
        return `${value}${config.unit || ''}`
      }
    }
  }
  
  // 否则使用默认格式化
  if (typeof value === 'number') {
    if (key.includes('temperature') || key.includes('temp')) {
      return `${value.toFixed(1)}°C`
    } else if (key.includes('humidity') || key.includes('humi')) {
      return `${value.toFixed(1)}%`
    } else if (key.includes('pressure')) {
      return `${value.toFixed(2)}hPa`
    } else if (key.includes('light')) {
      return `${value.toFixed(0)}lux`
    }
    return value.toFixed(2)
  }
  return value
}

// 格式化时间
const formatTime = (timestamp) => {
  if (!timestamp) return '-'
  return new Date(timestamp).toLocaleString('zh-CN')
}

// 返回设备列表
const goBack = () => {
  router.push('/devices')
}

// 生命周期
onMounted(async () => {
  await loadDeviceInfo()
  await loadRealtimeData()
})

onUnmounted(() => {
  // 清理资源（如果有的话）
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
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.sensor-data-section h3,
.data-history-section h3 {
  margin: 0 0 16px 0;
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}

.sensor-cards {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 16px;
  margin-bottom: 24px;
}

.sensor-card {
  text-align: center;
}

.sensor-header {
  margin-bottom: 12px;
}

.sensor-name {
  font-size: 14px;
  color: #606266;
}

.sensor-value {
  font-size: 32px;
  font-weight: 600;
  color: #409eff;
  margin: 16px 0;
}

.sensor-timestamp {
  font-size: 12px;
  color: #909399;
}

.data-content {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}
</style>

