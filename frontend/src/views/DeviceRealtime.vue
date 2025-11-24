<template>
  <div class="device-realtime-page">
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
            <el-tag type="info" size="small">{{ device.device_type }}</el-tag>
            <el-tag type="warning" size="small">ID: {{ device.device_id }}</el-tag>
          </div>
        </div>
      </div>
      <div class="header-controls">
        <el-button 
          :type="isMonitoring ? 'danger' : 'success'" 
          @click="toggleMonitoring"
          :loading="connecting"
        >
          <el-icon><VideoPlay v-if="!isMonitoring" /><VideoPause v-else /></el-icon>
          {{ isMonitoring ? '停止监控' : '开始监控' }}
        </el-button>
        <el-button type="primary" @click="exportData">
          <el-icon><Download /></el-icon>
          导出数据
        </el-button>
      </div>
    </div>

    <!-- 主要内容区域 -->
    <div class="page-content" v-if="device">
      <!-- 实时数据卡片 -->
      <div class="data-cards-section">
        <h3>实时数据</h3>
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
      </div>

      <!-- 实时图表 -->
      <div class="charts-section">
        <h3>数据趋势图</h3>
        <div class="chart-wrapper">
          <div ref="chartContainer" class="chart-content"></div>
        </div>
      </div>

      <!-- 实时日志 -->
      <div class="logs-section">
        <div class="logs-header">
          <h3>实时日志</h3>
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

    <!-- 加载状态 -->
    <div v-else class="loading-container">
      <el-loading-directive v-loading="loading" text="加载设备信息中...">
        <div style="height: 200px;"></div>
      </el-loading-directive>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, onUnmounted, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { 
  ArrowLeft,
  VideoPlay, 
  VideoPause, 
  Download, 
  TrendCharts, 
  Bottom, 
  Minus 
} from '@element-plus/icons-vue'
import * as echarts from 'echarts'

const route = useRoute()
const router = useRouter()

// 响应式数据
const device = ref(null)
const loading = ref(true)
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

// 返回设备列表
const goBack = () => {
  router.push('/devices')
}

// 加载设备信息
const loadDevice = async () => {
  try {
    const uuid = route.params.uuid
    if (!uuid) {
      ElMessage.error('设备UUID参数缺失')
      goBack()
      return
    }

    // 模拟API调用获取设备信息
    await new Promise(resolve => setTimeout(resolve, 500))
    
    // 模拟设备数据
    device.value = {
      id: 1,
      uuid: uuid,
      name: '智能温湿度传感器-001',
      device_id: 'TEMP_HUM_001',
      device_type: '温度传感器',
      is_online: true,
      last_seen: new Date().toISOString(),
      description: '用于监测环境温湿度的智能传感器'
    }

    initializeMetrics()
  } catch (error) {
    ElMessage.error('加载设备信息失败')
    console.error('Load device error:', error)
  } finally {
    loading.value = false
  }
}

// 初始化实时指标
const initializeMetrics = () => {
  if (!device.value) return
  
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
  
  realTimeMetrics.value = metricsConfig[device.value.device_type] || [
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
  if (!device.value?.is_online) {
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
      text: '实时数据趋势',
      left: 'center',
      textStyle: {
        fontSize: 16
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
    device: device.value,
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
  link.download = `${device.value.device_id}_realtime_data_${Date.now()}.json`
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

// 组件挂载
onMounted(() => {
  loadDevice()
  nextTick(() => {
    initChart()
  })
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
.device-realtime-page {
  min-height: 100vh;
  background: #f5f7fa;
}

.page-header {
  background: white;
  padding: 20px 24px;
  border-bottom: 1px solid #e4e7ed;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 16px;
}

.back-btn {
  color: #409eff;
  font-size: 14px;
}

.page-title h2 {
  margin: 0 0 8px 0;
  color: #303133;
  font-size: 20px;
}

.device-tags {
  display: flex;
  gap: 8px;
}

.header-controls {
  display: flex;
  gap: 12px;
}

.page-content {
  padding: 24px;
  max-width: 1400px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  gap: 24px;
}

.data-cards-section h3,
.charts-section h3,
.logs-section h3 {
  margin: 0 0 16px 0;
  color: #303133;
  font-size: 18px;
}

.data-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
}

.data-card {
  background: white;
  border: 1px solid #e4e7ed;
  border-radius: 12px;
  padding: 20px;
  text-align: center;
  transition: all 0.3s ease;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.data-card:hover {
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.1);
  transform: translateY(-2px);
}

.metric-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  font-size: 14px;
  color: #606266;
}

.metric-value {
  font-size: 28px;
  font-weight: bold;
  margin-bottom: 12px;
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
  gap: 6px;
  font-size: 13px;
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

.charts-section {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.chart-wrapper {
  height: 400px;
}

.chart-content {
  height: 100%;
  width: 100%;
}

.logs-section {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.logs-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.logs-controls {
  display: flex;
  align-items: center;
  gap: 12px;
}

.logs-content {
  height: 300px;
  overflow-y: auto;
  background: #f8f9fa;
  border-radius: 8px;
  padding: 12px;
  font-family: 'Courier New', monospace;
  font-size: 13px;
}

.log-item {
  display: flex;
  gap: 12px;
  padding: 4px 0;
  border-bottom: 1px solid #e4e7ed;
}

.log-item:last-child {
  border-bottom: none;
}

.log-time {
  color: #909399;
  min-width: 90px;
}

.log-level {
  min-width: 60px;
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

.loading-container {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 50vh;
}
</style>