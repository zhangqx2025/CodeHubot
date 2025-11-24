<template>
  <div class="dynamic-sensor-display">
    <el-card class="sensor-card" v-if="sensorConfig && Object.keys(sensorConfig).length > 0">
      <template #header>
        <div class="card-header">
          <span>传感器数据</span>
          <el-tag :type="isOnline ? 'success' : 'danger'" size="small">
            {{ isOnline ? '在线' : '离线' }}
          </el-tag>
        </div>
      </template>
      
      <div class="sensor-grid">
        <div 
          v-for="(sensor, key) in sensorConfig" 
          :key="key"
          class="sensor-item"
        >
          <div class="sensor-header">
            <el-icon class="sensor-icon">
              <component :is="getSensorIcon(sensor.type)" />
            </el-icon>
            <span class="sensor-name">{{ sensor.name || key }}</span>
          </div>
          
          <div class="sensor-value">
            <span class="value">{{ getSensorValue(key) }}</span>
            <span class="unit">{{ sensor.unit || '' }}</span>
          </div>
          
          <div class="sensor-info">
            <el-tag size="small" type="info">{{ sensor.type }}</el-tag>
            <span class="port">端口: {{ sensor.port }}</span>
          </div>
          
          <!-- 传感器状态指示器 -->
          <div class="sensor-status">
            <el-progress 
              v-if="sensor.type === 'analog'"
              :percentage="getSensorPercentage(key, sensor)"
              :color="getSensorColor(key, sensor)"
              :stroke-width="4"
              :show-text="false"
            />
            <el-tag 
              v-else-if="sensor.type === 'digital'"
              :type="getSensorValue(key) ? 'success' : 'info'"
              size="small"
            >
              {{ getSensorValue(key) ? '高电平' : '低电平' }}
            </el-tag>
          </div>
        </div>
      </div>
      
      <!-- 传感器配置信息 -->
      <el-collapse v-if="showConfig" class="sensor-config">
        <el-collapse-item title="传感器配置详情" name="config">
          <pre>{{ JSON.stringify(sensorConfig, null, 2) }}</pre>
        </el-collapse-item>
      </el-collapse>
    </el-card>
    
    <el-empty v-else description="暂无传感器配置" />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { 
  Monitor, 
  Operation, 
  Lightning, 
  Sunny,
  Warning,
  CircleCheck
} from '@element-plus/icons-vue'

const props = defineProps({
  deviceId: {
    type: [String, Number],
    required: true
  },
  sensorConfig: {
    type: Object,
    default: () => ({})
  },
  sensorData: {
    type: Object,
    default: () => ({})
  },
  isOnline: {
    type: Boolean,
    default: false
  },
  showConfig: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['refresh-data'])

// 传感器图标映射
const sensorIconMap = {
  temperature: Monitor,
  humidity: Sunny,
  pressure: Monitor,
  voltage: Lightning,
  current: Lightning,
  power: Operation,
  ph: Monitor,
  dissolved_oxygen: Monitor,
  turbidity: Monitor,
  digital: CircleCheck,
  analog: Monitor,
  default: Monitor
}

// 获取传感器图标
const getSensorIcon = (sensorType) => {
  return sensorIconMap[sensorType] || sensorIconMap.default
}

// 获取传感器值
const getSensorValue = (sensorKey) => {
  const value = props.sensorData[sensorKey]
  if (value === undefined || value === null) {
    return '--'
  }
  
  const sensor = props.sensorConfig[sensorKey]
  if (sensor && sensor.type === 'digital') {
    return value ? 1 : 0
  }
  
  // 格式化数值
  if (typeof value === 'number') {
    return value.toFixed(sensor?.precision || 2)
  }
  
  return value
}

// 获取传感器百分比（用于进度条）
const getSensorPercentage = (sensorKey, sensor) => {
  const value = props.sensorData[sensorKey]
  if (value === undefined || value === null) return 0
  
  const min = sensor.min || 0
  const max = sensor.max || 100
  
  return Math.min(100, Math.max(0, ((value - min) / (max - min)) * 100))
}

// 获取传感器颜色
const getSensorColor = (sensorKey, sensor) => {
  const value = props.sensorData[sensorKey]
  if (value === undefined || value === null) return '#909399'
  
  // 根据阈值设置颜色
  if (sensor.thresholds) {
    if (value >= sensor.thresholds.danger) return '#F56C6C'
    if (value >= sensor.thresholds.warning) return '#E6A23C'
    return '#67C23A'
  }
  
  // 默认颜色逻辑
  const percentage = getSensorPercentage(sensorKey, sensor)
  if (percentage > 80) return '#F56C6C'
  if (percentage > 60) return '#E6A23C'
  return '#67C23A'
}

// 刷新数据
const refreshData = () => {
  emit('refresh-data')
}

// 定时刷新
let refreshInterval = null

onMounted(() => {
  if (props.isOnline) {
    refreshInterval = setInterval(refreshData, 5000) // 5秒刷新一次
  }
})

onUnmounted(() => {
  if (refreshInterval) {
    clearInterval(refreshInterval)
  }
})
</script>

<style scoped>
.dynamic-sensor-display {
  width: 100%;
}

.sensor-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.sensor-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 16px;
}

.sensor-item {
  padding: 16px;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  background: #fafafa;
  transition: all 0.3s ease;
}

.sensor-item:hover {
  border-color: #409eff;
  box-shadow: 0 2px 8px rgba(64, 158, 255, 0.1);
}

.sensor-header {
  display: flex;
  align-items: center;
  margin-bottom: 12px;
}

.sensor-icon {
  font-size: 20px;
  color: #409eff;
  margin-right: 8px;
}

.sensor-name {
  font-weight: 600;
  color: #303133;
}

.sensor-value {
  display: flex;
  align-items: baseline;
  margin-bottom: 12px;
}

.value {
  font-size: 24px;
  font-weight: 700;
  color: #303133;
  margin-right: 4px;
}

.unit {
  font-size: 14px;
  color: #909399;
}

.sensor-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.port {
  font-size: 12px;
  color: #909399;
}

.sensor-status {
  margin-top: 8px;
}

.sensor-config {
  margin-top: 20px;
}

.sensor-config pre {
  background: #f5f7fa;
  padding: 12px;
  border-radius: 4px;
  font-size: 12px;
  color: #606266;
  overflow-x: auto;
}
</style>