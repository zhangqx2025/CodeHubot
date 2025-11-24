<template>
  <div class="device-detail" v-loading="loading">
    <!-- 设备头部信息 -->
    <div class="device-header">
      <div class="device-info">
        <h1>{{ deviceInfo.name || '设备详情' }}</h1>
        <div class="device-meta">
          <el-tag :type="deviceInfo.is_online ? 'success' : 'danger'" size="large">
            {{ deviceInfo.is_online ? '在线' : '离线' }}
          </el-tag>
          <span class="device-id">ID: {{ deviceInfo.device_id }}</span>
        </div>
      </div>
      <div class="device-actions">
        <el-button @click="goBack">
          <el-icon><ArrowLeft /></el-icon>
          返回
        </el-button>
        <el-button type="primary" @click="editDialogVisible = true">
          <el-icon><Edit /></el-icon>
          编辑设备
        </el-button>
        <el-switch
          v-model="realTimeEnabled"
          active-text="实时数据"
          @change="toggleRealTime"
        />
      </div>
    </div>

    <!-- 设备基本信息 -->
    <DeviceBasicInfo 
      :device-info="deviceInfo" 
      @edit-device="editDialogVisible = true"
    />

    <!-- 实时传感器数据 -->
    <DynamicSensorDisplay 
      v-if="deviceInfo.sensor_config"
      :device-id="deviceInfo.device_id"
      :sensor-config="deviceInfo.sensor_config"
      :sensor-data="realTimeData"
      :real-time-enabled="realTimeEnabled"
    />

    <!-- 设备控制 -->
    <DynamicDeviceControl 
      v-if="deviceInfo.control_config"
      :device-id="deviceInfo.device_id"
      :control-config="deviceInfo.control_config"
      :is-online="deviceInfo.is_online"
      @control-change="handleCommandSent"
    />

    <!-- 固件配置管理 -->
    <FirmwareConfigManager 
      :device-id="deviceInfo.device_id"
      :firmware-version="deviceInfo.firmware_version"
      :hardware-version="deviceInfo.hardware_version"
      :manufacturer="deviceInfo.manufacturer"
      :device-model="deviceInfo.device_model"
      :sensor-config="deviceInfo.sensor_config || {}"
      :control-config="deviceInfo.control_config || {}"
      :device-capabilities="deviceInfo.device_capabilities || {}"
      @config-updated="handleConfigUpdated"
    />

    <!-- 历史数据和日志 -->
    <el-row :gutter="24" style="margin-top: 24px;">
      <!-- 历史数据 -->
      <el-col :xs="24" :lg="12">
        <DeviceHistoryData :device-id="deviceInfo.device_id" />
      </el-col>

      <!-- 设备日志 -->
      <el-col :xs="24" :lg="12">
        <DeviceLogs :device-id="deviceInfo.device_id" />
      </el-col>
    </el-row>

    <!-- 交互数据统计 -->
    <el-row :gutter="24" style="margin-top: 24px;">
      <el-col :span="24">
        <DeviceInteractionStats :device-info="deviceInfo" />
      </el-col>
    </el-row>

    <!-- 编辑设备对话框 -->
    <el-dialog v-model="editDialogVisible" title="编辑设备" width="600px">
      <el-form :model="editForm" :rules="editRules" ref="editFormRef" label-width="100px">
        <el-form-item label="设备名称" prop="name">
          <el-input v-model="editForm.name" placeholder="请输入设备名称" />
        </el-form-item>
        <el-form-item label="设备类型" prop="device_type">
          <el-select v-model="editForm.device_type" placeholder="请选择设备类型">
            <el-option label="温湿度传感器" value="temperature_humidity" />
            <el-option label="压力传感器" value="pressure" />
            <el-option label="光照传感器" value="light" />
            <el-option label="运动传感器" value="motion" />
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
import { ref, reactive, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUserStore } from '../store/user'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ArrowLeft, Edit } from '@element-plus/icons-vue'
import { getDeviceDetail, updateDevice, getDeviceConfig, getDeviceFullConfig } from '@/api/device'

// 导入组件
import DeviceBasicInfo from '../components/device/DeviceBasicInfo.vue'
import DynamicSensorDisplay from '../components/device/DynamicSensorDisplay.vue'
import DynamicDeviceControl from '../components/device/DynamicDeviceControl.vue'
import FirmwareConfigManager from '../components/device/FirmwareConfigManager.vue'
import DeviceHistoryData from '../components/device/DeviceHistoryData.vue'
import DeviceLogs from '../components/device/DeviceLogs.vue'
import DeviceInteractionStats from '../components/device/DeviceInteractionStats.vue'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

