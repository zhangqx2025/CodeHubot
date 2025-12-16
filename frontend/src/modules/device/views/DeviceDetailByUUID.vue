<template>
  <div class="device-detail-page">
    <!-- 页面头部 -->
    <div class="page-header">
      <div class="header-left">
        <el-button @click="goBack" type="text" class="back-btn">
          <el-icon><ArrowLeft /></el-icon>
          返回设备列表
        </el-button>
        <div class="page-title">
          <h2>{{ deviceInfo.name || '设备详情' }}</h2>
          <div class="device-tags" v-if="deviceInfo.device_id">
            <el-tag :type="deviceInfo.is_online ? 'success' : 'danger'" size="small">
              {{ deviceInfo.is_online ? '在线' : '离线' }}
            </el-tag>
            <el-tag type="info" size="small">{{ deviceInfo.device_type }}</el-tag>
            <el-tag type="warning" size="small">ID: {{ deviceInfo.device_id }}</el-tag>
          </div>
        </div>
      </div>
      <div class="header-controls">
        <el-button @click="goToRealtime" :disabled="!deviceInfo.is_online">
          <el-icon><Monitor /></el-icon>
          实时数据
        </el-button>
        <el-button @click="goToRemoteControl" :disabled="!deviceInfo.is_online">
          <el-icon><Operation /></el-icon>
          远程控制
        </el-button>
        <el-button @click="goToConfig">
          <el-icon><Setting /></el-icon>
          设备配置
        </el-button>
        <el-button type="primary" @click="editDialogVisible = true">
          <el-icon><Edit /></el-icon>
          编辑设备
        </el-button>
      </div>
    </div>

    <!-- 主要内容区域 -->
    <div class="page-content" v-if="!loading">
      <!-- 设备基本信息卡片 -->
      <div class="info-section">
        <h3>基本信息</h3>
        <div class="info-cards">
          <div class="info-card">
            <div class="card-header">
              <el-icon><Cpu /></el-icon>
              <span>设备信息</span>
            </div>
            <div class="card-content">
              <div class="info-item">
                <span class="label">设备名称:</span>
                <span class="value">{{ deviceInfo.name }}</span>
              </div>
              <div class="info-item">
                <span class="label">设备ID:</span>
                <span class="value">{{ deviceInfo.device_id }}</span>
              </div>
              <div class="info-item">
                <span class="label">设备UUID:</span>
                <span class="value">{{ deviceInfo.uuid }}</span>
              </div>
              <div class="info-item">
                <span class="label">设备类型:</span>
                <span class="value">{{ deviceInfo.device_type }}</span>
              </div>
              <div class="info-item">
                <span class="label">制造商:</span>
                <span class="value">{{ deviceInfo.manufacturer }}</span>
              </div>
              <div class="info-item">
                <span class="label">型号:</span>
                <span class="value">{{ deviceInfo.model }}</span>
              </div>
            </div>
          </div>

          <div class="info-card">
            <div class="card-header">
              <el-icon><Connection /></el-icon>
              <span>连接状态</span>
            </div>
            <div class="card-content">
              <div class="info-item">
                <span class="label">在线状态:</span>
                <el-tag :type="deviceInfo.is_online ? 'success' : 'danger'" size="small">
                  {{ deviceInfo.is_online ? '在线' : '离线' }}
                </el-tag>
              </div>
              <div class="info-item">
                <span class="label">最后上线:</span>
                <span class="value">{{ deviceInfo.last_seen }}</span>
              </div>
              <div class="info-item">
                <span class="label">IP地址:</span>
                <span class="value">{{ deviceInfo.ip_address }}</span>
              </div>
              <div class="info-item">
                <span class="label">MAC地址:</span>
                <span class="value">{{ deviceInfo.mac_address }}</span>
              </div>
              <div class="info-item">
                <span class="label">网络状态:</span>
                <el-tag :type="getNetworkStatusType(deviceInfo.network_status)" size="small">
                  {{ getNetworkStatusText(deviceInfo.network_status) }}
                </el-tag>
              </div>
              <div class="info-item">
                <span class="label">信号强度:</span>
                <span class="value">{{ deviceInfo.signal_strength }}%</span>
              </div>
            </div>
          </div>

          <div class="info-card">
            <div class="card-header">
              <el-icon><Tools /></el-icon>
              <span>硬件信息</span>
            </div>
            <div class="card-content">
              <div class="info-item">
                <span class="label">固件版本:</span>
                <span class="value">{{ deviceInfo.firmware_version }}</span>
              </div>
              <div class="info-item">
                <span class="label">硬件版本:</span>
                <span class="value">{{ deviceInfo.hardware_version }}</span>
              </div>
              <div class="info-item" v-if="deviceInfo.battery_level !== undefined">
                <span class="label">电池电量:</span>
                <span class="value">{{ deviceInfo.battery_level }}%</span>
              </div>
              <div class="info-item">
                <span class="label">运行时间:</span>
                <span class="value">{{ formatUptime(deviceInfo.uptime) }}</span>
              </div>
              <div class="info-item">
                <span class="label">设备位置:</span>
                <span class="value">{{ deviceInfo.location }}</span>
              </div>
              <div class="info-item">
                <span class="label">设备组:</span>
                <span class="value">{{ deviceInfo.group_name }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 传感器配置 -->
      <div class="sensor-section" v-if="deviceInfo.sensor_config">
        <h3>传感器配置</h3>
        <div class="sensor-grid">
          <div 
            v-for="(sensor, key) in deviceInfo.sensor_config" 
            :key="key"
            class="sensor-card"
          >
            <div class="sensor-header">
              <span class="sensor-name">{{ getSensorName(key) }}</span>
              <el-tag size="small" type="info">{{ sensor.port }}</el-tag>
            </div>
            <div class="sensor-details">
              <div class="sensor-item">
                <span class="label">类型:</span>
                <span class="value">{{ sensor.type }}</span>
              </div>
              <div class="sensor-item">
                <span class="label">单位:</span>
                <span class="value">{{ sensor.unit }}</span>
              </div>
              <div class="sensor-item">
                <span class="label">范围:</span>
                <span class="value">{{ sensor.min }} ~ {{ sensor.max }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 控制配置 -->
      <div class="control-section" v-if="deviceInfo.control_config">
        <h3>控制配置</h3>
        <div class="control-grid">
          <div 
            v-for="(control, key) in deviceInfo.control_config" 
            :key="key"
            class="control-card"
          >
            <div class="control-header">
              <span class="control-name">{{ control.name }}</span>
              <el-tag size="small" type="warning">{{ control.port }}</el-tag>
            </div>
            <div class="control-details">
              <div class="control-item">
                <span class="label">类型:</span>
                <span class="value">{{ control.type }}</span>
              </div>
              <div class="control-item" v-if="control.min !== undefined">
                <span class="label">范围:</span>
                <span class="value">{{ control.min }} ~ {{ control.max }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 设备能力 -->
      <div class="capabilities-section" v-if="deviceInfo.device_capabilities">
        <h3>设备能力</h3>
        <div class="capabilities-card">
          <div class="capability-item">
            <span class="label">支持OTA升级:</span>
            <el-tag :type="deviceInfo.device_capabilities.supports_ota ? 'success' : 'danger'" size="small">
              {{ deviceInfo.device_capabilities.supports_ota ? '支持' : '不支持' }}
            </el-tag>
          </div>
          <div class="capability-item">
            <span class="label">支持远程配置:</span>
            <el-tag :type="deviceInfo.device_capabilities.supports_remote_config ? 'success' : 'danger'" size="small">
              {{ deviceInfo.device_capabilities.supports_remote_config ? '支持' : '不支持' }}
            </el-tag>
          </div>
          <div class="capability-item">
            <span class="label">最大传感器数:</span>
            <span class="value">{{ deviceInfo.device_capabilities.max_sensors }}</span>
          </div>
          <div class="capability-item">
            <span class="label">最大控制器数:</span>
            <span class="value">{{ deviceInfo.device_capabilities.max_controls }}</span>
          </div>
        </div>
      </div>

      <!-- 时间信息 -->
      <div class="time-section">
        <h3>时间信息</h3>
        <div class="time-card">
          <div class="time-item">
            <span class="label">创建时间:</span>
            <span class="value">{{ deviceInfo.created_at }}</span>
          </div>
          <div class="time-item">
            <span class="label">更新时间:</span>
            <span class="value">{{ deviceInfo.updated_at }}</span>
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

    <!-- 编辑设备对话框 -->
    <el-dialog v-model="editDialogVisible" title="编辑设备" width="600px">
      <el-form :model="editForm" :rules="editRules" ref="editFormRef" label-width="100px">
        <el-form-item label="设备名称" prop="name">
          <el-input v-model="editForm.name" placeholder="请输入设备名称" />
        </el-form-item>
        <el-form-item label="设备类型" prop="device_type">
          <el-select v-model="editForm.device_type" placeholder="请选择设备类型">
            <el-option label="温度传感器" value="温度传感器" />
            <el-option label="湿度传感器" value="湿度传感器" />
            <el-option label="压力传感器" value="压力传感器" />
            <el-option label="光照传感器" value="光照传感器" />
            <el-option label="运动传感器" value="运动传感器" />
            <el-option label="智能开关" value="智能开关" />
          </el-select>
        </el-form-item>
        <el-form-item label="设备位置" prop="location">
          <el-input v-model="editForm.location" placeholder="请输入设备位置" />
        </el-form-item>
        <el-form-item label="设备描述">
          <el-input v-model="editForm.description" type="textarea" rows="3" placeholder="请输入设备描述" />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="editDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="saveDevice" :loading="saveLoading">保存</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { 
  ArrowLeft,
  Edit,
  Monitor,
  Operation,
  Setting,
  Cpu,
  Connection,
  Tools
} from '@element-plus/icons-vue'

const route = useRoute()
const router = useRouter()

// 响应式数据
const loading = ref(true)
const editDialogVisible = ref(false)
const saveLoading = ref(false)
const editFormRef = ref()

// 设备信息
const deviceInfo = reactive({
  id: '',
  device_id: '',
  uuid: '',
  name: '',
  device_type: '',
  manufacturer: '',
  model: '',
  is_online: false,
  last_seen: '',
  firmware_version: '',
  hardware_version: '',
  ip_address: '',
  mac_address: '',
  network_status: 'connected',
  signal_strength: 75,
  battery_level: undefined,
  location: '',
  group_name: '',
  uptime: 0,
  created_at: '',
  updated_at: '',
  sensor_config: null,
  control_config: null,
  device_capabilities: null,
  description: ''
})

// 编辑表单
const editForm = reactive({
  name: '',
  device_type: '',
  location: '',
  description: ''
})

// 编辑表单验证规则
const editRules = {
  name: [
    { required: true, message: '请输入设备名称', trigger: 'blur' }
  ],
  device_type: [
    { required: true, message: '请选择设备类型', trigger: 'change' }
  ],
  location: [
    { required: true, message: '请输入设备位置', trigger: 'blur' }
  ]
}

// 返回设备列表
const goBack = () => {
  router.push('/devices')
}

// 跳转到实时数据页面
const goToRealtime = () => {
  router.push(`/device/${route.params.uuid}/realtime`)
}

// 跳转到远程控制页面
const goToRemoteControl = () => {
  router.push(`/device/${route.params.uuid}/remote-control`)
}

// 跳转到设备配置页面
const goToConfig = () => {
  router.push(`/device/${route.params.uuid}/config`)
}

// 加载设备信息
const loadDeviceInfo = async () => {
  try {
    const uuid = route.params.uuid
    if (!uuid) {
      ElMessage.error('设备UUID参数缺失')
      goBack()
      return
    }

    // 模拟API调用获取设备信息
    await new Promise(resolve => setTimeout(resolve, 500))
    
    // 模拟传感器配置
    const sensorConfig = {
      temperature: { port: 'A0', type: 'analog', unit: '°C', min: -40, max: 85 },
      humidity: { port: 'A1', type: 'analog', unit: '%', min: 0, max: 100 },
      pressure: { port: 'A2', type: 'analog', unit: 'hPa', min: 300, max: 1100 },
      light: { port: 'A3', type: 'analog', unit: 'lux', min: 0, max: 1000 }
    }
    
    // 模拟控制配置
    const controlConfig = {
      led1: { port: 'D2', type: 'digital', name: 'LED灯1' },
      led2: { port: 'D3', type: 'digital', name: 'LED灯2' },
      motor: { port: 'D5', type: 'pwm', name: '电机控制', min: 0, max: 255 },
      servo: { port: 'D6', type: 'servo', name: '舵机', min: 0, max: 180 }
    }
    
    Object.assign(deviceInfo, {
      id: Math.floor(Math.random() * 1000),
      device_id: `DEVICE_${Math.random().toString(36).substr(2, 8).toUpperCase()}`,
      uuid: uuid,
      name: '智能温湿度传感器-001',
      device_type: '温度传感器',
      manufacturer: '智能科技有限公司',
      model: 'TH-2024-Pro',
      is_online: Math.random() > 0.3,
      last_seen: new Date().toLocaleString(),
      firmware_version: 'v2.1.0',
      hardware_version: 'v1.5',
      ip_address: '192.168.1.100',
      mac_address: '00:11:22:33:44:55',
      network_status: ['connected', 'disconnected', 'unstable'][Math.floor(Math.random() * 3)],
      signal_strength: Math.floor(Math.random() * 100),
      battery_level: Math.random() > 0.5 ? Math.floor(Math.random() * 100) : undefined,
      location: '办公室A区-工位001',
      group_name: '环境监测设备组',
      uptime: Math.floor(Math.random() * 86400 * 30),
      created_at: '2023-12-01 10:00:00',
      updated_at: new Date().toLocaleString(),
      sensor_config: sensorConfig,
      control_config: controlConfig,
      device_capabilities: {
        supports_ota: true,
        supports_remote_config: true,
        max_sensors: 8,
        max_controls: 6
      },
      description: '用于监测环境温湿度的智能传感器设备'
    })
    
    // 填充编辑表单
    Object.assign(editForm, {
      name: deviceInfo.name,
      device_type: deviceInfo.device_type,
      location: deviceInfo.location,
      description: deviceInfo.description
    })
    
  } catch (error) {
    ElMessage.error('加载设备信息失败')
    console.error('Load device error:', error)
  } finally {
    loading.value = false
  }
}

// 保存设备信息
const saveDevice = async () => {
  if (!editFormRef.value) return
  
  try {
    await editFormRef.value.validate()
    saveLoading.value = true
    
    // 模拟保存设备信息
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    // 更新设备信息
    Object.assign(deviceInfo, editForm)
    deviceInfo.updated_at = new Date().toLocaleString()
    
    ElMessage.success('设备信息已更新')
    editDialogVisible.value = false
  } catch (error) {
    if (error !== false) { // 不是验证失败
      ElMessage.error('保存设备信息失败')
    }
  } finally {
    saveLoading.value = false
  }
}

// 获取传感器名称
const getSensorName = (key) => {
  const names = {
    temperature: '温度传感器',
    humidity: '湿度传感器',
    pressure: '压力传感器',
    light: '光照传感器'
  }
  return names[key] || key
}

// 获取网络状态类型
const getNetworkStatusType = (status) => {
  const types = {
    connected: 'success',
    disconnected: 'danger',
    unstable: 'warning'
  }
  return types[status] || 'info'
}

// 获取网络状态文本
const getNetworkStatusText = (status) => {
  const texts = {
    connected: '已连接',
    disconnected: '已断开',
    unstable: '不稳定'
  }
  return texts[status] || status
}

// 格式化运行时间
const formatUptime = (seconds) => {
  const days = Math.floor(seconds / 86400)
  const hours = Math.floor((seconds % 86400) / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  
  if (days > 0) {
    return `${days}天 ${hours}小时 ${minutes}分钟`
  } else if (hours > 0) {
    return `${hours}小时 ${minutes}分钟`
  } else {
    return `${minutes}分钟`
  }
}

// 组件挂载
onMounted(() => {
  loadDeviceInfo()
})
</script>

<style scoped>
.device-detail-page {
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

.info-section h3,
.sensor-section h3,
.control-section h3,
.capabilities-section h3,
.time-section h3 {
  margin: 0 0 16px 0;
  color: #303133;
  font-size: 18px;
}

.info-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 20px;
}

.info-card {
  background: white;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
  border: 1px solid #e4e7ed;
}

.card-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 16px;
  font-size: 16px;
  font-weight: 500;
  color: #303133;
}

.card-content {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.info-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.label {
  color: #606266;
  font-size: 14px;
}

.value {
  color: #303133;
  font-size: 14px;
  font-weight: 500;
}

.sensor-grid,
.control-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 16px;
}

.sensor-card,
.control-card {
  background: white;
  border-radius: 8px;
  padding: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
  border: 1px solid #e4e7ed;
}

.sensor-header,
.control-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.sensor-name,
.control-name {
  font-weight: 500;
  color: #303133;
}

.sensor-details,
.control-details {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.sensor-item,
.control-item {
  display: flex;
  justify-content: space-between;
  font-size: 13px;
}

.capabilities-card,
.time-card {
  background: white;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
  border: 1px solid #e4e7ed;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 16px;
}

.capability-item,
.time-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.loading-container {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 50vh;
}

@media (max-width: 768px) {
  .page-header {
    flex-direction: column;
    gap: 16px;
  }
  
  .header-controls {
    flex-wrap: wrap;
    justify-content: center;
  }
  
  .info-cards {
    grid-template-columns: 1fr;
  }
  
  .sensor-grid,
  .control-grid {
    grid-template-columns: 1fr;
  }
  
  .capabilities-card,
  .time-card {
    grid-template-columns: 1fr;
  }
}
</style>