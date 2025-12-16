<template>
  <el-dialog
    v-model="visible"
    :title="`${device?.name || '设备'} - 实时监控`"
    width="80%"
    :before-close="handleClose"
    class="monitor-dialog"
  >
    <div class="monitor-container" v-if="device">
      <!-- 设备基本信息 -->
      <div class="device-info-header">
        <div class="device-basic">
          <h3>{{ device.name }}</h3>
          <div class="device-tags">
            <el-tag :type="device.is_online ? 'success' : 'danger'" size="small">
              {{ device.is_online ? '在线' : '离线' }}
            </el-tag>
            <el-tag type="info" size="small">{{ device.device_type }}</el-tag>
            <el-tag type="warning" size="small">ID: {{ device.device_id }}</el-tag>
          </div>
        </div>
        <div class="monitor-controls">
          <el-button 
            :type="isMonitoring ? 'danger' : 'success'" 
            size="small"
            @click="toggleMonitoring"
            :loading="connecting"
          >
            <el-icon><VideoPlay v-if="!isMonitoring" /><VideoPause v-else /></el-icon>
            {{ isMonitoring ? '停止监控' : '开始监控' }}
          </el-button>
          <el-button type="primary" size="small" @click="exportData">
            <el-icon><Download /></el-icon>
            导出数据
          </el-button>
        </div>
      </div>

      <!-- 实时数据展示区域 -->
      <div class="monitor-content">
        <!-- 实时数据卡片 -->
        <div class="data-cards">
          <div class="data-card" v-for="metric in realTimeMetrics" :key="metric.key">
            <div class="metric-header">
              <span class="metric-name">{{ metric.name }}</span>
              <span class="metric-unit">{{ metric.unit }}</span>
            </div>
            <div class="metric-value" :class="getValueClass(metric)">
              {{ formatValue(metric.value) }}
            </div>
            <div class="metric-trend">
              <el-icon :class="getTrendClass(metric.trend)">
                <TrendCharts v-if="metric.trend === 'up'" />
                <Bottom v-else-if="metric.trend === 'down'" />
                <Minus v-else />
              </el-icon>
              <span class="trend-text">{{ getTrendText(metric.trend) }}</span>
            </div>
          </div>
        </div>

        <!-- 实时图表 -->
        <div class="charts-container">
          <div class="chart-wrapper">
            <h4>实时数据趋势</h4>
            <div ref="chartContainer" class="chart-content"></div>
          </div>
        </div>

        <!-- 实时日志 -->
        <div class="logs-container">
          <div class="logs-header">
            <h4>实时日志</h4>
            <div class="logs-controls">
              <el-button size="small" @click="clearLogs">清空日志</el-button>
              <el-switch
                v-model="autoScroll"
                active-text="自动滚动"
                size="small"
              />
            </div>
          </div>
          <div class="logs-content" ref="logsContainer">
            <div 
              v-for="log in realtimeLogs" 
              :key="log.id"
              class="log-item"
              :class="log.level"
            >
              <span class="log-time">{{ formatTime(log.timestamp) }}</span>
              <span class="log-level">{{ log.level.toUpperCase() }}</span>
              <span class="log-message">{{ log.message }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <template #footer>
      <div class="dialog-footer">
        <el-button @click="handleClose">关闭</el-button>
        <el-button type="primary" @click="openDeviceDetail">查看详情</el-button>
      </div>
    </template>
  </el-dialog>
</template>

<script setup>
import { ref, reactive, computed, watch, onMounted, onUnmounted, nextTick } from 'vue'
import { ElMessage } from 'element-plus'
import { 
  VideoPlay, 
  VideoPause, 
  Download, 
  TrendCharts, 
  Bottom, 
  Minus 
} from '@element-plus/icons-vue'
import * as echarts from 'echarts'

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false
  },
  device: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['update:modelValue', 'openDetail'])

// 响应式数据
const visible = computed({
  get: () => props.modelValue,
  set: (value) => emit('update:modelValue', value)
})

const isMonitoring = ref(false)
const connecting = ref(false)
const autoScroll = ref(true)
const chartContainer = ref(null)
const logsContainer = ref(null)
let chart = null
let websocket = null
let monitoringInterval = null

// 实时数据
const realTimeMetrics = ref([])
const realtimeLogs = ref([])
const chartData = reactive({
  timestamps: [],
  values: []
})

// 初始化实时指标
const initializeMetrics = () => {
  if (!props.device) return
  
  const metricsConfig = {
    '温度传感器': [
      { key: 'temperature', name: '温度', unit: '°C', value: 0, trend: 'stable' },
      { key: 'humidity', name: '湿度', unit: '%', value: 0, trend: 'stable' }
    ],
    '湿度传感器': [
      { key: 'humidity', name: '湿度', unit: '%', value: 0, trend: 'stable' },
      { key: 'temperature', name: '温度', unit: '°C', value: 0, trend: 'stable' }
    ],
    '压力传感器': [
      { key: 'pressure', name: '压力', unit: 'Pa', value: 0, trend: 'stable' },
      { key: 'temperature', name: '温度', unit: '°C', value: 0, trend: 'stable' }
    ]
  }
  
  realTimeMetrics.value = metricsConfig[props.device.device_type] || [
    { key: 'status', name: '状态', unit: '', value: '正常', trend: 'stable' }
  ]
}

