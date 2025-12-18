<template>
  <div class="device-basic-info">
    <!-- 设备基本信息 -->
    <el-row :gutter="24">
      <!-- 设备状态卡片 -->
      <el-col :xs="24" :lg="8">
        <el-card class="status-card" shadow="hover">
          <template #header>
            <div class="card-header">
              <el-icon size="20" :color="deviceInfo.is_online ? '#67C23A' : '#F56C6C'">
                <Monitor />
              </el-icon>
              <span>设备状态</span>
              <div class="card-actions">
                <el-button size="small" type="text" @click="pingDevice">
                  <el-icon><Connection /></el-icon>
                  测试连接
                </el-button>
              </div>
            </div>
          </template>
          <div class="status-content">
            <div class="status-indicator">
              <div class="status-dot" :class="{ online: deviceInfo.is_online, offline: !deviceInfo.is_online }"></div>
              <span class="status-text">{{ deviceInfo.is_online ? '在线' : '离线' }}</span>
            </div>
            <div class="status-details">
              <div class="detail-item">
                <span class="detail-label">最后在线</span>
                <span class="detail-value">{{ formatDateTime(deviceInfo.last_seen) }}</span>
              </div>
              <div class="detail-item">
                <span class="detail-label">运行时长</span>
                <span class="detail-value">{{ formatUptime(deviceInfo.uptime) }}</span>
              </div>
              <div class="detail-item">
                <span class="detail-label">网络状态</span>
                <el-tag :type="getNetworkStatusType(deviceInfo.network_status)" size="small">
                  {{ getNetworkStatusText(deviceInfo.network_status) }}
                </el-tag>
              </div>
              <div class="detail-item">
                <span class="detail-label">信号强度</span>
                <div class="signal-strength">
                  <el-progress 
                    :percentage="deviceInfo.signal_strength" 
                    :color="getSignalColor(deviceInfo.signal_strength)"
                    :show-text="false"
                    :stroke-width="6"
                  />
                  <span class="signal-text">{{ deviceInfo.signal_strength }}%</span>
                </div>
              </div>
              <div class="detail-item" v-if="deviceInfo.battery_level !== undefined">
                <span class="detail-label">电池电量</span>
                <div class="battery-level">
                  <el-progress 
                    :percentage="deviceInfo.battery_level" 
                    :color="getBatteryColor(deviceInfo.battery_level)"
                    :show-text="false"
                    :stroke-width="6"
                  />
                  <span class="battery-text">{{ deviceInfo.battery_level }}%</span>
                </div>
              </div>
            </div>
          </div>
        </el-card>
      </el-col>

      <!-- 设备信息卡片 -->
      <el-col :xs="24" :lg="16">
        <el-card class="info-card" shadow="hover">
          <template #header>
            <div class="card-header">
              <el-icon size="20" color="#409EFF"><InfoFilled /></el-icon>
              <span>设备信息</span>
              <div class="card-actions">
                <el-button size="small" type="text" @click="$emit('edit-device')">
                  <el-icon><Edit /></el-icon>
                  编辑
                </el-button>
              </div>
            </div>
          </template>
          <div class="device-info-grid">
            <div class="info-item">
              <span class="info-label">设备名称</span>
              <span class="info-value">{{ deviceInfo.name }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">设备ID</span>
              <span class="info-value">
                {{ deviceInfo.device_id }}
                <el-button size="small" type="text" @click="copyToClipboard(deviceInfo.device_id)">
                  <el-icon><CopyDocument /></el-icon>
                </el-button>
              </span>
            </div>
            <div class="info-item">
              <span class="info-label">UUID</span>
              <span class="info-value">
                {{ deviceInfo.uuid }}
                <el-button size="small" type="text" @click="copyToClipboard(deviceInfo.uuid)">
                  <el-icon><CopyDocument /></el-icon>
                </el-button>
              </span>
            </div>
            <div class="info-item">
              <span class="info-label">设备类型</span>
              <span class="info-value">{{ deviceInfo.device_type }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">制造商</span>
              <span class="info-value">{{ deviceInfo.manufacturer }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">型号</span>
              <span class="info-value">{{ deviceInfo.model }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">固件版本</span>
              <span class="info-value">{{ deviceInfo.firmware_version }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">硬件版本</span>
              <span class="info-value">{{ deviceInfo.hardware_version }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">IP地址</span>
              <span class="info-value">{{ deviceInfo.ip_address }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">MAC地址</span>
              <span class="info-value">{{ deviceInfo.mac_address }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">设备位置</span>
              <span class="info-value">
                {{ deviceInfo.location }}
                <el-button size="small" type="text" @click="showLocationMap">
                  <el-icon><Location /></el-icon>
                </el-button>
              </span>
            </div>
            <div class="info-item">
              <span class="info-label">设备组</span>
              <span class="info-value">{{ deviceInfo.group_name }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">创建时间</span>
              <span class="info-value">{{ formatDateTime(deviceInfo.created_at) }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">最后更新</span>
              <span class="info-value">{{ formatDateTime(deviceInfo.updated_at) }}</span>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ElMessage } from 'element-plus'
import {
  Monitor, Edit, InfoFilled, CopyDocument, Location, Connection
} from '@element-plus/icons-vue'

// Props
const props = defineProps({
  deviceInfo: {
    type: Object,
    required: true
  }
})

// Emits
const emit = defineEmits(['edit-device'])

// Methods
const copyToClipboard = async (text) => {
  try {
    await navigator.clipboard.writeText(text)
    ElMessage.success('已复制到剪贴板')
  } catch (err) {
    ElMessage.error('复制失败')
  }
}

const pingDevice = async () => {
  ElMessage.info('正在测试网络连接...')
  // 模拟ping操作
  setTimeout(() => {
    const success = Math.random() > 0.2
    if (success) {
      ElMessage.success('设备网络连接正常')
    } else {
      ElMessage.error('设备网络连接失败')
    }
  }, 2000)
}

const showLocationMap = () => {
  ElMessage.info('地图功能开发中...')
}

const getNetworkStatusType = (status) => {
  const statusMap = {
    'connected': 'success',
    'disconnected': 'danger',
    'connecting': 'warning',
    'unstable': 'warning'
  }
  return statusMap[status] || 'info'
}

const getNetworkStatusText = (status) => {
  const statusMap = {
    'connected': '已连接',
    'disconnected': '已断开',
    'connecting': '连接中',
    'unstable': '不稳定'
  }
  return statusMap[status] || '未知'
}

const getSignalColor = (strength) => {
  if (strength >= 80) return '#67C23A'
  if (strength >= 60) return '#E6A23C'
  if (strength >= 40) return '#F56C6C'
  return '#909399'
}

const getBatteryColor = (level) => {
  if (level >= 60) return '#67C23A'
  if (level >= 30) return '#E6A23C'
  return '#F56C6C'
}

const formatUptime = (seconds) => {
  if (!seconds) return '0分钟'
  
  const days = Math.floor(seconds / 86400)
  const hours = Math.floor((seconds % 86400) / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  
  if (days > 0) {
    return `${days}天${hours}小时`
  } else if (hours > 0) {
    return `${hours}小时${minutes}分钟`
  } else {
    return `${minutes}分钟`
  }
}

const formatDateTime = (dateTime) => {
  if (!dateTime) return '未知'
  return new Date(dateTime).toLocaleString('zh-CN')
}
</script>

<style scoped>
.device-basic-info {
  margin-bottom: 24px;
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-weight: 600;
}

.card-header span {
  margin-left: 8px;
  flex: 1;
}

.card-actions {
  display: flex;
  gap: 8px;
}

.status-content {
  padding: 16px 0;
}

.status-indicator {
  display: flex;
  align-items: center;
  margin-bottom: 20px;
}

.status-dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  margin-right: 8px;
}

.status-dot.online {
  background-color: #67C23A;
  box-shadow: 0 0 8px rgba(103, 194, 58, 0.4);
}

.status-dot.offline {
  background-color: #F56C6C;
  box-shadow: 0 0 8px rgba(245, 108, 108, 0.4);
}

.status-text {
  font-size: 16px;
  font-weight: 600;
}

.status-details {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.detail-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.detail-label {
  color: #909399;
  font-size: 14px;
}

.detail-value {
  font-weight: 500;
}

.signal-strength, .battery-level {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 100px;
}

.signal-text, .battery-text {
  font-size: 12px;
  color: #606266;
  min-width: 30px;
}

.device-info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 16px;
}

.info-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 0;
  border-bottom: 1px solid #f0f0f0;
}

.info-label {
  color: #909399;
  font-size: 14px;
  min-width: 80px;
}

.info-value {
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 4px;
}

@media (max-width: 768px) {
  .device-info-grid {
    grid-template-columns: 1fr;
  }
  
  .info-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 4px;
  }
}
</style>