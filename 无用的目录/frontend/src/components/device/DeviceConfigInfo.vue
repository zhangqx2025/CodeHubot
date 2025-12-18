<template>
  <el-card class="device-config-card" :class="getDeviceThemeClass()">
    <template #header>
      <div class="card-header">
        <div class="header-left">
          <el-icon class="device-type-icon" :class="getDeviceIconClass()">
            <component :is="getDeviceTypeIcon()" />
          </el-icon>
          <div>
            <span class="device-title">{{ device?.name || '设备配置信息' }}</span>
            <p class="device-type">{{ device?.device_type }}</p>
          </div>
        </div>
        <el-tag :type="device?.is_online ? 'success' : 'danger'" size="small">
          {{ device?.is_online ? '在线' : '离线' }}
        </el-tag>
      </div>
    </template>

    <el-tabs v-model="activeTab" class="config-tabs">
      <!-- 传感器配置 -->
      <el-tab-pane label="传感器配置" name="sensors">
        <div v-if="sensorConfig?.length > 0" class="config-list">
          <div 
            v-for="sensor in sensorConfig" 
            :key="sensor.id"
            class="config-item sensor-item"
            :class="getSensorItemClass(sensor.type)"
          >
            <div class="config-header">
              <div class="icon-wrapper" :class="getSensorIconClass(sensor.type)">
                <el-icon class="config-icon">
                  <component :is="getSensorIcon(sensor.type)" />
                </el-icon>
              </div>
              <div class="config-info">
                <h4>{{ sensor.name }}</h4>
                <p class="config-detail">
                  <el-tag size="small" type="info">{{ sensor.port }}</el-tag>
                  <span class="separator">|</span>
                  <span class="sensor-type">{{ getSensorTypeText(sensor.type) }}</span>
                  <span class="separator">|</span>
                  <span class="unit">{{ sensor.unit }}</span>
                </p>
              </div>
            </div>
            <div class="config-specs">
              <el-tag size="small" :type="getSensorRangeTagType(sensor)">
                测量范围: {{ sensor.range?.min }}-{{ sensor.range?.max }}{{ sensor.unit }}
              </el-tag>
              <el-tag size="small" type="warning" v-if="sensor.precision">
                精度: {{ sensor.precision }}位
              </el-tag>
              <!-- 阈值显示 -->
              <div v-if="sensor.thresholds" class="thresholds">
                <el-tag size="small" type="warning" v-if="sensor.thresholds.warning">
                  警告: {{ sensor.thresholds.warning.min }}-{{ sensor.thresholds.warning.max }}{{ sensor.unit }}
                </el-tag>
                <el-tag size="small" type="danger" v-if="sensor.thresholds.danger">
                  危险: {{ sensor.thresholds.danger.min }}-{{ sensor.thresholds.danger.max }}{{ sensor.unit }}
                </el-tag>
              </div>
            </div>
          </div>
        </div>
        <el-empty v-else description="暂无传感器配置" />
      </el-tab-pane>

      <!-- 控制配置 -->
      <el-tab-pane label="控制配置" name="controls">
        <div v-if="controlConfig && Object.keys(controlConfig).length > 0" class="config-list">
          <div 
            v-for="(control, key) in controlConfig" 
            :key="key"
            class="config-item control-item"
            :class="getControlItemClass(control.type)"
          >
            <div class="config-header">
              <div class="icon-wrapper" :class="getControlIconClass(control.type)">
                <el-icon class="config-icon">
                  <component :is="getControlIcon(control.type)" />
                </el-icon>
              </div>
              <div class="config-info">
                <h4>{{ control.name }}</h4>
                <p class="config-detail">
                  <el-tag size="small" type="success">{{ control.pin }}</el-tag>
                  <span class="separator">|</span>
                  <span class="control-type">{{ getControlTypeText(control.type) }}</span>
                </p>
                <p class="config-description">{{ control.description }}</p>
              </div>
            </div>
            <div class="config-specs">
              <el-tag size="small" :type="getControlTypeTag(control.type)">
                {{ getControlCategoryText(control.type) }}
              </el-tag>
              <el-tag size="small" type="info" v-if="control.min !== undefined">
                范围: {{ control.min }}-{{ control.max }}
              </el-tag>
            </div>
          </div>
        </div>
        <el-empty v-else description="暂无控制配置" />
      </el-tab-pane>

      <!-- 设备能力 -->
      <el-tab-pane label="设备能力" name="capabilities">
        <div v-if="deviceCapabilities?.length > 0" class="capabilities-grid">
          <div 
            v-for="capability in deviceCapabilities" 
            :key="capability"
            class="capability-item"
            :class="getCapabilityClass(capability)"
          >
            <el-icon class="capability-icon">
              <component :is="getCapabilityIcon(capability)" />
            </el-icon>
            <span class="capability-text">{{ capability }}</span>
          </div>
        </div>
        <el-empty v-else description="暂无设备能力信息" />
      </el-tab-pane>
    </el-tabs>
  </el-card>
