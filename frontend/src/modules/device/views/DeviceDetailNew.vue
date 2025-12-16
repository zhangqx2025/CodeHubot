<template>
  <div class="device-detail">
    <!-- 设备概览 -->
    <div class="overview-section">
      <DeviceOverview 
        :device="deviceInfo" 
        :loading="loading"
        @edit="handleEdit"
        @refresh="loadDeviceInfo"
        @unbind="handleUnbind"
      />
    </div>

    <!-- 主要内容区域 -->
    <div class="main-content">
      <el-row :gutter="24">
        <!-- 设备基本信息 -->
        <el-col :xs="24" :lg="14">
          <DeviceInfo :device="deviceInfo" />
        </el-col>

        <!-- 设备配置信息 -->
        <el-col :xs="24" :lg="10">
          <DeviceConfigInfo :device="deviceInfo" />
        </el-col>
      </el-row>
    </div>

    <!-- 快速导航区域 -->
    <div class="navigation-section">
      <QuickNavigation :device-id="deviceUuid" />
    </div>

    <!-- 编辑设备对话框 -->
    <DeviceEditDialog
      v-model:visible="editDialogVisible"
      :device="deviceInfo"
      :loading="saveLoading"
      @save="saveDevice"
    />
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'

// 导入子组件
import DeviceOverview from '../components/device/DeviceOverview.vue'
import DeviceInfo from '../components/device/DeviceInfo.vue'
import DeviceConfigInfo from '../components/device/DeviceConfigInfo.vue'
import QuickNavigation from '../components/device/QuickNavigation.vue'
import DeviceEditDialog from '../components/device/DeviceEditDialog.vue'

// 导入API
import { getDevice, updateDevice, getDeviceConfig, unbindDevice } from '../api/device'
import { ElMessageBox } from 'element-plus'

const route = useRoute()
const router = useRouter()

// 响应式数据
const loading = ref(true)
const editDialogVisible = ref(false)
const saveLoading = ref(false)
const deviceUuid = route.params.uuid

// 设备信息
const deviceInfo = reactive({
  id: null,
  device_id: '',
  name: '',
  device_type: '',
  description: '',
  is_online: false,
  last_seen: null,
  firmware_version: '',
  hardware_version: '',
  manufacturer: '',
  model: '',
  ip_address: '',
  mac_address: '',
  location: '',
  group_name: '',
  sensor_config: null,
  control_config: null,
  device_capabilities: null,
  created_at: null,
  updated_at: null
})

// 设置默认配置（用于演示）
const setDefaultConfig = () => {
  deviceInfo.sensor_config = {
    sensors: [
      {
        id: 'temp_01',
        name: '温度传感器',
        type: 'temperature',
        port: 'A0',
        unit: '°C',
        range: { min: -40, max: 85 },
        precision: 1,
        icon: 'thermometer',
        thresholds: {
          warning: { min: 10, max: 35 },
          danger: { min: 0, max: 45 }
        }
      },
      {
        id: 'hum_01',
        name: '湿度传感器',
        type: 'humidity',
        port: 'A1',
        unit: '%',
        range: { min: 0, max: 100 },
        precision: 1,
        icon: 'water',
        thresholds: {
          warning: { min: 30, max: 70 },
          danger: { min: 10, max: 90 }
        }
      }
    ]
  }
  
  deviceInfo.control_config = {
    led_01: {
      name: '状态LED',
      type: 'digital_output',
      pin: 'D2',
      description: '设备状态指示灯',
      icon: 'lightbulb',
      activeText: '开启',
      inactiveText: '关闭'
    },
    fan_01: {
      name: '散热风扇',
      type: 'pwm',
      pin: 'D3',
      description: '设备散热风扇控制',
      icon: 'fan',
      min: 0,
      max: 255,
      unit: 'PWM值'
    }
  }
  
  deviceInfo.device_capabilities = [
    'WiFi通信',
    'MQTT协议',
    'JSON数据格式',
    'TLS加密',
    'OTA固件升级',
    '远程配置',
    '数据记录',
    '实时监控',
    '现代化UI',
    '网格布局'
  ]
}

// 方法
const loadDeviceInfo = async () => {
  try {
    loading.value = true
    const response = await getDevice(deviceUuid)
    
    // 更新设备基本信息
    Object.assign(deviceInfo, response.data)
    
    // 如果没有配置信息，尝试获取配置
    if (!deviceInfo.sensor_config || !deviceInfo.control_config) {
      try {
        const configResponse = await getDeviceConfig(deviceUuid)
        deviceInfo.sensor_config = configResponse.data.sensor_config || {}
        deviceInfo.control_config = configResponse.data.control_config || {}
        deviceInfo.device_capabilities = configResponse.data.device_capabilities || {}
      } catch (configError) {
        console.warn('Failed to load device config:', configError)
        // 使用默认配置作为示例
        setDefaultConfig()
      }
    }
    
  } catch (error) {
    console.error('Failed to load device info:', error)
    ElMessage.error('加载设备信息失败')
    // 使用默认配置作为示例
    setDefaultConfig()
  } finally {
    loading.value = false
  }
}



const handleEdit = () => {
  editDialogVisible.value = true
}

const saveDevice = async (formData) => {
  try {
    saveLoading.value = true
    await updateDevice(deviceUuid, formData)
    
    // 更新设备信息
    Object.assign(deviceInfo, formData)
    
    ElMessage.success('设备信息更新成功')
    editDialogVisible.value = false
  } catch (error) {
    ElMessage.error('保存设备信息失败')
    console.error('Error saving device:', error)
  } finally {
    saveLoading.value = false
  }
}

// 解绑设备
const handleUnbind = async () => {
  try {
    // 确认解绑（自动清除所有历史数据）
    await ElMessageBox.confirm(
      '确定要解绑此设备吗？\n\n⚠️ 解绑后将自动清除所有历史数据（传感器数据、交互日志等），此操作不可恢复。\n\n解绑后设备将不再属于您，其他用户可以重新绑定该设备（重新绑定时会生成新的UUID和密钥）。',
      '解绑设备',
      {
        confirmButtonText: '确认解绑',
        cancelButtonText: '取消',
        type: 'warning',
        distinguishCancelAndClose: true
      }
    )
    
    // 调用解绑API（自动清除所有历史数据）
    saveLoading.value = true
    await unbindDevice(deviceUuid)
    
    ElMessage.success({
      message: '设备解绑成功，所有历史数据已清除',
      duration: 3000
    })
    
    // 延迟跳转到设备列表
    setTimeout(() => {
      router.push('/devices')
    }, 1500)
    
  } catch (error) {
    if (error === 'cancel' || error === 'close') {
      // 用户取消操作
      ElMessage.info('已取消解绑')
      return
    }
    
    console.error('解绑设备失败:', error)
    ElMessage.error(error.response?.data?.detail || '解绑设备失败')
  } finally {
    saveLoading.value = false
  }
}

// 生命周期
onMounted(() => {
  loadDeviceInfo()
})


</script>

<style scoped>
.device-detail {
  padding: 24px;
  background: #f5f7fa;
  min-height: calc(100vh - 60px);
}

.overview-section {
  margin-bottom: 24px;
}

.main-content {
  margin-bottom: 24px;
}

.navigation-section {
  margin-bottom: 24px;
}

@media (max-width: 768px) {
  .device-detail {
    padding: 16px;
  }
  
  .overview-section,
  .main-content,
  .navigation-section {
    margin-bottom: 16px;
  }
}
</style>