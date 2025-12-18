<template>
  <el-dialog
    v-model="visible"
    :title="`${device?.name || '设备'} - 远程控制`"
    width="70%"
    :before-close="handleClose"
    class="control-dialog"
  >
    <div class="control-container" v-if="device">
      <!-- 设备状态信息 -->
      <div class="device-status-header">
        <div class="status-info">
          <h3>{{ device.name }}</h3>
          <div class="status-indicators">
            <div class="status-item">
              <span class="status-label">连接状态:</span>
              <el-tag :type="device.is_online ? 'success' : 'danger'" size="small">
                {{ device.is_online ? '在线' : '离线' }}
              </el-tag>
            </div>
            <div class="status-item">
              <span class="status-label">设备类型:</span>
              <el-tag type="info" size="small">{{ device.device_type }}</el-tag>
            </div>
            <div class="status-item">
              <span class="status-label">最后响应:</span>
              <span class="status-value">{{ lastResponseTime || '暂无' }}</span>
            </div>
          </div>
        </div>
        <div class="connection-controls">
          <el-button 
            :type="isConnected ? 'danger' : 'success'" 
            size="small"
            @click="toggleConnection"
            :loading="connecting"
            :disabled="!device.is_online"
          >
            <el-icon><Link v-if="!isConnected" /><Close v-else /></el-icon>
            {{ isConnected ? '断开连接' : '建立连接' }}
          </el-button>
        </div>
      </div>

      <!-- 控制面板 -->
      <div class="control-content">
        <!-- 快速控制按钮 -->
        <div class="quick-controls">
          <h4>快速控制</h4>
          <div class="control-buttons">
            <el-button
              v-for="command in quickCommands"
              :key="command.name"
              :type="command.type"
              size="large"
              @click="executeCommand(command)"
              :disabled="!isConnected"
              :loading="command.loading"
              class="control-btn"
            >
              <el-icon>
                <component :is="command.icon" />
              </el-icon>
              {{ command.label }}
            </el-button>
          </div>
        </div>

        <!-- 参数控制 -->
        <div class="parameter-controls" v-if="parameterControls.length > 0">
          <h4>参数设置</h4>
          <div class="parameter-grid">
            <div 
              v-for="param in parameterControls" 
              :key="param.key"
              class="parameter-item"
            >
              <label class="parameter-label">{{ param.label }}</label>
              
              <!-- 滑块控制 -->
              <div v-if="param.type === 'slider'" class="parameter-control">
                <el-slider
                  v-model="param.value"
                  :min="param.min"
                  :max="param.max"
                  :step="param.step"
                  :disabled="!isConnected"
                  @change="updateParameter(param)"
                  show-input
                />
                <span class="parameter-unit">{{ param.unit }}</span>
              </div>
              
              <!-- 开关控制 -->
              <div v-else-if="param.type === 'switch'" class="parameter-control">
                <el-switch
                  v-model="param.value"
                  :disabled="!isConnected"
                  @change="updateParameter(param)"
                  :active-text="param.activeText"
                  :inactive-text="param.inactiveText"
                />
              </div>
              
              <!-- 选择器控制 -->
              <div v-else-if="param.type === 'select'" class="parameter-control">
                <el-select
                  v-model="param.value"
                  :disabled="!isConnected"
                  @change="updateParameter(param)"
                  style="width: 100%"
                >
                  <el-option
                    v-for="option in param.options"
                    :key="option.value"
                    :label="option.label"
                    :value="option.value"
                  />
                </el-select>
              </div>
              
              <!-- 数值输入 -->
              <div v-else-if="param.type === 'number'" class="parameter-control">
                <el-input-number
                  v-model="param.value"
                  :min="param.min"
                  :max="param.max"
                  :step="param.step"
                  :disabled="!isConnected"
                  @change="updateParameter(param)"
                  style="width: 100%"
                />
                <span class="parameter-unit">{{ param.unit }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- 自定义指令 -->
        <div class="custom-commands">
          <h4>自定义指令</h4>
          <div class="command-input">
            <el-input
              v-model="customCommand"
              placeholder="输入自定义指令 (JSON格式)"
              type="textarea"
              :rows="3"
              :disabled="!isConnected"
            />
            <div class="command-actions">
              <el-button 
                type="primary" 
                @click="sendCustomCommand"
                :disabled="!isConnected || !customCommand.trim()"
                :loading="sendingCommand"
              >
                <el-icon><Promotion /></el-icon>
                发送指令
              </el-button>
              <el-button @click="clearCommand">清空</el-button>
            </div>
          </div>
        </div>

        <!-- 指令历史 -->
        <div class="command-history">
          <div class="history-header">
            <h4>指令历史</h4>
            <el-button size="small" @click="clearHistory">清空历史</el-button>
          </div>
          <div class="history-content" ref="historyContainer">
            <div 
              v-for="record in commandHistory" 
              :key="record.id"
              class="history-item"
              :class="record.status"
            >
              <div class="history-time">{{ formatTime(record.timestamp) }}</div>
              <div class="history-command">{{ record.command }}</div>
              <div class="history-status">
                <el-tag 
                  :type="record.status === 'success' ? 'success' : 'danger'" 
                  size="small"
                >
                  {{ record.status === 'success' ? '成功' : '失败' }}
                </el-tag>
              </div>
              <div class="history-response" v-if="record.response">
                {{ record.response }}
              </div>
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
import { ref, reactive, computed, watch, nextTick, onUnmounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { 
  Link, 
  Close, 
  Promotion,
  VideoPlay,
  VideoPause,
  Switch,
  Setting,
  Refresh,
  Warning,
  Check
} from '@element-plus/icons-vue'

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

const isConnected = ref(false)
const connecting = ref(false)
const sendingCommand = ref(false)
const lastResponseTime = ref('')
const customCommand = ref('')
const historyContainer = ref(null)

// 快速控制指令
const quickCommands = ref([])

// 参数控制
const parameterControls = ref([])

// 指令历史
const commandHistory = ref([])

// 初始化控制配置
const initializeControls = () => {
  if (!props.device) return
  
  const deviceType = props.device.device_type
  
  // 根据设备类型配置快速控制按钮
  const commandsConfig = {
    '温度传感器': [
      { name: 'read_temp', label: '读取温度', type: 'primary', icon: 'Refresh', loading: false },
      { name: 'calibrate', label: '校准传感器', type: 'warning', icon: 'Setting', loading: false },
      { name: 'reset', label: '重置设备', type: 'danger', icon: 'Warning', loading: false }
    ],
    '湿度传感器': [
      { name: 'read_humidity', label: '读取湿度', type: 'primary', icon: 'Refresh', loading: false },
      { name: 'calibrate', label: '校准传感器', type: 'warning', icon: 'Setting', loading: false },
      { name: 'reset', label: '重置设备', type: 'danger', icon: 'Warning', loading: false }
    ],
    '压力传感器': [
      { name: 'read_pressure', label: '读取压力', type: 'primary', icon: 'Refresh', loading: false },
      { name: 'calibrate', label: '校准传感器', type: 'warning', icon: 'Setting', loading: false },
      { name: 'zero_adjust', label: '零点调整', type: 'info', icon: 'Check', loading: false },
      { name: 'reset', label: '重置设备', type: 'danger', icon: 'Warning', loading: false }
    ],
    '智能开关': [
      { name: 'turn_on', label: '打开', type: 'success', icon: 'VideoPlay', loading: false },
      { name: 'turn_off', label: '关闭', type: 'danger', icon: 'VideoPause', loading: false },
      { name: 'toggle', label: '切换', type: 'primary', icon: 'Switch', loading: false }
    ]
  }
  
  quickCommands.value = commandsConfig[deviceType] || [
    { name: 'status', label: '获取状态', type: 'primary', icon: 'Refresh', loading: false }
  ]
  
  // 根据设备类型配置参数控制
  const parametersConfig = {
    '温度传感器': [
      {
        key: 'threshold_min',
        label: '最低温度阈值',
        type: 'slider',
        value: 0,
        min: -50,
        max: 50,
        step: 0.1,
        unit: '°C'
      },
      {
        key: 'threshold_max',
        label: '最高温度阈值',
        type: 'slider',
        value: 40,
        min: 0,
        max: 100,
        step: 0.1,
        unit: '°C'
      },
      {
        key: 'sampling_rate',
        label: '采样频率',
        type: 'select',
        value: 1000,
        options: [
          { label: '1秒', value: 1000 },
          { label: '5秒', value: 5000 },
          { label: '10秒', value: 10000 },
          { label: '30秒', value: 30000 }
        ]
      }
    ],
    '湿度传感器': [
      {
        key: 'threshold_min',
        label: '最低湿度阈值',
        type: 'slider',
        value: 30,
        min: 0,
        max: 100,
        step: 1,
        unit: '%'
      },
      {
        key: 'threshold_max',
        label: '最高湿度阈值',
        type: 'slider',
        value: 80,
        min: 0,
        max: 100,
        step: 1,
        unit: '%'
      }
    ],
    '压力传感器': [
      {
        key: 'threshold_min',
        label: '最低压力阈值',
        type: 'number',
        value: 1000,
        min: 0,
        max: 10000,
        step: 10,
        unit: 'Pa'
      },
      {
        key: 'threshold_max',
        label: '最高压力阈值',
        type: 'number',
        value: 5000,
        min: 0,
        max: 10000,
        step: 10,
        unit: 'Pa'
      },
      {
        key: 'auto_calibrate',
        label: '自动校准',
        type: 'switch',
        value: true,
        activeText: '开启',
        inactiveText: '关闭'
      }
    ],
    '智能开关': [
      {
        key: 'auto_mode',
        label: '自动模式',
        type: 'switch',
        value: false,
        activeText: '开启',
        inactiveText: '关闭'
      },
      {
        key: 'delay_time',
        label: '延时时间',
        type: 'slider',
        value: 0,
        min: 0,
        max: 60,
        step: 1,
        unit: '秒'
      }
    ]
  }
  
  parameterControls.value = parametersConfig[deviceType] || []
}

// 建立/断开连接
const toggleConnection = async () => {
  if (isConnected.value) {
    disconnectDevice()
  } else {
    await connectDevice()
  }
}

// 连接设备
const connectDevice = async () => {
  if (!props.device?.is_online) {
    ElMessage.warning('设备离线，无法建立连接')
    return
  }
  
  connecting.value = true
  
  try {
    // 模拟连接过程
    await new Promise(resolve => setTimeout(resolve, 1500))
    
    isConnected.value = true
    lastResponseTime.value = new Date().toLocaleString()
    
    addCommandRecord('connect', '建立连接', 'success', '连接成功')
    ElMessage.success('设备连接成功')
  } catch (error) {
    addCommandRecord('connect', '建立连接', 'error', '连接失败')
    ElMessage.error('设备连接失败')
    console.error('Connect device error:', error)
  } finally {
    connecting.value = false
  }
}

// 断开连接
const disconnectDevice = () => {
  isConnected.value = false
  lastResponseTime.value = ''
  
  addCommandRecord('disconnect', '断开连接', 'success', '已断开连接')
  ElMessage.info('设备连接已断开')
}

// 执行快速指令
const executeCommand = async (command) => {
  if (!isConnected.value) {
    ElMessage.warning('请先建立设备连接')
    return
  }
  
  command.loading = true
  
  try {
    // 模拟指令执行
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    const responses = {
      'read_temp': '当前温度: 23.5°C',
      'read_humidity': '当前湿度: 65%',
      'read_pressure': '当前压力: 1013Pa',
      'calibrate': '校准完成',
      'zero_adjust': '零点调整完成',
      'turn_on': '设备已打开',
      'turn_off': '设备已关闭',
      'toggle': '状态已切换',
      'reset': '设备已重置',
      'status': '设备状态正常'
    }
    
    const response = responses[command.name] || '指令执行成功'
    
    addCommandRecord(command.name, command.label, 'success', response)
    lastResponseTime.value = new Date().toLocaleString()
    
    ElMessage.success(response)
  } catch (error) {
    addCommandRecord(command.name, command.label, 'error', '指令执行失败')
    ElMessage.error('指令执行失败')
    console.error('Execute command error:', error)
  } finally {
    command.loading = false
  }
}

// 更新参数
const updateParameter = async (param) => {
  if (!isConnected.value) {
    ElMessage.warning('请先建立设备连接')
    return
  }
  
  try {
    // 模拟参数更新
    await new Promise(resolve => setTimeout(resolve, 500))
    
    const commandText = `设置${param.label}: ${param.value}${param.unit || ''}`
    addCommandRecord('set_param', commandText, 'success', '参数更新成功')
    lastResponseTime.value = new Date().toLocaleString()
    
    ElMessage.success('参数更新成功')
  } catch (error) {
    addCommandRecord('set_param', `设置${param.label}`, 'error', '参数更新失败')
    ElMessage.error('参数更新失败')
    console.error('Update parameter error:', error)
  }
}

// 发送自定义指令
const sendCustomCommand = async () => {
  if (!isConnected.value) {
    ElMessage.warning('请先建立设备连接')
    return
  }
  
  if (!customCommand.value.trim()) {
    ElMessage.warning('请输入指令内容')
    return
  }
  
  sendingCommand.value = true
  
  try {
    // 验证JSON格式
    let commandObj
    try {
      commandObj = JSON.parse(customCommand.value)
    } catch (e) {
      throw new Error('指令格式错误，请使用有效的JSON格式')
    }
    
    // 模拟指令发送
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    addCommandRecord('custom', customCommand.value, 'success', '自定义指令执行成功')
    lastResponseTime.value = new Date().toLocaleString()
    
    ElMessage.success('自定义指令执行成功')
    customCommand.value = ''
  } catch (error) {
    addCommandRecord('custom', customCommand.value, 'error', error.message)
    ElMessage.error(error.message || '自定义指令执行失败')
    console.error('Send custom command error:', error)
  } finally {
    sendingCommand.value = false
  }
}

// 清空指令
const clearCommand = () => {
  customCommand.value = ''
}

// 添加指令记录
const addCommandRecord = (type, command, status, response) => {
  const record = {
    id: Date.now() + Math.random(),
    timestamp: new Date(),
    type,
    command,
    status,
    response
  }
  
  commandHistory.value.unshift(record)
  
  // 只保留最近50条记录
  if (commandHistory.value.length > 50) {
    commandHistory.value = commandHistory.value.slice(0, 50)
  }
  
  // 滚动到顶部显示最新记录
  nextTick(() => {
    if (historyContainer.value) {
      historyContainer.value.scrollTop = 0
    }
  })
}

// 清空历史
const clearHistory = () => {
  commandHistory.value = []
  ElMessage.success('指令历史已清空')
}

// 格式化时间
const formatTime = (timestamp) => {
  return new Date(timestamp).toLocaleString()
}

// 关闭弹窗
const handleClose = () => {
  if (isConnected.value) {
    ElMessageBox.confirm('设备仍处于连接状态，确定要关闭控制面板吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    }).then(() => {
      disconnectDevice()
      visible.value = false
    }).catch(() => {
      // 用户取消
    })
  } else {
    visible.value = false
  }
}

// 打开设备详情
const openDeviceDetail = () => {
  emit('openDetail', props.device)
  handleClose()
}

// 监听设备变化
watch(() => props.device, (newDevice) => {
  if (newDevice) {
    initializeControls()
    if (isConnected.value) {
      disconnectDevice()
    }
  }
}, { immediate: true })

// 组件卸载时清理
onUnmounted(() => {
  if (isConnected.value) {
    disconnectDevice()
  }
})
</script>

<style scoped>
.control-dialog {
  .el-dialog__body {
    padding: 20px;
  }
}

.control-container {
  height: 70vh;
  display: flex;
  flex-direction: column;
}

.device-status-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px;
  background: #f8f9fa;
  border-radius: 8px;
  margin-bottom: 20px;
}