</template>

<script setup>
import { ref, computed } from 'vue'
import { 
  Sunny, 
  Lightning,
  Setting,
  Monitor,



  Warning,
  Tools,
  Connection,


  CirclePlus,
  Star,
  Trophy,
  Cpu,
  VideoCamera,
  Microphone
} from '@element-plus/icons-vue'

const props = defineProps({
  device: {
    type: Object,
    default: () => ({})
  }
})

const activeTab = ref('sensors')

// 计算属性
const sensorConfig = computed(() => {
  return props.device?.sensor_config?.sensors || []
})

const controlConfig = computed(() => {
  return props.device?.control_config || {}
})

const deviceCapabilities = computed(() => {
  return props.device?.device_capabilities || []
})

// 获取设备类型图标
const getDeviceTypeIcon = () => {
  const deviceType = props.device?.device_type
  if (deviceType?.includes('工业')) return Setting
  if (deviceType?.includes('农业')) return Star
  if (deviceType?.includes('医疗')) return Star
  return Monitor
}

// 获取设备主题类
const getDeviceThemeClass = () => {
  const deviceType = props.device?.device_type
  if (deviceType?.includes('工业')) return 'industrial-theme'
  if (deviceType?.includes('农业')) return 'agricultural-theme'
  if (deviceType?.includes('医疗')) return 'medical-theme'
  return 'default-theme'
}

// 获取设备图标类
const getDeviceIconClass = () => {
  const deviceType = props.device?.device_type
  if (deviceType?.includes('工业')) return 'industrial-icon'
  if (deviceType?.includes('农业')) return 'agricultural-icon'
  if (deviceType?.includes('医疗')) return 'medical-icon'
  return 'default-icon'
}

// 获取传感器图标
const getSensorIcon = (type) => {
  const iconMap = {
    temperature: Warning,
    humidity: Star,
    pressure: Warning,
    vibration: Lightning,
    current: Lightning,
    soil_moisture: Star,
    light_intensity: Sunny,
    wind_speed: Star,
    ph: Monitor,
    air_quality: Monitor,
    noise: Microphone,
    uv: Sunny,
    pm25: Monitor,
    light: Sunny,
    motion: Lightning,
    co2: Monitor
  }
  return iconMap[type] || Monitor
}

// 获取传感器图标类
const getSensorIconClass = (type) => {
  const classMap = {
    temperature: 'temperature-icon',
    humidity: 'humidity-icon',
    pressure: 'pressure-icon',
    vibration: 'vibration-icon',
    current: 'current-icon',
    soil_moisture: 'soil-icon',
    light_intensity: 'light-icon',
    wind_speed: 'wind-icon',
    ph: 'ph-icon',
    air_quality: 'air-icon',
    noise: 'noise-icon',
    uv: 'uv-icon'
  }
  return classMap[type] || 'default-sensor-icon'
}

// 获取传感器项目类
const getSensorItemClass = (type) => {
  const classMap = {
    temperature: 'temperature-item',
    humidity: 'humidity-item',
    pressure: 'pressure-item',
    vibration: 'vibration-item',
    current: 'current-item',
    soil_moisture: 'soil-item',
    light_intensity: 'light-item',
    wind_speed: 'wind-item',
    ph: 'ph-item',
    air_quality: 'air-item',
    noise: 'noise-item',
    uv: 'uv-item'
  }
  return classMap[type] || 'default-sensor-item'
}

