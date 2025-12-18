<template>
  <el-dialog
    v-model="dialogVisible"
    title="编辑设备信息"
    width="800px"
    :before-close="handleClose"
    destroy-on-close
  >
    <el-form
      ref="formRef"
      :model="formData"
      :rules="formRules"
      label-width="120px"
      label-position="left"
    >
      <el-tabs v-model="activeTab" type="border-card">
        <!-- 基本信息 -->
        <el-tab-pane label="基本信息" name="basic">
          <el-row :gutter="20">
            <el-col :span="12">
              <el-form-item label="设备名称" prop="name">
                <el-input v-model="formData.name" placeholder="请输入设备名称" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="设备类型" prop="device_type">
                <el-select v-model="formData.device_type" placeholder="请选择设备类型">
                  <el-option label="传感器节点" value="sensor_node" />
                  <el-option label="控制器" value="controller" />
                  <el-option label="网关设备" value="gateway" />
                  <el-option label="执行器" value="actuator" />
                  <el-option label="混合设备" value="hybrid" />
                </el-select>
              </el-form-item>
            </el-col>
          </el-row>

          <el-form-item label="设备描述" prop="description">
            <el-input
              v-model="formData.description"
              type="textarea"
              :rows="3"
              placeholder="请输入设备描述"
            />
          </el-form-item>

          <el-row :gutter="20">
            <el-col :span="12">
              <el-form-item label="设备分组" prop="group_name">
                <el-input v-model="formData.group_name" placeholder="请输入设备分组" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="设备位置" prop="location">
                <el-input v-model="formData.location" placeholder="请输入设备位置" />
              </el-form-item>
            </el-col>
          </el-row>
        </el-tab-pane>

        <!-- 硬件信息 -->
        <el-tab-pane label="硬件信息" name="hardware">
          <el-row :gutter="20">
            <el-col :span="12">
              <el-form-item label="制造商" prop="manufacturer">
                <el-input v-model="formData.manufacturer" placeholder="请输入制造商" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="设备型号" prop="model">
                <el-input v-model="formData.model" placeholder="请输入设备型号" />
              </el-form-item>
            </el-col>
          </el-row>

          <el-row :gutter="20">
            <el-col :span="12">
              <el-form-item label="固件版本" prop="firmware_version">
                <el-input v-model="formData.firmware_version" placeholder="请输入固件版本" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="硬件版本" prop="hardware_version">
                <el-input v-model="formData.hardware_version" placeholder="请输入硬件版本" />
              </el-form-item>
            </el-col>
          </el-row>

          <el-row :gutter="20">
            <el-col :span="12">
              <el-form-item label="IP地址" prop="ip_address">
                <el-input v-model="formData.ip_address" placeholder="请输入IP地址" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="MAC地址" prop="mac_address">
                <el-input v-model="formData.mac_address" placeholder="请输入MAC地址" />
              </el-form-item>
            </el-col>
          </el-row>
        </el-tab-pane>

        <!-- 传感器配置 -->
        <el-tab-pane label="传感器配置" name="sensors">
          <div class="config-section">
            <div class="section-header">
              <span>传感器配置</span>
              <el-button @click="addSensor" type="primary" size="small" :icon="Plus">
                添加传感器
              </el-button>
            </div>

            <div v-if="formData.sensor_config.length === 0" class="empty-config">
              <el-empty description="暂无传感器配置" />
            </div>

            <div v-else class="sensor-list">
              <div 
                v-for="(sensor, index) in formData.sensor_config" 
                :key="index"
                class="sensor-item"
              >
                <el-card shadow="hover">
                  <template #header>
                    <div class="sensor-header">
                      <span>传感器 {{ index + 1 }}</span>
                      <el-button @click="removeSensor(index)" type="danger" size="small" :icon="Delete" circle />
                    </div>
                  </template>

                  <el-row :gutter="16">
                    <el-col :span="8">
                      <el-form-item :label="`传感器${index + 1}标识`" :prop="`sensor_config.${index}.key`">
                        <el-input v-model="sensor.key" placeholder="如: temp1" />
                      </el-form-item>
                    </el-col>
                    <el-col :span="8">
                      <el-form-item :label="`传感器${index + 1}名称`" :prop="`sensor_config.${index}.label`">
                        <el-input v-model="sensor.label" placeholder="如: 温度传感器" />
                      </el-form-item>
                    </el-col>
                    <el-col :span="8">
                      <el-form-item :label="`传感器${index + 1}类型`" :prop="`sensor_config.${index}.type`">
                        <el-select v-model="sensor.type" placeholder="选择类型">
                          <el-option label="温度" value="temperature" />
                          <el-option label="湿度" value="humidity" />
                          <el-option label="压力" value="pressure" />
                          <el-option label="光照" value="light" />
                          <el-option label="运动" value="motion" />
                          <el-option label="声音" value="sound" />
                          <el-option label="气体" value="gas" />
                          <el-option label="电压" value="voltage" />
                          <el-option label="电流" value="current" />
                          <el-option label="功率" value="power" />
                        </el-select>
                      </el-form-item>
                    </el-col>
                  </el-row>

                  <el-row :gutter="16">
                    <el-col :span="8">
                      <el-form-item :label="`单位`">
                        <el-input v-model="sensor.unit" placeholder="如: °C, %, V" />
                      </el-form-item>
                    </el-col>
                    <el-col :span="8">
                      <el-form-item :label="`最小值`">
                        <el-input-number v-model="sensor.min_value" :precision="2" />
                      </el-form-item>
                    </el-col>
                    <el-col :span="8">
                      <el-form-item :label="`最大值`">
                        <el-input-number v-model="sensor.max_value" :precision="2" />
                      </el-form-item>
                    </el-col>
                  </el-row>

                  <el-form-item :label="`描述`">
                    <el-input v-model="sensor.description" placeholder="传感器描述" />
                  </el-form-item>
                </el-card>
              </div>
            </div>
          </div>
        </el-tab-pane>

        <!-- 控制配置 -->
        <el-tab-pane label="控制配置" name="controls">
          <div class="config-section">
            <div class="section-header">
              <span>控制端口配置</span>
              <el-button @click="addControl" type="success" size="small" :icon="Plus">
                添加控制端口
              </el-button>
            </div>

            <div v-if="formData.control_config.length === 0" class="empty-config">
              <el-empty description="暂无控制端口配置" />
            </div>

            <div v-else class="control-list">
              <div 
                v-for="(control, index) in formData.control_config" 
                :key="index"
                class="control-item"
              >
                <el-card shadow="hover">
                  <template #header>
                    <div class="control-header">
                      <span>控制端口 {{ index + 1 }}</span>
                      <el-button @click="removeControl(index)" type="danger" size="small" :icon="Delete" circle />
                    </div>
                  </template>

                  <el-row :gutter="16">
                    <el-col :span="8">
                      <el-form-item :label="`端口${index + 1}标识`" :prop="`control_config.${index}.key`">
                        <el-input v-model="control.key" placeholder="如: gpio1" />
                      </el-form-item>
                    </el-col>
                    <el-col :span="8">
                      <el-form-item :label="`端口${index + 1}名称`" :prop="`control_config.${index}.label`">
                        <el-input v-model="control.label" placeholder="如: LED灯" />
                      </el-form-item>
                    </el-col>
                    <el-col :span="8">
                      <el-form-item :label="`控制类型`" :prop="`control_config.${index}.type`">
                        <el-select v-model="control.type" placeholder="选择类型">
                          <el-option label="数字输出" value="digital" />
                          <el-option label="PWM输出" value="pwm" />
                          <el-option label="模拟输出" value="analog" />
                          <el-option label="继电器" value="relay" />
                        </el-select>
                      </el-form-item>
                    </el-col>
                  </el-row>

                  <el-row :gutter="16" v-if="control.type === 'pwm' || control.type === 'analog'">
                    <el-col :span="8">
                      <el-form-item :label="`最小值`">
                        <el-input-number v-model="control.min_value" :precision="2" />
                      </el-form-item>
                    </el-col>
                    <el-col :span="8">
                      <el-form-item :label="`最大值`">
                        <el-input-number v-model="control.max_value" :precision="2" />
                      </el-form-item>
                    </el-col>
                    <el-col :span="8">
                      <el-form-item :label="`默认值`">
                        <el-input-number v-model="control.default_value" :precision="2" />
                      </el-form-item>
                    </el-col>
                  </el-row>

                  <el-form-item :label="`描述`">
                    <el-input v-model="control.description" placeholder="控制端口描述" />
                  </el-form-item>
                </el-card>
              </div>
            </div>
          </div>
        </el-tab-pane>

        <!-- 设备能力 -->
        <el-tab-pane label="设备能力" name="capabilities">
          <el-row :gutter="20">
            <el-col :span="12">
              <el-form-item label="支持协议">
                <el-select v-model="formData.device_capabilities.supported_protocols" multiple placeholder="选择支持的协议">
                  <el-option label="HTTP" value="http" />
                  <el-option label="MQTT" value="mqtt" />
                  <el-option label="WebSocket" value="websocket" />
                  <el-option label="CoAP" value="coap" />
                  <el-option label="LoRa" value="lora" />
                </el-select>
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="数据上传间隔(秒)">
                <el-input-number v-model="formData.device_capabilities.data_upload_interval" :min="1" :max="3600" />
              </el-form-item>
            </el-col>
          </el-row>

          <el-row :gutter="20">
            <el-col :span="12">
              <el-form-item label="最大传感器数">
                <el-input-number v-model="formData.device_capabilities.max_sensors" :min="0" :max="32" />
              </el-form-item>
            </el-col>
            <el-col :span="12">
              <el-form-item label="最大控制端口数">
                <el-input-number v-model="formData.device_capabilities.max_control_ports" :min="0" :max="32" />
              </el-form-item>
            </el-col>
          </el-row>

          <el-form-item label="支持功能">
            <el-checkbox-group v-model="formData.device_capabilities.features">
              <el-checkbox label="ota_update">OTA升级</el-checkbox>
              <el-checkbox label="remote_config">远程配置</el-checkbox>
              <el-checkbox label="data_encryption">数据加密</el-checkbox>
              <el-checkbox label="low_power_mode">低功耗模式</el-checkbox>
              <el-checkbox label="mesh_networking">网状网络</el-checkbox>
              <el-checkbox label="edge_computing">边缘计算</el-checkbox>
            </el-checkbox-group>
          </el-form-item>
        </el-tab-pane>
      </el-tabs>
    </el-form>

    <template #footer>
      <div class="dialog-footer">
        <el-button @click="handleClose">取消</el-button>
        <el-button type="primary" @click="handleSave" :loading="saving">
          保存
        </el-button>
      </div>
    </template>
  </el-dialog>
