<template>
  <el-card class="device-info-card" shadow="hover">
    <template #header>
      <div class="card-header">
        <div class="header-left">
          <el-icon size="20" color="#409EFF"><InfoFilled /></el-icon>
          <span class="header-title">设备信息</span>
        </div>
        <div class="header-actions">
          <el-button @click="$emit('edit')" :icon="Edit" size="small" type="primary">
            编辑
          </el-button>
        </div>
      </div>
    </template>

    <div class="info-grid">
      <!-- 基本信息 -->
      <div class="info-section">
        <h4 class="section-title">基本信息</h4>
        <div class="info-items">
          <div class="info-item">
            <div class="info-label">设备名称</div>
            <div class="info-value">{{ device.name || 'N/A' }}</div>
          </div>
          <div class="info-item">
            <div class="info-label">设备ID</div>
            <div class="info-value code">{{ device.device_id || 'N/A' }}</div>
          </div>
          <div class="info-item">
            <div class="info-label">设备类型</div>
            <div class="info-value">
              <el-tag type="info">{{ getDeviceTypeLabel(device.device_type) }}</el-tag>
            </div>
          </div>
          <div class="info-item">
            <div class="info-label">设备描述</div>
            <div class="info-value">{{ device.description || '无描述' }}</div>
          </div>
          <div class="info-item">
            <div class="info-label">设备分组</div>
            <div class="info-value">
              <el-tag v-if="device.group_name" type="success">{{ device.group_name }}</el-tag>
              <span v-else class="text-muted">未分组</span>
            </div>
          </div>
        </div>
      </div>

      <!-- 硬件信息 -->
      <div class="info-section">
        <h4 class="section-title">硬件信息</h4>
        <div class="info-items">
          <div class="info-item">
            <div class="info-label">制造商</div>
            <div class="info-value">{{ device.manufacturer || 'N/A' }}</div>
          </div>
          <div class="info-item">
            <div class="info-label">设备型号</div>
            <div class="info-value">{{ device.model || 'N/A' }}</div>
          </div>
          <div class="info-item">
            <div class="info-label">固件版本</div>
            <div class="info-value code">{{ device.firmware_version || 'N/A' }}</div>
          </div>
          <div class="info-item">
            <div class="info-label">硬件版本</div>
            <div class="info-value code">{{ device.hardware_version || 'N/A' }}</div>
          </div>
        </div>
      </div>

      <!-- 网络信息 -->
      <div class="info-section">
        <h4 class="section-title">网络信息</h4>
        <div class="info-items">
          <div class="info-item">
            <div class="info-label">IP地址</div>
            <div class="info-value code">{{ device.ip_address || 'N/A' }}</div>
          </div>
          <div class="info-item">
            <div class="info-label">MAC地址</div>
            <div class="info-value code">{{ device.mac_address || 'N/A' }}</div>
          </div>
          <div class="info-item">
            <div class="info-label">连接状态</div>
            <div class="info-value">
              <el-tag :type="device.is_online ? 'success' : 'danger'">
                {{ device.is_online ? '在线' : '离线' }}
              </el-tag>
            </div>
          </div>
          <div class="info-item">
            <div class="info-label">最后在线</div>
            <div class="info-value">{{ formatDateTime(device.last_seen) }}</div>
          </div>
        </div>
      </div>

      <!-- 位置信息 -->
      <div class="info-section">
        <h4 class="section-title">位置信息</h4>
        <div class="info-items">
          <div class="info-item">
            <div class="info-label">设备位置</div>
            <div class="info-value">{{ device.location || '未设置' }}</div>
          </div>
          <div class="info-item">
            <div class="info-label">创建时间</div>
            <div class="info-value">{{ formatDateTime(device.created_at) }}</div>
          </div>
          <div class="info-item">
            <div class="info-label">更新时间</div>
            <div class="info-value">{{ formatDateTime(device.updated_at) }}</div>
          </div>
        </div>
      </div>

      <!-- 统计信息 -->
      <div class="info-section">
        <h4 class="section-title">配置统计</h4>
        <div class="info-items">
          <div class="info-item">
            <div class="info-label">传感器数量</div>
            <div class="info-value">
              <el-tag type="primary">{{ sensorCount }}个</el-tag>
            </div>
          </div>
          <div class="info-item">
            <div class="info-label">控制端口数量</div>
            <div class="info-value">
              <el-tag type="warning">{{ controlCount }}个</el-tag>
            </div>
          </div>
          <div class="info-item">
            <div class="info-label">设备能力</div>
            <div class="info-value">
              <el-tag type="success">{{ capabilityCount }}项</el-tag>
            </div>
          </div>
        </div>
      </div>
    </div>
  </el-card>