.status-info h3 {
  margin: 0 0 12px 0;
  color: #303133;
}

.status-indicators {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
}

.status-item {
  display: flex;
  align-items: center;
  gap: 8px;
}

.status-label {
  font-size: 14px;
  color: #606266;
}

.status-value {
  font-size: 14px;
  color: #303133;
}

.connection-controls {
  display: flex;
  gap: 12px;
}

.control-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 24px;
  overflow-y: auto;
}

.quick-controls h4,
.parameter-controls h4,
.custom-commands h4,
.command-history h4 {
  margin: 0 0 16px 0;
  color: #303133;
  font-size: 16px;
  border-bottom: 2px solid #e4e7ed;
  padding-bottom: 8px;
}

.control-buttons {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 12px;
}

.control-btn {
  height: 60px;
  font-size: 14px;
  border-radius: 8px;
  transition: all 0.3s ease;
}

.control-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.control-btn .el-icon {
  margin-right: 8px;
  font-size: 16px;
}

.parameter-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
}

.parameter-item {
  background: white;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  padding: 16px;
}

.parameter-label {
  display: block;
  margin-bottom: 12px;
  font-weight: 500;
  color: #303133;
}

.parameter-control {
  display: flex;
  align-items: center;
  gap: 12px;
}

.parameter-unit {
  font-size: 14px;
  color: #909399;
  min-width: 30px;
}

.command-input {
  background: white;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  padding: 16px;
}

.command-actions {
  display: flex;
  gap: 12px;
  margin-top: 12px;
  justify-content: flex-end;
}

.command-history {
  background: white;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  padding: 16px;
}

.history-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.history-content {
  max-height: 300px;
  overflow-y: auto;
}

.history-item {
  display: grid;
  grid-template-columns: 120px 1fr 80px;
  gap: 12px;
  padding: 12px;
  border-bottom: 1px solid #f0f0f0;
  font-size: 14px;
}

.history-item:last-child {
  border-bottom: none;
}

.history-item.success {
  background: #f0f9ff;
}

.history-item.error {
  background: #fef0f0;
}

.history-time {
  color: #909399;
  font-size: 12px;
}

.history-command {
  color: #303133;
  word-break: break-all;
}

.history-status {
  display: flex;
  justify-content: center;
}

.history-response {
  grid-column: 1 / -1;
  color: #606266;
  font-size: 12px;
  background: #f8f9fa;
  padding: 8px;
  border-radius: 4px;
  margin-top: 8px;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}
</style>