</template>

<script setup>
import { ref, reactive, watch } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Delete } from '@element-plus/icons-vue'

const props = defineProps({
  visible: {
    type: Boolean,
    default: false
  },
  device: {
    type: Object,
    default: () => ({})
  }
})

const emit = defineEmits(['update:visible', 'save'])

const dialogVisible = ref(false)
const activeTab = ref('basic')
const formRef = ref()
const saving = ref(false)

const formData = reactive({
  name: '',
  device_type: '',
  description: '',
  group_name: '',
  location: '',
  manufacturer: '',
  model: '',
  firmware_version: '',
  hardware_version: '',
  ip_address: '',
  mac_address: '',
  sensor_config: [],
  control_config: [],
  device_capabilities: {
    supported_protocols: [],
    data_upload_interval: 60,
    max_sensors: 8,
    max_control_ports: 8,
    features: []
  }
})

const formRules = {
  name: [
    { required: true, message: '请输入设备名称', trigger: 'blur' }
  ],
  device_type: [
    { required: true, message: '请选择设备类型', trigger: 'change' }
  ]
}

const addSensor = () => {
  formData.sensor_config.push({
    key: '',
    label: '',
    type: '',
    unit: '',
    min_value: 0,
    max_value: 100,
    description: ''
  })
}

const removeSensor = (index) => {
  formData.sensor_config.splice(index, 1)
}

