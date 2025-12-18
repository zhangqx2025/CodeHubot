<template>
  <div class="dynamic-device-control">
    <el-card class="control-card" v-if="controlConfig && Object.keys(controlConfig).length > 0">
      <template #header>
        <div class="card-header">
          <span>设备控制</span>
          <el-tag :type="isOnline ? 'success' : 'danger'" size="small">
            {{ isOnline ? '可控制' : '离线' }}
          </el-tag>
        </div>
      </template>
      
      <div class="control-grid">
        <div 
          v-for="(control, key) in controlConfig" 
          :key="key"
          class="control-item"
        >
          <div class="control-header">
            <el-icon class="control-icon">
              <component :is="getControlIcon(control.type)" />
            </el-icon>
            <span class="control-name">{{ control.name || key }}</span>
          </div>
          
          <div class="control-info">
            <el-tag size="small" :type="getControlTypeColor(control.type)">
              {{ getControlTypeText(control.type) }}
            </el-tag>
            <span class="port">GPIO: {{ control.pin }}</span>
          </div>
          
          <!-- 数字输出控制 -->
          <div v-if="control.type === 'digital_output'" class="control-widget">
            <el-switch
              v-model="controlStates[key]"
              :disabled="!isOnline || loading"
              :active-text="control.activeText || '开'"
              :inactive-text="control.inactiveText || '关'"
              @change="handleDigitalControl(key, control)"
            />
          </div>
          
          <!-- PWM控制 -->
          <div v-else-if="control.type === 'pwm'" class="control-widget">
            <div class="pwm-control">
              <el-slider
                v-model="controlStates[key]"
                :min="control.min || 0"
                :max="control.max || 255"
                :step="control.step || 1"
                :disabled="!isOnline || loading"
                @change="handlePwmControl(key, control)"
                show-input
                :show-input-controls="false"
              />
              <div class="pwm-info">
                <span>占空比: {{ getPwmPercentage(key) }}%</span>
              </div>
            </div>
          </div>
          
          <!-- 模拟输出控制 -->
          <div v-else-if="control.type === 'analog_output'" class="control-widget">
            <div class="analog-control">
              <el-input-number
                v-model="controlStates[key]"
                :min="control.min || 0"
                :max="control.max || 1023"
                :step="control.step || 1"
                :precision="control.precision || 0"
                :disabled="!isOnline || loading"
                @change="handleAnalogControl(key, control)"
                size="small"
              />
              <span class="unit">{{ control.unit || 'V' }}</span>
            </div>
          </div>
          
          <!-- 舵机控制 -->
          <div v-else-if="control.type === 'servo'" class="control-widget">
            <div class="servo-control">
              <el-slider
                v-model="controlStates[key]"
                :min="control.min || 0"
                :max="control.max || 180"
                :step="control.step || 1"
                :disabled="!isOnline || loading"
                @change="handleServoControl(key, control)"
                show-input
                :show-input-controls="false"
              />
              <div class="servo-info">
                <span>角度: {{ controlStates[key] }}°</span>
              </div>
            </div>
          </div>
          
          <!-- 控制状态 -->
          <div class="control-status">
            <el-tag 
              v-if="controlStatus[key]"
              :type="controlStatus[key].success ? 'success' : 'danger'"
              size="small"
            >
              {{ controlStatus[key].message }}
            </el-tag>
          </div>
        </div>
      </div>
      
      <!-- 批量控制 -->
      <div class="batch-control" v-if="Object.keys(controlConfig).length > 1">
        <el-divider content-position="left">批量控制</el-divider>
        <div class="batch-buttons">
          <el-button 
            type="primary" 
            size="small"
            :disabled="!isOnline || loading"
            @click="handleBatchControl('all_on')"
          >
            全部开启
          </el-button>
          <el-button 
            type="info" 
            size="small"
            :disabled="!isOnline || loading"
            @click="handleBatchControl('all_off')"
          >
            全部关闭
          </el-button>
          <el-button 
            type="warning" 
            size="small"
            :disabled="!isOnline || loading"
            @click="handleBatchControl('reset')"
          >
            重置状态
          </el-button>
        </div>
      </div>
      
      <!-- 控制配置信息 -->
      <el-collapse v-if="showConfig" class="control-config">
        <el-collapse-item title="控制配置详情" name="config">
          <pre>{{ JSON.stringify(controlConfig, null, 2) }}</pre>
        </el-collapse-item>
      </el-collapse>
    </el-card>
    
    <el-empty v-else description="暂无控制配置" />
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { 
  Switch, 
  Operation, 
  Lightning, 
  Setting,
  VideoPlay,
  Tools
} from '@element-plus/icons-vue'
import { sendDeviceCommand } from '@/api/device'