// 开始/停止监控
const toggleMonitoring = async () => {
  if (isMonitoring.value) {
    stopMonitoring()
  } else {
    await startMonitoring()
  }
}

// 开始监控
const startMonitoring = async () => {
  if (!props.device?.is_online) {
    ElMessage.warning('设备离线，无法开始监控')
    return
  }
  
  connecting.value = true
  
  try {
    // 模拟WebSocket连接
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    isMonitoring.value = true
    
    // 启动数据模拟
    startDataSimulation()
    
    addLog('info', '开始实时监控')
    ElMessage.success('实时监控已启动')
  } catch (error) {
    ElMessage.error('启动监控失败')
    console.error('Start monitoring error:', error)
  } finally {
    connecting.value = false
  }
}

// 停止监控
const stopMonitoring = () => {
  isMonitoring.value = false
  
  if (monitoringInterval) {
    clearInterval(monitoringInterval)
    monitoringInterval = null
  }
  
  if (websocket) {
    websocket.close()
    websocket = null
  }
  
  addLog('info', '停止实时监控')
  ElMessage.info('实时监控已停止')
}

// 启动数据模拟
const startDataSimulation = () => {
  monitoringInterval = setInterval(() => {
    updateRealTimeData()
  }, 2000) // 每2秒更新一次数据
}

// 更新实时数据
const updateRealTimeData = () => {
  const now = new Date()
  
  realTimeMetrics.value.forEach(metric => {
    const oldValue = metric.value
    
    // 模拟数据变化
    switch (metric.key) {
      case 'temperature':
        metric.value = (20 + Math.random() * 10).toFixed(1)
        break
      case 'humidity':
        metric.value = (40 + Math.random() * 20).toFixed(1)
        break
      case 'pressure':
        metric.value = (1000 + Math.random() * 100).toFixed(0)
        break
      default:
        metric.value = Math.random() > 0.5 ? '正常' : '警告'
    }
    
    // 计算趋势
    if (typeof metric.value === 'string') {
      metric.trend = 'stable'
    } else {
      const newValue = parseFloat(metric.value)
      const prevValue = parseFloat(oldValue)
      if (newValue > prevValue) {
        metric.trend = 'up'
      } else if (newValue < prevValue) {
        metric.trend = 'down'
      } else {
        metric.trend = 'stable'
      }
    }
  })
  
  // 更新图表数据
  updateChartData()
  
  // 添加日志
  if (Math.random() > 0.7) {
    const messages = [
      '数据采集正常',
      '传感器状态良好',
      '数据传输稳定',
      '设备响应正常'
    ]
    addLog('info', messages[Math.floor(Math.random() * messages.length)])
  }
}

// 更新图表数据
const updateChartData = () => {
  const now = new Date()
  const timeStr = now.toLocaleTimeString()
  
  chartData.timestamps.push(timeStr)
  
  // 只保留最近20个数据点
  if (chartData.timestamps.length > 20) {
    chartData.timestamps.shift()
  }
  
  // 更新图表
  if (chart && realTimeMetrics.value.length > 0) {
    const metric = realTimeMetrics.value[0]
    const value = typeof metric.value === 'string' ? 0 : parseFloat(metric.value)
    
    chart.setOption({
      xAxis: {
        data: chartData.timestamps
      },
      series: [{
        data: [...chartData.values, value].slice(-20)
      }]
    })
    
    chartData.values.push(value)
    if (chartData.values.length > 20) {
      chartData.values.shift()
    }
  }
}

// 初始化图表
const initChart = () => {
  if (!chartContainer.value) return
  
  chart = echarts.init(chartContainer.value)
  
  const option = {
    title: {
      text: '实时数据',
      left: 'center',
      textStyle: {
        fontSize: 14
      }
    },
    tooltip: {
      trigger: 'axis'
    },
    xAxis: {
      type: 'category',
      data: chartData.timestamps,
      axisLabel: {
        rotate: 45
      }
    },
    yAxis: {
      type: 'value'
    },
    series: [{
      name: realTimeMetrics.value[0]?.name || '数值',
      type: 'line',
      data: chartData.values,
      smooth: true,
      lineStyle: {
        color: '#409eff'
      },
      areaStyle: {
        color: {
          type: 'linear',
          x: 0,
          y: 0,
          x2: 0,
          y2: 1,
          colorStops: [{
            offset: 0, color: 'rgba(64, 158, 255, 0.3)'
          }, {
            offset: 1, color: 'rgba(64, 158, 255, 0.1)'
          }]
        }
      }
    }]
  }
  
  chart.setOption(option)
}

// 添加日志
const addLog = (level, message) => {
  const log = {
    id: Date.now() + Math.random(),
    timestamp: new Date(),
    level,
    message
  }
  
  realtimeLogs.value.push(log)
  
  // 只保留最近100条日志
  if (realtimeLogs.value.length > 100) {
    realtimeLogs.value.shift()
  }
  
  // 自动滚动到底部
  if (autoScroll.value) {
    nextTick(() => {
      if (logsContainer.value) {
        logsContainer.value.scrollTop = logsContainer.value.scrollHeight
      }
    })
  }
}

