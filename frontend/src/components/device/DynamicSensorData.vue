<template>
  <el-card class="sensor-data-card" shadow="hover" v-loading="loading">
    <template #header>
      <div class="card-header">
        <div class="header-left">
          <el-icon size="20" color="#409EFF"><TrendCharts /></el-icon>
          <span class="header-title">实时传感器数据</span>
          <el-tag v-if="sensorCount > 0" type="info" size="small">
            {{ sensorCount }} 个传感器
          </el-tag>
        </div>
        <div class="header-actions">
          <el-button @click="refreshData" :icon="Refresh" size="small" circle />
          <el-button @click="toggleAutoRefresh" :icon="Timer" size="small" circle 
                     :type="autoRefresh ? 'primary' : 'default'" />
        </div>
      </div>
    </template>

    <div v-if="!sensorConfig || sensorConfig.length === 0" class="no-sensors">
      <el-empty description="该设备未配置传感器" />
    </div>

    <div v-else class="sensor-grid">
      <div 
        v-for="sensor in sensorConfig" 
        :key="sensor.key"
        class="sensor-item"
        :class="getSensorStatusClass(sensor)"
      >
        <div class="sensor-header">
          <div class="sensor-icon">
            <el-icon :size="24" :color="getSensorIconColor(sensor)">
              <component :is="getSensorIcon(sensor)" />
            </el-icon>
          </div>
          <div class="sensor-info">
            <div class="sensor-label">{{ sensor.label }}</div>
            <div class="sensor-description">{{ sensor.description || sensor.type }}</div>
          </div>
          <div class="sensor-status">
            <el-tag 
              :type="getSensorTagType(sensor)" 
              size="small"
              effect="plain"
            >
              {{ getSensorStatusText(sensor) }}
            </el-tag>
          </div>
        </div>

        <div class="sensor-value">
          <span class="value-number">{{ formatSensorValue(sensor) }}</span>
          <span class="value-unit">{{ sensor.unit || '' }}</span>
        </div>

        <!-- 进度条显示（适用于百分比类型数据） -->
        <div v-if="isPercentageType(sensor)" class="sensor-progress">
          <el-progress 
            :percentage="getSensorPercentage(sensor)"
            :color="getProgressColor(sensor)"
            :show-text="false"
            :stroke-width="8"
          />
        </div>

        <!-- 趋势图标 -->
        <div class="sensor-trend" v-if="sensor.trend">
          <el-icon :color="getTrendColor(sensor.trend)">
            <ArrowUp v-if="sensor.trend === 'up'" />
            <ArrowDown v-if="sensor.trend === 'down'" />
            <Minus v-if="sensor.trend === 'stable'" />
          </el-icon>
          <span class="trend-text">{{ getTrendText(sensor.trend) }}</span>
        </div>

        <!-- 最后更新时间 -->
        <div class="sensor-timestamp">
          <el-icon size="12"><Clock /></el-icon>
          <span>{{ formatTimestamp(sensor.timestamp) }}</span>
        </div>
      </div>
    </div>

    <!-- 数据统计摘要 -->
    <div v-if="sensorConfig && sensorConfig.length > 0" class="data-summary">
      <div class="summary-item">
        <span class="summary-label">正常:</span>
        <span class="summary-value normal">{{ normalSensorCount }}</span>
      </div>
      <div class="summary-item">
        <span class="summary-label">警告:</span>
        <span class="summary-value warning">{{ warningSensorCount }}</span>
      </div>
      <div class="summary-item">
        <span class="summary-label">异常:</span>
        <span class="summary-value danger">{{ dangerSensorCount }}</span>
      </div>
      <div class="summary-item">
        <span class="summary-label">最后更新:</span>
        <span class="summary-value">{{ lastUpdateTime }}</span>
      </div>
    </div>
  </el-card>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { 
  TrendCharts, Refresh, Timer, Clock, ArrowUp, ArrowDown, Minus,
  Monitor, Odometer, Connection, Operation,
  Warning, InfoFilled
} from '@element-plus/icons-vue'