// 获取传感器类型文本
const getSensorTypeText = (type) => {
  const textMap = {
    temperature: '温度传感器',
    humidity: '湿度传感器',
    pressure: '压力传感器',
    vibration: '振动传感器',
    current: '电流传感器',
    soil_moisture: '土壤湿度',
    light_intensity: '光照强度',
    wind_speed: '风速传感器',
    ph: 'pH传感器',
    air_quality: '空气质量',
    noise: '噪音传感器',
    uv: '紫外线传感器'
  }
  return textMap[type] || type
}

// 获取传感器范围标签类型
const getSensorRangeTagType = (sensor) => {
  const range = sensor.range?.max - sensor.range?.min
  if (range > 1000) return 'primary'
  if (range > 100) return 'success'
  return 'info'
}

// 获取控制设备图标
const getControlIcon = (type) => {
  const iconMap = {
    heater: Warning,
    valve: Setting,
    motor: Setting,
    irrigation: Star,
    fertilizer: Star,
    shade: House,
    air_purifier: Star,
    humidifier: Star,
    uv_sterilizer: Sunny
  }
  return iconMap[type] || Tools
}

// 获取控制设备图标类
const getControlIconClass = (type) => {
  const classMap = {
    heater: 'heater-icon',
    valve: 'valve-icon',
    motor: 'motor-icon',
    irrigation: 'irrigation-icon',
    fertilizer: 'fertilizer-icon',
    shade: 'shade-icon',
    air_purifier: 'air-purifier-icon',
    humidifier: 'humidifier-icon',
    uv_sterilizer: 'uv-sterilizer-icon'
  }
  return classMap[type] || 'default-control-icon'
}

// 获取控制项目类
const getControlItemClass = (type) => {
  const classMap = {
    heater: 'heater-item',
    valve: 'valve-item',
    motor: 'motor-item',
    irrigation: 'irrigation-item',
    fertilizer: 'fertilizer-item',
    shade: 'shade-item',
    air_purifier: 'air-purifier-item',
    humidifier: 'humidifier-item',
    uv_sterilizer: 'uv-sterilizer-item'
  }
  return classMap[type] || 'default-control-item'
}

// 获取控制类型标签颜色
const getControlTypeTag = (type) => {
  const tagMap = {
    heater: 'danger',
    valve: 'warning',
    motor: 'primary',
    irrigation: 'success',
    fertilizer: 'warning',
    shade: 'info',
    air_purifier: 'success',
    humidifier: 'primary',
    uv_sterilizer: 'warning',
    digital_output: 'success',
    pwm: 'warning',
    servo: 'info'
  }
  return tagMap[type] || 'primary'
}

// 获取控制类型文本
const getControlTypeText = (type) => {
  const textMap = {
    heater: '加热设备',
    valve: '阀门控制',
    motor: '电机驱动',
    irrigation: '灌溉系统',
    fertilizer: '施肥系统',
    shade: '遮阳控制',
    air_purifier: '空气净化',
    humidifier: '湿度控制',
    uv_sterilizer: '紫外消毒',
    digital_output: '开关控制',
    pwm: 'PWM调节',
    servo: '舵机控制'
  }
  return textMap[type] || type
}

// 获取控制分类文本
const getControlCategoryText = (type) => {
  const textMap = {
    heater: '工业控制',
    valve: '工业控制',
    motor: '工业控制',
    irrigation: '农业控制',
    fertilizer: '农业控制',
    shade: '农业控制',
    air_purifier: '医疗控制',
    humidifier: '医疗控制',
    uv_sterilizer: '医疗控制',
    digital_output: '数字输出',
    pwm: 'PWM控制',
    servo: '伺服控制'
  }
  return textMap[type] || '通用控制'
}

