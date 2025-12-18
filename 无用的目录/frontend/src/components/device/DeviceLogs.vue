<template>
  <div class="device-logs">
    <el-card class="logs-card" shadow="hover">
      <template #header>
        <div class="card-header">
          <el-icon size="20" color="#909399"><Document /></el-icon>
          <span>设备日志</span>
          <div class="card-actions">
            <el-select 
              v-model="logLevelFilter" 
              placeholder="日志级别" 
              size="small" 
              style="width: 100px; margin-right: 8px;"
              @change="filterLogs"
            >
              <el-option label="全部" value="all" />
              <el-option label="错误" value="error" />
              <el-option label="警告" value="warning" />
              <el-option label="信息" value="info" />
              <el-option label="调试" value="debug" />
            </el-select>
            <el-input
              v-model="logSearchKeyword"
              placeholder="搜索日志"
              size="small"
              style="width: 120px; margin-right: 8px;"
              @input="filterLogs"
              clearable
            >
              <template #prefix>
                <el-icon><Search /></el-icon>
              </template>
            </el-input>
            <el-button size="small" type="text" @click="refreshLogs">
              <el-icon><Refresh /></el-icon>
              刷新
            </el-button>
            <el-button size="small" type="text" @click="exportLogs">
              <el-icon><Download /></el-icon>
              导出
            </el-button>
          </div>
        </div>
      </template>
      <div class="device-logs-content">
        <div class="logs-container" style="max-height: 300px; overflow-y: auto;">
          <div 
            class="log-item" 
            v-for="log in filteredLogs" 
            :key="log.id"
            :class="['log-level-' + log.level]"
          >
            <div class="log-header">
              <div class="log-time">{{ formatLogTime(log.timestamp) }}</div>
              <el-tag 
                :type="getLogLevelType(log.level)" 
                size="small"
                class="log-level-tag"
              >
                {{ getLogLevelText(log.level) }}
              </el-tag>
            </div>
            <div class="log-content">
              <div class="log-message" v-html="highlightSearchKeyword(log.message)"></div>
              <div class="log-source" v-if="log.source">
                <el-icon><Location /></el-icon>
                {{ log.source }}
              </div>
            </div>
          </div>
          <div v-if="filteredLogs.length === 0" class="empty-logs">
            <el-empty description="暂无日志数据" :image-size="80" />
          </div>
        </div>
        <div class="logs-footer" style="margin-top: 12px; text-align: center;">
          <el-text size="small" type="info">
            共 {{ filteredLogs.length }} 条日志
            <span v-if="logSearchKeyword || logLevelFilter !== 'all'">
              (已筛选，原始: {{ deviceLogs.length }} 条)
            </span>
          </el-text>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Document, Search, Refresh, Download, Location } from '@element-plus/icons-vue'

// Props
const props = defineProps({
  deviceId: {
    type: String,
    required: true
  }
})

// 响应式数据
const deviceLogs = ref([])
const logLevelFilter = ref('all')
const logSearchKeyword = ref('')

// 计算属性
const filteredLogs = computed(() => {
  let logs = deviceLogs.value
  
  // 按级别筛选
  if (logLevelFilter.value !== 'all') {
    logs = logs.filter(log => log.level === logLevelFilter.value)
  }
  
  // 按关键词搜索
  if (logSearchKeyword.value) {
    const keyword = logSearchKeyword.value.toLowerCase()
    logs = logs.filter(log => 
      log.message.toLowerCase().includes(keyword) ||
      (log.source && log.source.toLowerCase().includes(keyword))
    )
  }
  
  return logs
})