const addControl = () => {
  formData.control_config.push({
    key: '',
    label: '',
    type: 'digital',
    min_value: 0,
    max_value: 100,
    default_value: 0,
    description: ''
  })
}

const removeControl = (index) => {
  formData.control_config.splice(index, 1)
}

const handleClose = () => {
  emit('update:visible', false)
}

const handleSave = async () => {
  try {
    await formRef.value.validate()
    
    saving.value = true
    
    // 模拟保存延迟
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    emit('save', { ...formData })
    ElMessage.success('设备信息保存成功')
    handleClose()
    
  } catch (error) {
    console.error('表单验证失败:', error)
    ElMessage.error('请检查表单填写是否正确')
  } finally {
    saving.value = false
  }
}

const initFormData = () => {
  if (props.device && Object.keys(props.device).length > 0) {
    Object.assign(formData, {
      name: props.device.name || '',
      device_type: props.device.device_type || '',
      description: props.device.description || '',
      group_name: props.device.group_name || '',
      location: props.device.location || '',
      manufacturer: props.device.manufacturer || '',
      model: props.device.model || '',
      firmware_version: props.device.firmware_version || '',
      hardware_version: props.device.hardware_version || '',
      ip_address: props.device.ip_address || '',
      mac_address: props.device.mac_address || '',
      sensor_config: props.device.sensor_config || [],
      control_config: props.device.control_config || [],
      device_capabilities: {
        supported_protocols: props.device.device_capabilities?.supported_protocols || [],
        data_upload_interval: props.device.device_capabilities?.data_upload_interval || 60,
        max_sensors: props.device.device_capabilities?.max_sensors || 8,
        max_control_ports: props.device.device_capabilities?.max_control_ports || 8,
        features: props.device.device_capabilities?.features || []
      }
    })
  }
}

watch(() => props.visible, (newVal) => {
  dialogVisible.value = newVal
  if (newVal) {
    initFormData()
    activeTab.value = 'basic'
  }
})

watch(dialogVisible, (newVal) => {
  if (!newVal) {
    emit('update:visible', false)
  }
})
</script>

<style scoped>
.config-section {
  margin-bottom: 20px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  font-size: 1rem;
  font-weight: 600;
  color: #1e293b;
}

.empty-config {
  padding: 40px 0;
}

.sensor-list, .control-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.sensor-item, .control-item {
  border-radius: 8px;
}

.sensor-header, .control-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-weight: 600;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
}

:deep(.el-tabs__content) {
  padding: 20px 0;
}

:deep(.el-form-item) {
  margin-bottom: 18px;
}

:deep(.el-card__header) {
  padding: 12px 16px;
  background: #f8fafc;
}

:deep(.el-card__body) {
  padding: 16px;
}

@media (max-width: 768px) {
  .el-dialog {
    width: 95% !important;
    margin: 5vh auto;
  }
  
  .el-row {
    flex-direction: column;
  }
  
  .el-col {
    width: 100% !important;
    margin-bottom: 12px;
  }
}
</style>