const props = defineProps({
  deviceId: {
    type: [String, Number],
    required: true
  },
  controlConfig: {
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

const emit = defineEmits(['control-change'])

// 控制状态
const controlStates = reactive({})
const controlStatus = reactive({})
const loading = ref(false)

// 控制图标映射
const controlIconMap = {
  digital_output: Switch,
  pwm: Lightning,
  analog_output: Operation,
  servo: VideoPlay,
  relay: Switch,
  motor: Tools,
  default: Setting
}

// 获取控制图标
const getControlIcon = (controlType) => {
  return controlIconMap[controlType] || controlIconMap.default
}

// 获取控制类型颜色
const getControlTypeColor = (controlType) => {
  const colorMap = {
    digital_output: 'primary',
    pwm: 'warning',
    analog_output: 'success',
    servo: 'info',
    relay: 'primary',
    motor: 'danger'
  }
  return colorMap[controlType] || 'info'
}

// 获取控制类型文本
const getControlTypeText = (controlType) => {
  const textMap = {
    digital_output: '数字输出',
    pwm: 'PWM输出',
    analog_output: '模拟输出',
    servo: '舵机控制',
    relay: '继电器',
    motor: '电机控制'
  }
  return textMap[controlType] || controlType
}

// 获取PWM百分比
const getPwmPercentage = (key) => {
  const control = props.controlConfig[key]
  const value = controlStates[key] || 0
  const max = control?.max || 255
  return Math.round((value / max) * 100)
}

// 初始化控制状态
const initControlStates = () => {
  Object.keys(props.controlConfig).forEach(key => {
    const control = props.controlConfig[key]
    if (control.type === 'digital_output' || control.type === 'relay') {
      controlStates[key] = control.defaultValue || false
    } else {
      controlStates[key] = control.defaultValue || control.min || 0
    }
  })
}

// 发送控制命令
const sendControlCommand = async (controlKey, control, value) => {
  try {
    loading.value = true
    
    const command = {
      type: 'control',
      target: controlKey,
      action: control.type,
      value: value,
      pin: control.pin,
      timestamp: Date.now()
    }
    
    const response = await sendDeviceCommand(props.deviceId, command)
    
    controlStatus[controlKey] = {
      success: true,
      message: '控制成功',
      timestamp: new Date()
    }
    
    emit('control-change', {
      controlKey,
      control,
      value,
      success: true
    })
    
    ElMessage.success(`${control.name || controlKey} 控制成功`)
    
  } catch (error) {
    console.error('控制命令发送失败:', error)
    
    controlStatus[controlKey] = {
      success: false,
      message: '控制失败',
      timestamp: new Date()
    }
    
    emit('control-change', {
      controlKey,
      control,
      value,
      success: false,
      error: error.message
    })
    
    ElMessage.error(`${control.name || controlKey} 控制失败: ${error.message}`)
  } finally {
    loading.value = false
  }
}

// 数字输出控制
const handleDigitalControl = (key, control) => {
  const value = controlStates[key]
  sendControlCommand(key, control, value ? 1 : 0)
}

// PWM控制
const handlePwmControl = (key, control) => {
  const value = controlStates[key]
  sendControlCommand(key, control, value)
}

// 模拟输出控制
const handleAnalogControl = (key, control) => {
  const value = controlStates[key]
  sendControlCommand(key, control, value)
}

// 舵机控制
const handleServoControl = (key, control) => {
  const value = controlStates[key]
  sendControlCommand(key, control, value)
}

// 批量控制
const handleBatchControl = async (action) => {
  try {
    loading.value = true
    
    const commands = []
    
    Object.keys(props.controlConfig).forEach(key => {
      const control = props.controlConfig[key]
      let value
      
      switch (action) {
        case 'all_on':
          if (control.type === 'digital_output' || control.type === 'relay') {
            value = 1
            controlStates[key] = true
          } else if (control.type === 'pwm') {
            value = control.max || 255
            controlStates[key] = value
          }
          break
        case 'all_off':
          if (control.type === 'digital_output' || control.type === 'relay') {
            value = 0
            controlStates[key] = false
          } else if (control.type === 'pwm') {
            value = 0
            controlStates[key] = value
          }
          break
        case 'reset':
          value = control.defaultValue || 0
          controlStates[key] = value
          break
      }
      
      if (value !== undefined) {
        commands.push({
          type: 'control',
          target: key,
          action: control.type,
          value: value,
          pin: control.pin
        })
      }
    })
    
    // 发送批量命令
    const batchCommand = {
      type: 'batch_control',
      commands: commands,
      timestamp: Date.now()
    }
    
    await sendDeviceCommand(props.deviceId, batchCommand)
    
    ElMessage.success('批量控制成功')
    
  } catch (error) {
    console.error('批量控制失败:', error)
    ElMessage.error(`批量控制失败: ${error.message}`)
  } finally {
    loading.value = false
  }
}

// 监听控制配置变化
watch(() => props.controlConfig, () => {
  initControlStates()
}, { immediate: true, deep: true })

onMounted(() => {
  initControlStates()
})
</script>

<style scoped>
.dynamic-device-control {
  width: 100%;
}

.control-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.control-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 16px;
}

.control-item {
  padding: 16px;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
  background: #fafafa;
  transition: all 0.3s ease;
}

.control-item:hover {
  border-color: #409eff;
  box-shadow: 0 2px 8px rgba(64, 158, 255, 0.1);
}

.control-header {
  display: flex;
  align-items: center;
  margin-bottom: 12px;
}

.control-icon {
  font-size: 20px;
  color: #409eff;
  margin-right: 8px;
}

.control-name {
  font-weight: 600;
  color: #303133;
}

.control-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.port {
  font-size: 12px;
  color: #909399;
}

.control-widget {
  margin-bottom: 12px;
}

.pwm-control,
.analog-control,
.servo-control {
  width: 100%;
}

.pwm-info,
.servo-info {
  margin-top: 8px;
  font-size: 12px;
  color: #909399;
  text-align: center;
}

.analog-control {
  display: flex;
  align-items: center;
  gap: 8px;
}

.unit {
  font-size: 12px;
  color: #909399;
}

.control-status {
  margin-top: 8px;
  min-height: 24px;
}

.batch-control {
  margin-top: 20px;
}

.batch-buttons {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.control-config {
  margin-top: 20px;
}

.control-config pre {
  background: #f5f7fa;
  padding: 12px;
  border-radius: 4px;
  font-size: 12px;
  color: #606266;
  overflow-x: auto;
}
</style>