// 获取设备能力图标
const getCapabilityIcon = (capability) => {
  const iconMap = {
    '高温作业': Warning,
    '压力监控': Warning,
    '振动分析': Lightning,
    '电流保护': Lightning,
    '智能灌溉': Star,
    '光照调节': Sunny,
    '土壤分析': Monitor,
    '气象监测': Star,
    '生命体征监测': Star,
    '环境净化': Star,
    '紫外线消毒': Sunny,
    '噪音控制': Microphone,
    '数据记录': Monitor,
    '远程控制': Connection,
    '实时监控': VideoCamera,
    '报警系统': Warning,
    '太阳能供电': CirclePlus,
    'LoRa通信': Connection,
    '防水防尘': Star,
    '低功耗设计': CirclePlus,
    '远程监控': VideoCamera,
    '自动控制': Setting,
    '数据分析': Monitor,
    '云端同步': Connection,
    '智能算法': Star,
    '预测维护': Tools,
    '能耗优化': CirclePlus,
    '故障诊断': Tools,
    '历史数据': Monitor,
    '趋势分析': Monitor
  }
  return iconMap[capability] || Star
}

// 获取设备能力类
const getCapabilityClass = (capability) => {
  if (capability.includes('工业') || capability.includes('高温') || capability.includes('Modbus')) {
    return 'industrial-capability'
  }
  if (capability.includes('农业') || capability.includes('太阳能') || capability.includes('LoRa') || capability.includes('低功耗')) {
    return 'agricultural-capability'
  }
  if (capability.includes('医疗') || capability.includes('认证') || capability.includes('消毒')) {
    return 'medical-capability'
  }
  return 'default-capability'
}
</script>

<style scoped>
.device-config-card {
  height: 100%;
  transition: all 0.3s ease;
}

/* 设备主题样式 */
.industrial-theme {
  border-left: 4px solid #ff6b35;
}

.agricultural-theme {
  border-left: 4px solid #4caf50;
}