// 方法
const loadDeviceLogs = async () => {
  try {
    // 模拟加载设备日志
    const logMessages = [
      { level: 'info', message: '设备数据上报成功', source: 'DataCollector' },
      { level: 'warning', message: '温度传感器读数异常，当前值: 45.2°C', source: 'TempSensor' },
      { level: 'info', message: '设备连接正常，信号强度: 85%', source: 'NetworkManager' },
      { level: 'error', message: '网络连接超时，重试中...', source: 'NetworkManager' },
      { level: 'info', message: '设备启动完成，版本: v2.1.3', source: 'SystemCore' },
      { level: 'debug', message: 'CPU使用率: 15.2%, 内存使用率: 68.5%', source: 'SystemMonitor' },
      { level: 'warning', message: '磁盘空间不足，剩余: 2.1GB', source: 'StorageManager' },
      { level: 'info', message: '固件检查完成，当前为最新版本', source: 'FirmwareManager' },
      { level: 'error', message: '传感器校准失败，请检查硬件连接', source: 'CalibrationService' },
      { level: 'info', message: '配置文件已更新', source: 'ConfigManager' },
      { level: 'debug', message: '心跳包发送成功，延迟: 25ms', source: 'HeartbeatService' },
      { level: 'warning', message: '电池电量低于20%，请及时充电', source: 'PowerManager' }
    ]
    
    const logs = []
    for (let i = 0; i < 15; i++) {
      const randomLog = logMessages[Math.floor(Math.random() * logMessages.length)]
      const time = new Date(Date.now() - i * 3 * 60 * 1000) // 每3分钟一条日志
      logs.push({
        id: i + 1,
        timestamp: time.toISOString(),
        level: randomLog.level,
        message: randomLog.message,
        source: randomLog.source
      })
    }
    
    deviceLogs.value = logs
  } catch (error) {
    ElMessage.error('加载设备日志失败')
  }
}

const filterLogs = () => {
  // 触发计算属性重新计算
}

const refreshLogs = () => {
  loadDeviceLogs()
  ElMessage.success('日志已刷新')
}

const exportLogs = () => {
  ElMessage.info('导出功能开发中...')
}

const formatLogTime = (timestamp) => {
  return new Date(timestamp).toLocaleString('zh-CN', {
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  })
}

const getLogLevelType = (level) => {
  const typeMap = {
    'error': 'danger',
    'warning': 'warning',
    'info': 'info',
    'debug': 'info'
  }
  return typeMap[level] || 'info'
}

const getLogLevelText = (level) => {
  const textMap = {
    'error': '错误',
    'warning': '警告',
    'info': '信息',
    'debug': '调试'
  }
  return textMap[level] || level
}

const highlightSearchKeyword = (text) => {
  if (!logSearchKeyword.value) return text
  
  const keyword = logSearchKeyword.value
  const regex = new RegExp(`(${keyword})`, 'gi')
  return text.replace(regex, '<mark>$1</mark>')
}

// 生命周期
onMounted(() => {
  loadDeviceLogs()
})
</script>

<style scoped>
.device-logs {
  height: 100%;
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-weight: 600;
}

.card-header span {
  margin-left: 8px;
  flex: 1;
}

.card-actions {
  display: flex;
  gap: 8px;
  align-items: center;
}

.device-logs-content {
  padding: 0;
}

.logs-container {
  border: 1px solid #f0f0f0;
  border-radius: 4px;
  background: #fafafa;
}

.log-item {
  padding: 12px;
  border-bottom: 1px solid #f0f0f0;
  transition: background-color 0.2s;
}

.log-item:hover {
  background-color: #f5f7fa;
}

.log-item:last-child {
  border-bottom: none;
}

.log-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.log-time {
  font-size: 12px;
  color: #909399;
  font-family: monospace;
}

.log-level-tag {
  font-size: 10px;
}

.log-content {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.log-message {
  font-size: 14px;
  line-height: 1.4;
  color: #303133;
}

.log-message :deep(mark) {
  background-color: #fff2cc;
  padding: 1px 2px;
  border-radius: 2px;
}

.log-source {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: #909399;
}

.log-level-error {
  border-left: 3px solid #F56C6C;
}

.log-level-warning {
  border-left: 3px solid #E6A23C;
}

.log-level-info {
  border-left: 3px solid #409EFF;
}

.log-level-debug {
  border-left: 3px solid #909399;
}

.empty-logs {
  padding: 40px 0;
  text-align: center;
}

@media (max-width: 768px) {
  .card-actions {
    flex-direction: column;
    gap: 4px;
  }
  
  .card-actions .el-select,
  .card-actions .el-input {
    width: 100% !important;
  }
  
  .log-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 4px;
  }
}
</style>