</template>

<script setup>
import { computed } from 'vue'
import {
  InfoFilled, Edit, Cpu, Timer, Setting
} from '@element-plus/icons-vue'

const props = defineProps({
  device: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['edit'])

// 计算属性
const sensorCount = computed(() => {
  return props.device?.sensor_config?.sensors?.length || 0
})

const controlCount = computed(() => {
  const controlConfig = props.device?.control_config || {}
  return Object.keys(controlConfig).length
})

const capabilityCount = computed(() => {
  return props.device?.device_capabilities?.length || 0
})

const getDeviceTypeLabel = (type) => {
  const typeMap = {
    'sensor_node': '传感器节点',
    'controller': '控制器',
    'gateway': '网关设备',
    'actuator': '执行器',
    'hybrid': '混合设备'
  }
  return typeMap[type] || type || '未知类型'
}

const getFeatureLabel = (feature) => {
  const featureMap = {
    'ota_update': 'OTA升级',
    'remote_config': '远程配置',
    'data_encryption': '数据加密',
    'low_power_mode': '低功耗模式',
    'mesh_networking': '网状网络',
    'edge_computing': '边缘计算'
  }
  return featureMap[feature] || feature
}



const formatDateTime = (timestamp) => {
  if (!timestamp) return 'N/A'
  return new Date(timestamp).toLocaleString('zh-CN')
}
</script>

<style scoped>
.device-info-card {
  border-radius: 16px;
  border: none;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
  border: 1px solid #e2e8f0;
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

.header-title {
  font-size: 1.1rem;
  font-weight: 600;
  color: #1e293b;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 24px;
}

.info-section {
  background: rgba(255, 255, 255, 0.6);
  border-radius: 12px;
  padding: 20px;
  border: 1px solid #e2e8f0;
}

.info-section.full-width {
  grid-column: 1 / -1;
}

.section-title {
  margin: 0 0 16px 0;
  font-size: 1rem;
  font-weight: 600;
  color: #1e293b;
  padding-bottom: 8px;
  border-bottom: 2px solid #e2e8f0;
}

.info-items {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.info-item {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  padding: 8px 0;
  border-bottom: 1px solid #f1f5f9;
}

.info-item:last-child {
  border-bottom: none;
}

.info-label {
  font-size: 0.9rem;
  color: #64748b;
  font-weight: 500;
  min-width: 100px;
}

.info-value {
  font-size: 0.9rem;
  color: #1e293b;
  font-weight: 500;
  text-align: right;
  flex: 1;
}

.info-value.code {
  font-family: 'Monaco', 'Menlo', monospace;
  background: #f1f5f9;
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 0.85rem;
}

.text-muted {
  color: #94a3b8;
  font-style: italic;
}

.capabilities-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
}

.capability-item {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.capability-item.full-width {
  grid-column: 1 / -1;
}

.capability-label {
  font-size: 0.9rem;
  color: #64748b;
  font-weight: 500;
}

.capability-value {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.protocol-tag, .feature-tag {
  margin: 0;
}

.sensor-overview, .control-overview {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
}

.sensor-chip, .control-chip {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  background: rgba(64, 158, 255, 0.1);
  border: 1px solid rgba(64, 158, 255, 0.2);
  border-radius: 20px;
  font-size: 0.85rem;
}

.control-chip {
  background: rgba(103, 194, 58, 0.1);
  border-color: rgba(103, 194, 58, 0.2);
}

@media (max-width: 768px) {
  .info-grid {
    grid-template-columns: 1fr;
  }
  
  .info-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 4px;
  }
  
  .info-value {
    text-align: left;
  }
  
  .capabilities-grid {
    grid-template-columns: 1fr;
  }
}
</style>