// 响应式数据
const loading = ref(false)
const realTimeEnabled = ref(false)
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
  device_capabilities: null
})

// 实时数据
const realTimeData = reactive({
  temperature: '25.6',
  humidity: '65.2',
  pressure: '1013.25',
  light: '450',
  cpu_usage: '15.2',
  memory_usage: '68.5',
  disk_usage: '42.1',
  network_speed: '125.6',
  power_consumption: '12.8',
  vibration: '0.02'
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

// 实时数据更新定时器
let realTimeTimer = null

// 方法
const goBack = () => {
  router.go(-1)
}

const toggleRealTime = (enabled) => {
  if (enabled) {
    startRealTimeUpdate()
  } else {
    stopRealTimeUpdate()
  }
}

const startRealTimeUpdate = () => {
  realTimeTimer = setInterval(() => {
    // 模拟实时数据更新
    realTimeData.temperature = (20 + Math.random() * 15).toFixed(1)
    realTimeData.humidity = (50 + Math.random() * 30).toFixed(1)
    realTimeData.pressure = (1000 + Math.random() * 50).toFixed(2)
    realTimeData.light = Math.floor(300 + Math.random() * 400)
    realTimeData.cpu_usage = (10 + Math.random() * 80).toFixed(1)
    realTimeData.memory_usage = (30 + Math.random() * 60).toFixed(1)
    realTimeData.disk_usage = (20 + Math.random() * 70).toFixed(1)
    realTimeData.network_speed = (50 + Math.random() * 200).toFixed(1)
    realTimeData.power_consumption = (8 + Math.random() * 15).toFixed(1)
    realTimeData.vibration = (Math.random() * 0.1).toFixed(3)
  }, 2000)
}

const stopRealTimeUpdate = () => {
  if (realTimeTimer) {
    clearInterval(realTimeTimer)
    realTimeTimer = null
  }
}

const loadDeviceInfo = async () => {
  loading.value = true
  try {
    const deviceId = route.params.id
    
    // 获取设备基本信息
    const deviceResponse = await getDeviceDetail(deviceId)
    const device = deviceResponse.data
    
    // 获取设备完整配置信息（包括产品配置）
    const configResponse = await getDeviceFullConfig(deviceId)
    const fullConfig = configResponse.data
    
    // 合并设备信息和配置
    Object.assign(deviceInfo, {
      ...device,
      sensor_config: fullConfig.sensor_config || {},
      control_config: fullConfig.control_config || {},
      device_capabilities: fullConfig.device_capabilities || {
        supports_ota: true,
        supports_remote_config: true,
        max_sensors: 8,
        max_controls: 6
      }
    })
    
    // 填充编辑表单
    Object.assign(editForm, {
      name: deviceInfo.name,
      device_type: deviceInfo.device_type,
      location: deviceInfo.location,
      description: deviceInfo.description || ''
    })
    
  } catch (error) {
    ElMessage.error('加载设备信息失败')
  } finally {
    loading.value = false
  }
}

const saveDevice = async () => {
  if (!editFormRef.value) return
  
  try {
    await editFormRef.value.validate()
    saveLoading.value = true
    
    // 模拟保存设备信息
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    // 更新设备信息
    Object.assign(deviceInfo, editForm)
    
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

const handleCommandSent = (command) => {
  ElMessage.success(`命令已发送: ${command.type}`)
}

const handleConfigUpdated = (config) => {
  ElMessage.success('设备配置已更新')
  // 重新加载设备信息
  loadDeviceInfo()
}

// 生命周期
onMounted(() => {
  loadDeviceInfo()
})

onUnmounted(() => {
  stopRealTimeUpdate()
})
</script>

<style scoped>
.device-detail {
  padding: 24px;
  background: #f5f7fa;
  min-height: 100vh;
}

.device-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  padding: 24px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.device-info h1 {
  margin: 0 0 8px 0;
  color: #303133;
  font-size: 24px;
  font-weight: 600;
}

.device-meta {
  display: flex;
  align-items: center;
  gap: 16px;
}

.device-id {
  color: #909399;
  font-size: 14px;
}

.device-actions {
  display: flex;
  gap: 12px;
  align-items: center;
}

@media (max-width: 768px) {
  .device-detail {
    padding: 16px;
  }
  
  .device-header {
    flex-direction: column;
    text-align: center;
    gap: 16px;
  }
  
  .device-actions {
    flex-direction: column;
    width: 100%;
  }
}
</style>