// 清空日志
const clearLogs = () => {
  realtimeLogs.value = []
  ElMessage.success('日志已清空')
}

// 导出数据
const exportData = () => {
  const data = {
    device: props.device,
    metrics: realTimeMetrics.value,
    logs: realtimeLogs.value,
    exportTime: new Date().toISOString()
  }
  
  const blob = new Blob([JSON.stringify(data, null, 2)], {
    type: 'application/json'
  })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = `${props.device.device_id}_monitor_data_${Date.now()}.json`
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  URL.revokeObjectURL(url)
  
  ElMessage.success('数据导出成功')
}

// 格式化数值
const formatValue = (value) => {
  if (typeof value === 'string') return value
  return parseFloat(value).toFixed(1)
}

// 获取数值样式类
const getValueClass = (metric) => {
  if (typeof metric.value === 'string') {
    return metric.value === '正常' ? 'normal' : 'warning'
  }
  return 'normal'
}

// 获取趋势样式类
const getTrendClass = (trend) => {
  return {
    'trend-up': trend === 'up',
    'trend-down': trend === 'down',
    'trend-stable': trend === 'stable'
  }
}

// 获取趋势文本
const getTrendText = (trend) => {
  const texts = {
    up: '上升',
    down: '下降',
    stable: '稳定'
  }
  return texts[trend] || '稳定'
}

// 格式化时间
const formatTime = (timestamp) => {
  return new Date(timestamp).toLocaleTimeString()
}

// 关闭弹窗
const handleClose = () => {
  stopMonitoring()
  visible.value = false
}

// 打开设备详情
const openDeviceDetail = () => {
  emit('openDetail', props.device)
  handleClose()
}

// 监听设备变化
watch(() => props.device, (newDevice) => {
  if (newDevice) {
    initializeMetrics()
    if (isMonitoring.value) {
      stopMonitoring()
    }
  }
}, { immediate: true })

// 监听弹窗显示
watch(visible, (newVisible) => {
  if (newVisible) {
    nextTick(() => {
      initChart()
    })
  } else {
    stopMonitoring()
  }
})

// 组件卸载时清理
onUnmounted(() => {
  stopMonitoring()
  if (chart) {
    chart.dispose()
  }
})
</script>

<style scoped>
.monitor-dialog {
  .el-dialog__body {
    padding: 20px;
  }
}

.monitor-container {
  height: 70vh;
  display: flex;
  flex-direction: column;
}

.device-info-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px;
  background: #f8f9fa;
  border-radius: 8px;
  margin-bottom: 20px;
}

.device-basic h3 {
  margin: 0 0 8px 0;
  color: #303133;
}

.device-tags {
  display: flex;
  gap: 8px;
}

.monitor-controls {
  display: flex;
  gap: 12px;
}

.monitor-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 20px;
  overflow: hidden;
}

.data-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
}

.data-card {
  background: white;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  padding: 16px;
  text-align: center;
  transition: all 0.3s ease;
}

.data-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  transform: translateY(-2px);
}

.metric-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
  font-size: 14px;
  color: #606266;
}

.metric-value {
  font-size: 24px;
  font-weight: bold;
  margin-bottom: 8px;
}

.metric-value.normal {
  color: #67c23a;
}

.metric-value.warning {
  color: #e6a23c;
}

.metric-trend {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  font-size: 12px;
  color: #909399;
}

.trend-up {
  color: #f56c6c;
}

.trend-down {
  color: #409eff;
}

.trend-stable {
  color: #909399;
}

.charts-container {
  flex: 1;
  min-height: 300px;
}

.chart-wrapper {
  height: 100%;
  background: white;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  padding: 16px;
}

.chart-wrapper h4 {
  margin: 0 0 16px 0;
  color: #303133;
}

.chart-content {
  height: calc(100% - 40px);
  min-height: 250px;
}

.logs-container {
  height: 200px;
  background: white;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  padding: 16px;
  display: flex;
  flex-direction: column;
}

.logs-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.logs-header h4 {
  margin: 0;
  color: #303133;
}

.logs-controls {
  display: flex;
  align-items: center;
  gap: 12px;
}

.logs-content {
  flex: 1;
  overflow-y: auto;
  background: #f8f9fa;
  border-radius: 4px;
  padding: 8px;
  font-family: 'Courier New', monospace;
  font-size: 12px;
}

.log-item {
  display: flex;
  gap: 8px;
  padding: 2px 0;
  border-bottom: 1px solid #e4e7ed;
}

.log-item:last-child {
  border-bottom: none;
}

.log-time {
  color: #909399;
  min-width: 80px;
}

.log-level {
  min-width: 50px;
  font-weight: bold;
}

.log-item.info .log-level {
  color: #409eff;
}

.log-item.warning .log-level {
  color: #e6a23c;
}

.log-item.error .log-level {
  color: #f56c6c;
}

.log-message {
  flex: 1;
  color: #303133;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}
</style>