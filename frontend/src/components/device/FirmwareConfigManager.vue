<template>
  <div class="firmware-config-manager">
    <el-card class="config-card">
      <template #header>
        <div class="card-header">
          <span>固件配置管理</span>
          <el-tag :type="getFirmwareStatusType()" size="small">
            {{ firmwareVersion || '未知版本' }}
          </el-tag>
        </div>
      </template>
      
      <!-- 固件信息 -->
      <div class="firmware-info">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="固件版本">
            {{ firmwareVersion || 'N/A' }}
          </el-descriptions-item>
          <el-descriptions-item label="硬件版本">
            {{ hardwareVersion || 'N/A' }}
          </el-descriptions-item>
          <el-descriptions-item label="制造商">
            {{ manufacturer || 'N/A' }}
          </el-descriptions-item>
          <el-descriptions-item label="设备型号">
            {{ deviceModel || 'N/A' }}
          </el-descriptions-item>
          <el-descriptions-item label="支持功能">
            <el-tag 
              v-for="feature in supportedFeatures" 
              :key="feature"
              size="small"
              type="success"
              style="margin-right: 4px;"
            >
              {{ getFeatureLabel(feature) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="配置状态">
            <el-tag :type="isConfigValid ? 'success' : 'warning'">
              {{ isConfigValid ? '配置有效' : '需要更新' }}
            </el-tag>
          </el-descriptions-item>
        </el-descriptions>
      </div>
      
      <!-- 传感器配置 -->
      <div class="sensor-config-section" v-if="sensorConfig">
        <el-divider content-position="left">传感器配置</el-divider>
        <div class="config-grid">
          <div 
            v-for="(sensor, key) in sensorConfig" 
            :key="key"
            class="config-item"
          >
            <div class="config-header">
              <el-icon class="config-icon">
                <component :is="getSensorIcon(sensor.type)" />
              </el-icon>
              <span class="config-name">{{ sensor.name || key }}</span>
              <el-tag size="small" :type="getSensorTypeColor(sensor.type)">
                {{ getSensorTypeText(sensor.type) }}
              </el-tag>
            </div>
            <div class="config-details">
              <div class="detail-item">
                <span class="detail-label">端口:</span>
                <span class="detail-value">{{ sensor.pin || 'N/A' }}</span>
              </div>
              <div class="detail-item" v-if="sensor.unit">
                <span class="detail-label">单位:</span>
                <span class="detail-value">{{ sensor.unit }}</span>
              </div>
              <div class="detail-item" v-if="sensor.range">
                <span class="detail-label">范围:</span>
                <span class="detail-value">{{ sensor.range.min }} - {{ sensor.range.max }}</span>
              </div>
              <div class="detail-item" v-if="sensor.accuracy">
                <span class="detail-label">精度:</span>
                <span class="detail-value">{{ sensor.accuracy }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- 控制配置 -->
      <div class="control-config-section" v-if="controlConfig">
        <el-divider content-position="left">控制配置</el-divider>
        <div class="config-grid">
          <div 
            v-for="(control, key) in controlConfig" 
            :key="key"
            class="config-item"
          >
            <div class="config-header">
              <el-icon class="config-icon">
                <component :is="getControlIcon(control.type)" />
              </el-icon>
              <span class="config-name">{{ control.name || key }}</span>
              <el-tag size="small" :type="getControlTypeColor(control.type)">
                {{ getControlTypeText(control.type) }}
              </el-tag>
            </div>
            <div class="config-details">
              <div class="detail-item">
                <span class="detail-label">GPIO:</span>
                <span class="detail-value">{{ control.pin || 'N/A' }}</span>
              </div>
              <div class="detail-item" v-if="control.type === 'pwm'">
                <span class="detail-label">频率:</span>
                <span class="detail-value">{{ control.frequency || 'N/A' }}Hz</span>
              </div>
              <div class="detail-item" v-if="control.min !== undefined">
                <span class="detail-label">最小值:</span>
                <span class="detail-value">{{ control.min }}</span>
              </div>
              <div class="detail-item" v-if="control.max !== undefined">
                <span class="detail-label">最大值:</span>
                <span class="detail-value">{{ control.max }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- 设备能力 -->
      <div class="capabilities-section" v-if="deviceCapabilities">
        <el-divider content-position="left">设备能力</el-divider>
        <div class="capabilities-grid">
          <div 
            v-for="(capability, key) in deviceCapabilities" 
            :key="key"
            class="capability-item"
          >
            <div class="capability-header">
              <span class="capability-name">{{ getCapabilityLabel(key) }}</span>
              <el-tag :type="capability.enabled ? 'success' : 'info'" size="small">
                {{ capability.enabled ? '支持' : '不支持' }}
              </el-tag>
            </div>
            <div class="capability-details" v-if="capability.enabled && capability.details">
              <div 
                v-for="(detail, detailKey) in capability.details" 
                :key="detailKey"
                class="detail-item"
              >
                <span class="detail-label">{{ detailKey }}:</span>
                <span class="detail-value">{{ detail }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- 固件兼容性检查 -->
      <div class="compatibility-section">
        <el-divider content-position="left">兼容性检查</el-divider>
        <div class="compatibility-results">
          <div 
            v-for="check in compatibilityChecks" 
            :key="check.name"
            class="compatibility-item"
          >
            <div class="check-header">
              <el-icon :color="check.passed ? '#67C23A' : '#F56C6C'">
                <component :is="check.passed ? 'SuccessFilled' : 'WarningFilled'" />
              </el-icon>
              <span class="check-name">{{ check.name }}</span>
              <el-tag :type="check.passed ? 'success' : 'warning'" size="small">
                {{ check.passed ? '通过' : '警告' }}
              </el-tag>
            </div>
            <div class="check-message" v-if="check.message">
              {{ check.message }}
            </div>
          </div>
        </div>
      </div>
      
      <!-- 配置操作 -->
      <div class="config-actions">
        <el-divider content-position="left">配置操作</el-divider>
        <div class="action-buttons">
          <el-button 
            type="primary" 
            :icon="Refresh"
            @click="refreshConfig"
            :loading="loading"
          >
            刷新配置
          </el-button>
          <el-button 
            type="success" 
            :icon="Download"
            @click="exportConfig"
            :disabled="!isConfigValid"
          >
            导出配置
          </el-button>
          <el-button 
            type="warning" 
            :icon="Upload"
            @click="showImportDialog = true"
          >
            导入配置
          </el-button>
          <el-button 
            type="info" 
            :icon="Setting"
            @click="showConfigEditor = true"
          >
            编辑配置
          </el-button>
        </div>
      </div>
    </el-card>
    
    <!-- 配置导入对话框 -->
    <el-dialog
      v-model="showImportDialog"
      title="导入配置"
      width="600px"
    >
      <el-upload
        class="config-upload"
        drag
        :auto-upload="false"
        :on-change="handleConfigImport"
        accept=".json"
      >
        <el-icon class="el-icon--upload"><upload-filled /></el-icon>
        <div class="el-upload__text">
          将配置文件拖到此处，或<em>点击上传</em>
        </div>
        <template #tip>
          <div class="el-upload__tip">
            只能上传 JSON 格式的配置文件
          </div>
        </template>
      </el-upload>
      
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="showImportDialog = false">取消</el-button>
          <el-button type="primary" @click="confirmImport">确定</el-button>
        </span>
      </template>
    </el-dialog>
    
    <!-- 配置编辑器对话框 -->
    <el-dialog
      v-model="showConfigEditor"
      title="配置编辑器"
      width="80%"
      :before-close="handleEditorClose"
    >
      <div class="config-editor">
        <el-tabs v-model="activeTab">
          <el-tab-pane label="传感器配置" name="sensor">
            <el-input
              v-model="editingSensorConfig"
              type="textarea"
              :rows="15"
              placeholder="请输入传感器配置 JSON"
            />
          </el-tab-pane>
          <el-tab-pane label="控制配置" name="control">
            <el-input
              v-model="editingControlConfig"
              type="textarea"
              :rows="15"
              placeholder="请输入控制配置 JSON"
            />
          </el-tab-pane>
          <el-tab-pane label="设备能力" name="capabilities">
            <el-input
              v-model="editingCapabilities"
              type="textarea"
              :rows="15"
              placeholder="请输入设备能力配置 JSON"
            />
          </el-tab-pane>
        </el-tabs>
      </div>
      
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="showConfigEditor = false">取消</el-button>
          <el-button type="primary" @click="saveConfig" :loading="saving">保存</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { 
  Refresh, Download, Upload, Setting,
  SuccessFilled, WarningFilled, UploadFilled,
  Monitor, Operation, Lightning, Switch, VideoPlay, Tools,
  Odometer, Warning
} from '@element-plus/icons-vue'
import { updateDeviceConfig } from '@/api/device'

const props = defineProps({
  deviceId: {
    type: [String, Number],
    required: true
  },
  firmwareVersion: {
    type: String,
    default: ''
  },
  hardwareVersion: {
    type: String,
    default: ''
  },
  manufacturer: {
    type: String,
    default: ''
  },
  deviceModel: {
    type: String,
    default: ''
  },
  sensorConfig: {
    type: Object,
    default: () => ({})
  },
  controlConfig: {
    type: Object,
    default: () => ({})
  },
  deviceCapabilities: {
    type: Object,
    default: () => ({})
  }
})

const emit = defineEmits(['config-updated'])

// 响应式数据
const loading = ref(false)
const saving = ref(false)
const showImportDialog = ref(false)
const showConfigEditor = ref(false)
const activeTab = ref('sensor')
const editingSensorConfig = ref('')
const editingControlConfig = ref('')
const editingCapabilities = ref('')

// 固件版本支持的功能映射
const firmwareFeatures = {
  '1.0.0': ['basic_sensor', 'digital_output'],
  '1.1.0': ['basic_sensor', 'digital_output', 'pwm_output'],
  '1.2.0': ['basic_sensor', 'digital_output', 'pwm_output', 'analog_input'],
  '2.0.0': ['basic_sensor', 'digital_output', 'pwm_output', 'analog_input', 'servo_control'],
  '2.1.0': ['basic_sensor', 'digital_output', 'pwm_output', 'analog_input', 'servo_control', 'wireless_comm'],
  '3.0.0': ['basic_sensor', 'digital_output', 'pwm_output', 'analog_input', 'servo_control', 'wireless_comm', 'advanced_sensor', 'motor_control']
}

// 计算属性
const supportedFeatures = computed(() => {
  return firmwareFeatures[props.firmwareVersion] || []
})

const isConfigValid = computed(() => {
  return props.firmwareVersion && 
         Object.keys(props.sensorConfig).length > 0 && 
         supportedFeatures.value.length > 0
})

const compatibilityChecks = computed(() => {
  const checks = []
  
  // 检查固件版本
  checks.push({
    name: '固件版本检查',
    passed: !!props.firmwareVersion,
    message: props.firmwareVersion ? `当前版本: ${props.firmwareVersion}` : '未检测到固件版本'
  })
  
  // 检查传感器配置
  const sensorCount = Object.keys(props.sensorConfig).length
  checks.push({
    name: '传感器配置检查',
    passed: sensorCount > 0,
    message: sensorCount > 0 ? `配置了 ${sensorCount} 个传感器` : '未配置传感器'
  })
  
  // 检查控制配置
  const controlCount = Object.keys(props.controlConfig).length
  checks.push({
    name: '控制配置检查',
    passed: controlCount > 0,
    message: controlCount > 0 ? `配置了 ${controlCount} 个控制端口` : '未配置控制端口'
  })
  
  // 检查功能兼容性
  const hasIncompatibleFeatures = checkFeatureCompatibility()
  checks.push({
    name: '功能兼容性检查',
    passed: !hasIncompatibleFeatures,
    message: hasIncompatibleFeatures ? '存在不兼容的功能配置' : '所有功能配置兼容'
  })
  
  return checks
})

// 方法
const getFirmwareStatusType = () => {
  if (!props.firmwareVersion) return 'info'
  const version = props.firmwareVersion
  if (version.startsWith('3.')) return 'success'
  if (version.startsWith('2.')) return 'warning'
  return 'info'
}

const getFeatureLabel = (feature) => {
  const labels = {
    'basic_sensor': '基础传感器',
    'digital_output': '数字输出',
    'pwm_output': 'PWM输出',
    'analog_input': '模拟输入',
    'servo_control': '舵机控制',
    'wireless_comm': '无线通信',
    'advanced_sensor': '高级传感器',
    'motor_control': '电机控制'
  }
  return labels[feature] || feature
}

const getSensorIcon = (sensorType) => {
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
    'default': Monitor
  }
  return iconMap[sensorType] || iconMap.default
}

const getSensorTypeColor = (sensorType) => {
  const colorMap = {
    'temperature': 'danger',
    'humidity': 'primary',
    'pressure': 'warning',
    'light': 'success',
    'motion': 'info',
    'gas': 'warning',
    'ph': 'success'
  }
  return colorMap[sensorType] || 'info'
}

const getSensorTypeText = (sensorType) => {
  const textMap = {
    'temperature': '温度传感器',
    'humidity': '湿度传感器',
    'pressure': '压力传感器',
    'light': '光照传感器',
    'motion': '运动传感器',
    'gas': '气体传感器',
    'ph': 'pH传感器'
  }
  return textMap[sensorType] || sensorType
}

const getControlIcon = (controlType) => {
  const iconMap = {
    'digital_output': Switch,
    'pwm': Lightning,
    'analog_output': Operation,
    'servo': VideoPlay,
    'relay': Switch,
    'motor': Tools,
    'default': Setting
  }
  return iconMap[controlType] || iconMap.default
}

const getControlTypeColor = (controlType) => {
  const colorMap = {
    'digital_output': 'primary',
    'pwm': 'warning',
    'analog_output': 'success',
    'servo': 'info',
    'relay': 'primary',
    'motor': 'danger'
  }
  return colorMap[controlType] || 'info'
}

const getControlTypeText = (controlType) => {
  const textMap = {
    'digital_output': '数字输出',
    'pwm': 'PWM输出',
    'analog_output': '模拟输出',
    'servo': '舵机控制',
    'relay': '继电器',
    'motor': '电机控制'
  }
  return textMap[controlType] || controlType
}

const getCapabilityLabel = (capability) => {
  const labels = {
    'wifi': 'WiFi连接',
    'bluetooth': '蓝牙连接',
    'ethernet': '以太网连接',
    'storage': '存储功能',
    'rtc': '实时时钟',
    'watchdog': '看门狗',
    'ota': 'OTA更新',
    'encryption': '数据加密'
  }
  return labels[capability] || capability
}

const checkFeatureCompatibility = () => {
  const currentFeatures = supportedFeatures.value
  
  // 检查传感器配置兼容性
  for (const sensor of Object.values(props.sensorConfig)) {
    if (sensor.type === 'advanced' && !currentFeatures.includes('advanced_sensor')) {
      return true
    }
  }
  
  // 检查控制配置兼容性
  for (const control of Object.values(props.controlConfig)) {
    if (control.type === 'pwm' && !currentFeatures.includes('pwm_output')) {
      return true
    }
    if (control.type === 'servo' && !currentFeatures.includes('servo_control')) {
      return true
    }
    if (control.type === 'motor' && !currentFeatures.includes('motor_control')) {
      return true
    }
  }
  
  return false
}

const refreshConfig = async () => {
  try {
    loading.value = true
    // 这里应该调用API刷新配置
    await new Promise(resolve => setTimeout(resolve, 1000))
    ElMessage.success('配置刷新成功')
    emit('config-updated')
  } catch (error) {
    ElMessage.error('配置刷新失败')
  } finally {
    loading.value = false
  }
}

const exportConfig = () => {
  const config = {
    firmware_version: props.firmwareVersion,
    hardware_version: props.hardwareVersion,
    manufacturer: props.manufacturer,
    device_model: props.deviceModel,
    sensor_config: props.sensorConfig,
    control_config: props.controlConfig,
    device_capabilities: props.deviceCapabilities,
    export_time: new Date().toISOString()
  }
  
  const blob = new Blob([JSON.stringify(config, null, 2)], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `device_${props.deviceId}_config.json`
  a.click()
  URL.revokeObjectURL(url)
  
  ElMessage.success('配置导出成功')
}

const handleConfigImport = (file) => {
  const reader = new FileReader()
  reader.onload = (e) => {
    try {
      const config = JSON.parse(e.target.result)
      // 验证配置格式
      if (config.sensor_config || config.control_config || config.device_capabilities) {
        ElMessage.success('配置文件读取成功')
      } else {
        ElMessage.error('配置文件格式不正确')
      }
    } catch (error) {
      ElMessage.error('配置文件解析失败')
    }
  }
  reader.readAsText(file.raw)
}

const confirmImport = () => {
  showImportDialog.value = false
  ElMessage.success('配置导入成功')
}

const handleEditorClose = (done) => {
  ElMessageBox.confirm('确定要关闭编辑器吗？未保存的更改将丢失。')
    .then(() => {
      done()
    })
    .catch(() => {})
}

const saveConfig = async () => {
  try {
    saving.value = true
    
    const config = {
      sensor_config: JSON.parse(editingSensorConfig.value || '{}'),
      control_config: JSON.parse(editingControlConfig.value || '{}'),
      device_capabilities: JSON.parse(editingCapabilities.value || '{}')
    }
    
    await updateDeviceConfig(props.deviceId, config)
    
    showConfigEditor.value = false
    ElMessage.success('配置保存成功')
    emit('config-updated')
    
  } catch (error) {
    ElMessage.error('配置保存失败: ' + error.message)
  } finally {
    saving.value = false
  }
}

// 监听配置变化，更新编辑器内容
watch(() => [props.sensorConfig, props.controlConfig, props.deviceCapabilities], () => {
  editingSensorConfig.value = JSON.stringify(props.sensorConfig, null, 2)
  editingControlConfig.value = JSON.stringify(props.controlConfig, null, 2)
  editingCapabilities.value = JSON.stringify(props.deviceCapabilities, null, 2)
}, { immediate: true, deep: true })

onMounted(() => {
  // 初始化
})
</script>

<style scoped>
.firmware-config-manager {
  width: 100%;
}

.config-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.firmware-info {
  margin-bottom: 24px;
}

.config-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 16px;
  margin-bottom: 20px;
}

.config-item {
  padding: 16px;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  background: #fafafa;
}

.config-header {
  display: flex;
  align-items: center;
  margin-bottom: 12px;
  gap: 8px;
}

.config-icon {
  font-size: 18px;
  color: #409eff;
}

.config-name {
  font-weight: 600;
  color: #303133;
  flex: 1;
}

.config-details {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.detail-item {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
}

.detail-label {
  color: #909399;
}

.detail-value {
  color: #606266;
  font-weight: 500;
}

.capabilities-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
  gap: 12px;
  margin-bottom: 20px;
}

.capability-item {
  padding: 12px;
  border: 1px solid #e4e7ed;
  border-radius: 6px;
  background: #f9f9f9;
}

.capability-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.capability-name {
  font-weight: 500;
  color: #303133;
}

.capability-details {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.compatibility-results {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-bottom: 20px;
}

.compatibility-item {
  padding: 12px;
  border: 1px solid #e4e7ed;
  border-radius: 6px;
  background: #f9f9f9;
}

.check-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}

.check-name {
  font-weight: 500;
  color: #303133;
  flex: 1;
}

.check-message {
  font-size: 12px;
  color: #909399;
  margin-left: 24px;
}

.action-buttons {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

.config-upload {
  margin: 20px 0;
}

.config-editor {
  height: 400px;
}

.config-editor .el-textarea {
  height: 100%;
}

.config-editor .el-textarea__inner {
  height: 100% !important;
  font-family: 'Courier New', monospace;
  font-size: 12px;
}
</style>