const props = defineProps({
  device: {
    type: Object,
    required: true
  },
  sensorConfig: {
    type: Array,
    default: () => []
  },
  realTimeData: {
    type: Object,
    default: () => ({})
  },
  loading: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['refresh', 'dataUpdate'])

const autoRefresh = ref(false)
const refreshInterval = ref(null)

// 计算属性
const sensorCount = computed(() => props.sensorConfig?.length || 0)

const normalSensorCount = computed(() => {
  return props.sensorConfig?.filter(sensor => !isWarning(sensor) && !isDanger(sensor)).length || 0
})

const warningSensorCount = computed(() => {
  return props.sensorConfig?.filter(sensor => isWarning(sensor) && !isDanger(sensor)).length || 0
})

const dangerSensorCount = computed(() => {
  return props.sensorConfig?.filter(sensor => isDanger(sensor)).length || 0
})

const lastUpdateTime = computed(() => {
  const timestamps = props.sensorConfig?.map(sensor => sensor.timestamp).filter(Boolean)
  if (!timestamps || timestamps.length === 0) return 'N/A'
  
  const latest = Math.max(...timestamps.map(t => new Date(t).getTime()))
  return formatTimestamp(new Date(latest).toISOString())
})

// 方法
const getSensorIcon = (sensor) => {
  const iconMap = {
    'temperature': Monitor,
    'humidity': Odometer,
    'pressure': Monitor,
    'light': Monitor,
    'motion': Operation,
    'sound': Monitor,
    'gas': Warning,
    'voltage': Monitor,
    'current': Monitor,
    'power': Monitor,
    'distance': Odometer,
    'ph': Monitor,
    'co2': Warning,
    'pm25': Warning,
    'default': Monitor
  }
  
  return iconMap[sensor.type] || iconMap[sensor.key] || iconMap.default
}

const getSensorIconColor = (sensor) => {
  if (isDanger(sensor)) return '#F56C6C'
  if (isWarning(sensor)) return '#E6A23C'
  return '#409EFF'
}

const getSensorStatusClass = (sensor) => {
  if (isDanger(sensor)) return 'sensor-danger'
  if (isWarning(sensor)) return 'sensor-warning'
  return 'sensor-normal'
}

const getSensorTagType = (sensor) => {
  if (isDanger(sensor)) return 'danger'
  if (isWarning(sensor)) return 'warning'
  return 'success'
}

const getSensorStatusText = (sensor) => {
  if (isDanger(sensor)) return '异常'
  if (isWarning(sensor)) return '警告'
  return '正常'
}

const formatSensorValue = (sensor) => {
  const value = props.realTimeData[sensor.key]
  if (value === undefined || value === null) return '--'
  
  if (typeof value === 'number') {
    return sensor.decimal_places !== undefined 
      ? value.toFixed(sensor.decimal_places)
      : value.toString()
  }
  
  return value.toString()
}

const isPercentageType = (sensor) => {
  return sensor.unit === '%' || sensor.type === 'percentage' || 
         (sensor.max_value && sensor.min_value !== undefined)
}

const getSensorPercentage = (sensor) => {
  const value = props.realTimeData[sensor.key]
  if (value === undefined || value === null) return 0
  
  if (sensor.max_value && sensor.min_value !== undefined) {
    const range = sensor.max_value - sensor.min_value
    return Math.min(100, Math.max(0, ((value - sensor.min_value) / range) * 100))
  }
  
  if (sensor.unit === '%') {
    return Math.min(100, Math.max(0, value))
  }
  
  return 0
}

const getProgressColor = (sensor) => {
  if (isDanger(sensor)) return '#F56C6C'
  if (isWarning(sensor)) return '#E6A23C'
  return '#67C23A'
}

const isWarning = (sensor) => {
  const value = props.realTimeData[sensor.key]
  if (value === undefined || value === null || !sensor.warning_threshold) return false
  
  const { min, max } = sensor.warning_threshold
  return (min !== undefined && value < min) || (max !== undefined && value > max)
}

const isDanger = (sensor) => {
  const value = props.realTimeData[sensor.key]
  if (value === undefined || value === null || !sensor.danger_threshold) return false
  
  const { min, max } = sensor.danger_threshold
  return (min !== undefined && value < min) || (max !== undefined && value > max)
}

const getTrendColor = (trend) => {
  const colorMap = {
    'up': '#67C23A',
    'down': '#F56C6C',
    'stable': '#909399'
  }
  return colorMap[trend] || '#909399'
}

const getTrendText = (trend) => {
  const textMap = {
    'up': '上升',
    'down': '下降',
    'stable': '稳定'
  }
  return textMap[trend] || ''
}

const formatTimestamp = (timestamp) => {
  if (!timestamp) return 'N/A'
  
  const now = new Date()
  const time = new Date(timestamp)
  const diffMs = now - time
  const diffMins = Math.floor(diffMs / 60000)
  
  if (diffMins < 1) return '刚刚'
  if (diffMins < 60) return `${diffMins}分钟前`
  
  return time.toLocaleTimeString()
}

const refreshData = () => {
  emit('refresh')
}

const toggleAutoRefresh = () => {
  autoRefresh.value = !autoRefresh.value
  
  if (autoRefresh.value) {
    refreshInterval.value = setInterval(() => {
      refreshData()
    }, 5000) // 每5秒刷新一次
  } else {
    if (refreshInterval.value) {
      clearInterval(refreshInterval.value)
      refreshInterval.value = null
    }
  }
}

onMounted(() => {
  // 默认开启自动刷新
  toggleAutoRefresh()
})

onUnmounted(() => {
  if (refreshInterval.value) {
    clearInterval(refreshInterval.value)
  }
})
</script>

<style scoped>
.sensor-data-card {
  border-radius: 16px;
  border: none;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
  border: 1px solid #e2e8f0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.header-title {
  font-size: 1.1rem;
  font-weight: 600;
  color: #1e293b;
}

.header-actions {
  display: flex;
  gap: 8px;
}

.no-sensors {
  padding: 40px 0;
}

.sensor-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 16px;
}