.medical-theme {
  border-left: 4px solid #2196f3;
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

.device-type-icon {
  font-size: 28px;
  padding: 8px;
  border-radius: 8px;
}

.industrial-icon {
  color: #ff6b35;
  background: rgba(255, 107, 53, 0.1);
}

.agricultural-icon {
  color: #4caf50;
  background: rgba(76, 175, 80, 0.1);
}

.medical-icon {
  color: #2196f3;
  background: rgba(33, 150, 243, 0.1);
}

.device-title {
  font-size: 18px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.device-type {
  margin: 2px 0 0 0;
  font-size: 12px;
  color: var(--el-text-color-secondary);
}

.config-tabs {
  height: 450px;
  overflow-y: auto;
}

.config-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.config-item {
  padding: 16px;
  border: 1px solid var(--el-border-color-light);
  border-radius: 12px;
  background: var(--el-bg-color-page);
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
}

.config-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.config-header {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  margin-bottom: 12px;
}

.icon-wrapper {
  padding: 8px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.config-icon {
  font-size: 20px;
}

/* 传感器图标样式 */
.temperature-icon { background: rgba(255, 87, 34, 0.1); color: #ff5722; }
.humidity-icon { background: rgba(33, 150, 243, 0.1); color: #2196f3; }
.pressure-icon { background: rgba(255, 193, 7, 0.1); color: #ffc107; }
.vibration-icon { background: rgba(156, 39, 176, 0.1); color: #9c27b0; }
.current-icon { background: rgba(255, 235, 59, 0.1); color: #ffeb3b; }
.soil-icon { background: rgba(121, 85, 72, 0.1); color: #795548; }
.light-icon { background: rgba(255, 193, 7, 0.1); color: #ffc107; }
.wind-icon { background: rgba(96, 125, 139, 0.1); color: #607d8b; }
.ph-icon { background: rgba(76, 175, 80, 0.1); color: #4caf50; }
.air-icon { background: rgba(158, 158, 158, 0.1); color: #9e9e9e; }
.noise-icon { background: rgba(233, 30, 99, 0.1); color: #e91e63; }
.uv-icon { background: rgba(255, 152, 0, 0.1); color: #ff9800; }

/* 控制设备图标样式 */
.heater-icon { background: rgba(244, 67, 54, 0.1); color: #f44336; }
.valve-icon { background: rgba(96, 125, 139, 0.1); color: #607d8b; }
.motor-icon { background: rgba(63, 81, 181, 0.1); color: #3f51b5; }
.irrigation-icon { background: rgba(33, 150, 243, 0.1); color: #2196f3; }
.fertilizer-icon { background: rgba(139, 195, 74, 0.1); color: #8bc34a; }
.shade-icon { background: rgba(121, 85, 72, 0.1); color: #795548; }
.air-purifier-icon { background: rgba(0, 188, 212, 0.1); color: #00bcd4; }
.humidifier-icon { background: rgba(33, 150, 243, 0.1); color: #2196f3; }
.uv-sterilizer-icon { background: rgba(255, 152, 0, 0.1); color: #ff9800; }

.config-info h4 {
  margin: 0 0 6px 0;
  font-size: 16px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.config-detail {
  margin: 0 0 6px 0;
  font-size: 13px;
  color: var(--el-text-color-regular);
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.separator {
  color: var(--el-text-color-placeholder);
  margin: 0 4px;
}

.sensor-type, .control-type {
  font-weight: 500;
}

.unit {
  font-weight: 600;
  color: var(--el-color-primary);
}

.config-description {
  margin: 0;
  font-size: 12px;
  color: var(--el-text-color-secondary);
  font-style: italic;
}

.config-specs {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  align-items: flex-start;
}

.thresholds {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  margin-top: 4px;
}

/* 设备能力网格布局 */
.capabilities-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
}

.capability-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  border-radius: 8px;
  transition: all 0.3s ease;
  cursor: pointer;
}

.capability-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.industrial-capability {
  background: linear-gradient(135deg, rgba(255, 107, 53, 0.1), rgba(255, 107, 53, 0.05));
  border: 1px solid rgba(255, 107, 53, 0.2);
}

.agricultural-capability {
  background: linear-gradient(135deg, rgba(76, 175, 80, 0.1), rgba(76, 175, 80, 0.05));
  border: 1px solid rgba(76, 175, 80, 0.2);
}

.medical-capability {
  background: linear-gradient(135deg, rgba(33, 150, 243, 0.1), rgba(33, 150, 243, 0.05));
  border: 1px solid rgba(33, 150, 243, 0.2);
}

.default-capability {
  background: linear-gradient(135deg, rgba(158, 158, 158, 0.1), rgba(158, 158, 158, 0.05));
  border: 1px solid rgba(158, 158, 158, 0.2);
}

.capability-icon {
  font-size: 20px;
  color: var(--el-color-primary);
}

.capability-text {
  font-size: 14px;
  font-weight: 500;
  color: var(--el-text-color-primary);
}

/* 传感器项目特殊样式 */
.temperature-item { border-left: 3px solid #ff5722; }
.humidity-item { border-left: 3px solid #2196f3; }
.pressure-item { border-left: 3px solid #ffc107; }
.vibration-item { border-left: 3px solid #9c27b0; }
.current-item { border-left: 3px solid #ffeb3b; }
.soil-item { border-left: 3px solid #795548; }
.light-item { border-left: 3px solid #ffc107; }
.wind-item { border-left: 3px solid #607d8b; }
.ph-item { border-left: 3px solid #4caf50; }
.air-item { border-left: 3px solid #9e9e9e; }
.noise-item { border-left: 3px solid #e91e63; }
.uv-item { border-left: 3px solid #ff9800; }

/* 控制项目特殊样式 */
.heater-item { border-left: 3px solid #f44336; }
.valve-item { border-left: 3px solid #607d8b; }
.motor-item { border-left: 3px solid #3f51b5; }
.irrigation-item { border-left: 3px solid #2196f3; }
.fertilizer-item { border-left: 3px solid #8bc34a; }
.shade-item { border-left: 3px solid #795548; }
.air-purifier-item { border-left: 3px solid #00bcd4; }
.humidifier-item { border-left: 3px solid #2196f3; }
.uv-sterilizer-item { border-left: 3px solid #ff9800; }

/* 响应式设计 */
@media (max-width: 768px) {
  .capabilities-grid {
    grid-template-columns: 1fr;
  }
  
  .config-detail {
    flex-direction: column;
    align-items: flex-start;
    gap: 4px;
  }
  
  .separator {
    display: none;
  }
}
</style>