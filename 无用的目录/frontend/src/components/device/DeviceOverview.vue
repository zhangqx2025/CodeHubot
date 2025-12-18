<template>
  <el-card class="device-overview-card" shadow="hover" v-loading="loading">
    <div class="device-header">
      <div class="device-main-info">
        <div class="device-icon">
          <el-icon size="48" color="#409EFF">
            <Monitor />
          </el-icon>
        </div>
        <div class="device-info">
          <h2 class="device-name">{{ device.name || '设备名称' }}</h2>
          <div class="device-meta">
            <el-tag class="device-type-tag" type="info">{{ getDeviceTypeLabel(device.device_type) }}</el-tag>
            <span class="device-id">ID: {{ device.device_id || 'N/A' }}</span>
          </div>
        </div>
      </div>
      
      <div class="device-status">
        <div class="device-status-indicator" :class="{ 'online': device.is_online, 'offline': !device.is_online }">
          <el-icon size="12">
            <Connection v-if="device.is_online" />
            <Warning v-else />
          </el-icon>
          <span>{{ device.is_online ? '在线' : '离线' }}</span>
        </div>
        <div class="last-seen" v-if="device.last_seen">
          <el-icon size="14"><Clock /></el-icon>
          <span>{{ formatLastSeen(device.last_seen) }}</span>
        </div>
      </div>

      <div class="device-actions">
        <el-button type="primary" @click="$emit('edit')" :icon="Edit">
          编辑设备
        </el-button>
        <el-button @click="$emit('refresh')" :icon="Refresh">
          刷新
        </el-button>
        <el-button type="danger" plain @click="$emit('unbind')" :icon="RemoveFilled">
          解绑设备
        </el-button>
      </div>
    </div>

    <div class="device-quick-info">
      <div class="quick-info-grid">
        <div class="quick-info-item">
          <div class="info-content">
            <el-icon size="20" color="#67C23A"><Cpu /></el-icon>
            <div class="info-details">
              <div class="info-label">固件版本</div>
              <div class="info-value">{{ device.firmware_version || 'N/A' }}</div>
            </div>
          </div>
        </div>
        
        <div class="quick-info-item">
          <div class="info-content">
            <el-icon size="20" color="#409EFF"><Monitor /></el-icon>
            <div class="info-details">
              <div class="info-label">硬件版本</div>
              <div class="info-value">{{ device.hardware_version || 'N/A' }}</div>
            </div>
          </div>
        </div>
        
        <div class="quick-info-item">
          <div class="info-content">
            <el-icon size="20" color="#E6A23C"><Location /></el-icon>
            <div class="info-details">
              <div class="info-label">设备位置</div>
              <div class="info-value">{{ device.location || '未设置' }}</div>
            </div>
          </div>
        </div>
        
        <div class="quick-info-item">
          <div class="info-content">
            <el-icon size="20" color="#909399"><Connection /></el-icon>
            <div class="info-details">
              <div class="info-label">IP地址</div>
              <div class="info-value">{{ device.ip_address || 'N/A' }}</div>
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
  Monitor, Edit, Refresh, Connection, Warning, Clock, 
  Cpu, Location, RemoveFilled 
} from '@element-plus/icons-vue'

const props = defineProps({
  device: {
    type: Object,
    default: () => ({})
  },
  loading: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['edit', 'refresh', 'unbind'])

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

const formatLastSeen = (timestamp) => {
  if (!timestamp) return 'N/A'
  
  const now = new Date()
  const lastSeen = new Date(timestamp)
  const diffMs = now - lastSeen
  const diffMins = Math.floor(diffMs / 60000)
  const diffHours = Math.floor(diffMins / 60)
  const diffDays = Math.floor(diffHours / 24)
  
  if (diffMins < 1) return '刚刚'
  if (diffMins < 60) return `${diffMins}分钟前`
  if (diffHours < 24) return `${diffHours}小时前`
  if (diffDays < 7) return `${diffDays}天前`
  
  return lastSeen.toLocaleDateString()
}
</script>

<style scoped>
.device-overview-card {
  border-radius: 16px;
  border: none;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  background: linear-gradient(135deg, #ffffff 0%, #f8fafc 100%);
  border: 1px solid #e2e8f0;
}

.device-header {
  display: flex;
  align-items: flex-start;
  gap: 24px;
  margin-bottom: 24px;
  flex-wrap: wrap;
}

.device-main-info {
  display: flex;
  align-items: center;
  gap: 16px;
  flex: 1;
  min-width: 300px;
}

.device-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 80px;
  height: 80px;
  border-radius: 20px;
  background: linear-gradient(135deg, #409EFF 0%, #67C23A 100%);
  color: white;
}

.device-info {
  flex: 1;
}

.device-name {
  margin: 0 0 8px 0;
  font-size: 1.5rem;
  font-weight: 600;
  color: #1e293b;
}

.device-meta {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.device-type-tag {
  font-size: 0.85rem;
}

.device-id {
  font-size: 0.9rem;
  color: #64748b;
  font-family: 'Monaco', 'Menlo', monospace;
}

.device-status {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 8px;
}

.device-status-indicator {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 0.9rem;
  font-weight: 500;
}

.device-status-indicator.online {
  background: #f0f9ff;
  color: #0369a1;
  border: 1px solid #bae6fd;
}

.device-status-indicator.offline {
  background: #fef2f2;
  color: #dc2626;
  border: 1px solid #fecaca;
}

.last-seen {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 0.85rem;
  color: #64748b;
}

.device-actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.quick-info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
}

.quick-info-item {
  padding: 16px;
  background: rgba(255, 255, 255, 0.8);
  border-radius: 12px;
  border: 1px solid #e2e8f0;
  transition: all 0.3s ease;
}

.quick-info-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.info-content {
  display: flex;
  align-items: center;
  gap: 12px;
}

.info-details {
  flex: 1;
}

.info-label {
  font-size: 0.85rem;
  color: #64748b;
  margin-bottom: 4px;
}

.info-value {
  font-size: 0.95rem;
  font-weight: 600;
  color: #1e293b;
}

@media (max-width: 768px) {
  .device-header {
    flex-direction: column;
    align-items: stretch;
  }
  
  .device-main-info {
    min-width: auto;
  }
  
  .device-status {
    align-items: flex-start;
  }
  
  .quick-info-grid {
    grid-template-columns: 1fr;
  }
}
</style>