.sensor-item {
  padding: 20px;
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  background: rgba(255, 255, 255, 0.8);
  transition: all 0.3s ease;
}

.sensor-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.1);
}

.sensor-item.sensor-warning {
  border-color: #E6A23C;
  background: linear-gradient(135deg, #fefcf3 0%, #fef7e6 100%);
}

.sensor-item.sensor-danger {
  border-color: #F56C6C;
  background: linear-gradient(135deg, #fef2f2 0%, #fee2e2 100%);
}

.sensor-header {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  margin-bottom: 16px;
}

.sensor-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 48px;
  height: 48px;
  border-radius: 12px;
  background: rgba(64, 158, 255, 0.1);
}

.sensor-info {
  flex: 1;
}

.sensor-label {
  font-size: 1rem;
  font-weight: 600;
  color: #1e293b;
  margin-bottom: 4px;
}

.sensor-description {
  font-size: 0.85rem;
  color: #64748b;
}

.sensor-value {
  display: flex;
  align-items: baseline;
  gap: 8px;
  margin-bottom: 12px;
}

.value-number {
  font-size: 2rem;
  font-weight: 700;
  color: #1e293b;
}

.value-unit {
  font-size: 1rem;
  color: #64748b;
  font-weight: 500;
}

.sensor-progress {
  margin-bottom: 12px;
}

.sensor-trend {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 8px;
  font-size: 0.85rem;
}

.trend-text {
  font-weight: 500;
}

.sensor-timestamp {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 0.8rem;
  color: #64748b;
}

.data-summary {
  margin-top: 24px;
  padding-top: 20px;
  border-top: 1px solid #e2e8f0;
  display: flex;
  justify-content: space-around;
  flex-wrap: wrap;
  gap: 16px;
}

.summary-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.summary-label {
  font-size: 0.85rem;
  color: #64748b;
}

.summary-value {
  font-size: 1.1rem;
  font-weight: 600;
}

.summary-value.normal {
  color: #67C23A;
}

.summary-value.warning {
  color: #E6A23C;
}

.summary-value.danger {
  color: #F56C6C;
}

@media (max-width: 768px) {
  .sensor-grid {
    grid-template-columns: 1fr;
  }
  
  .data-summary {
    flex-direction: column;
    align-items: center;
  }
}
</style>