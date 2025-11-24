<template>
  <div class="device-status-container">
    <div class="page-header">
      <h2>设备状态监控</h2>
      <div class="header-actions">
        <el-button @click="refreshStatus" :loading="refreshing">
          <el-icon><Refresh /></el-icon>
          刷新状态
        </el-button>
        <el-button @click="cleanupConnections" type="warning">
          <el-icon><Delete /></el-icon>
          清理连接
        </el-button>
      </div>
    </div>

    <!-- 状态统计卡片 -->
    <el-row :gutter="20" class="status-cards">
      <el-col :span="6">
        <el-card class="status-card online-card">
          <div class="card-content">
            <div class="card-icon">
              <el-icon><Connection /></el-icon>
            </div>
            <div class="card-info">
              <div class="card-value">{{ statusStats.online }}</div>
              <div class="card-label">在线设备</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="status-card offline-card">
          <div class="card-content">
            <div class="card-icon">
              <el-icon><Close /></el-icon>
            </div>
            <div class="card-info">
              <div class="card-value">{{ statusStats.offline }}</div>
              <div class="card-label">离线设备</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="status-card pending-card">
          <div class="card-content">
            <div class="card-icon">
              <el-icon><Warning /></el-icon>
            </div>
            <div class="card-info">
              <div class="card-value">{{ statusStats.pending }}</div>
              <div class="card-label">待断开</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="status-card total-card">
          <div class="card-content">
            <div class="card-icon">
              <el-icon><Monitor /></el-icon>
            </div>
            <div class="card-info">
              <div class="card-value">{{ statusStats.total }}</div>
              <div class="card-label">总设备数</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 筛选和搜索 -->
    <el-card class="filter-card">
      <el-row :gutter="20">
        <el-col :span="6">
          <el-select v-model="filters.status" placeholder="设备状态" clearable>
            <el-option label="全部状态" value="" />
            <el-option label="在线" value="online" />
            <el-option label="离线" value="offline" />
            <el-option label="待断开" value="pending" />
          </el-select>
        </el-col>
        <el-col :span="6">
          <el-select v-model="filters.deviceType" placeholder="设备类型" clearable>
            <el-option label="全部类型" value="" />
            <el-option label="传感器" value="sensor" />
            <el-option label="执行器" value="actuator" />
            <el-option label="网关" value="gateway" />
            <el-option label="摄像头" value="camera" />
          </el-select>
        </el-col>
        <el-col :span="6">
          <el-input 
            v-model="filters.keyword" 
            placeholder="搜索设备ID、名称或类型"
            clearable
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>
        </el-col>
        <el-col :span="6">
          <el-button type="primary" @click="applyFilters">
            <el-icon><Search /></el-icon>
            搜索
          </el-button>
          <el-button @click="resetFilters">重置</el-button>
        </el-col>
      </el-row>
    </el-card>

    <!-- 设备状态表格 -->
    <el-card class="table-card">
      <template #header>
        <div class="card-header">
          <span>设备状态列表</span>
          <div class="header-actions">
            <el-button size="small" @click="exportStatus">
              <el-icon><Download /></el-icon>
              导出
            </el-button>
            <el-switch
              v-model="autoRefresh"
              active-text="自动刷新"
              @change="toggleAutoRefresh"
            />
          </div>
        </div>
      </template>

      <el-table 
        :data="filteredDevices" 
        stripe 
        v-loading="loading"
        @selection-change="handleSelectionChange"
      >
        <el-table-column type="selection" width="55" />
        <el-table-column prop="deviceId" label="设备ID" width="150" fixed="left">
          <template #default="{ row }">
            <div class="device-id">
              <el-icon class="device-icon">
                <Monitor v-if="row.deviceType === 'sensor'" />
                <Camera v-else-if="row.deviceType === 'camera'" />
                <Connection v-else />
              </el-icon>
              {{ row.deviceId }}
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="deviceName" label="设备名称" width="150" />
        <el-table-column prop="deviceType" label="类型" width="100">
          <template #default="{ row }">
            <el-tag size="small">{{ getDeviceTypeText(row.deviceType) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="连接状态" width="120">
          <template #default="{ row }">
            <div class="status-indicator">
              <div :class="['status-dot', row.status]"></div>
              <span :class="['status-text', row.status]">
                {{ getStatusText(row.status) }}
              </span>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="lastHeartbeat" label="最后心跳" width="180">
          <template #default="{ row }">
            <div class="heartbeat-info">
              <div>{{ row.lastHeartbeat }}</div>
              <div class="heartbeat-ago">{{ getHeartbeatAgo(row.lastHeartbeat) }}</div>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="mqttClientId" label="MQTT客户端ID" width="150" />
        <el-table-column prop="ipAddress" label="IP地址" width="130" />
        <el-table-column prop="location" label="位置" width="120" />
        <el-table-column prop="onlineDuration" label="在线时长" width="120">
          <template #default="{ row }">
            <span v-if="row.status === 'online'">{{ row.onlineDuration }}</span>
            <span v-else class="offline-text">-</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button size="small" @click="viewDeviceDetail(row)">详情</el-button>
            <el-button 
              size="small" 
              type="warning" 
              v-if="row.status === 'pending'"
              @click="disconnectDevice(row)"
            >
              断开
            </el-button>
            <el-button 
              size="small" 
              type="success" 
              v-if="row.status === 'offline'"
              @click="reconnectDevice(row)"
            >
              重连
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-wrapper">
        <el-pagination
          v-model:current-page="pagination.currentPage"
          v-model:page-size="pagination.pageSize"
          :page-sizes="[10, 20, 50, 100]"
          :total="pagination.total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 批量操作 -->
    <el-card v-if="selectedDevices.length > 0" class="batch-actions-card">
      <div class="batch-actions">
        <span>已选择 {{ selectedDevices.length }} 个设备</span>
        <div class="actions">
          <el-button 
            type="warning" 
            @click="batchDisconnect"
            :disabled="!canBatchDisconnect"
          >
            批量断开
          </el-button>
          <el-button type="success" @click="batchReconnect">
            批量重连
          </el-button>
          <el-button @click="clearSelection">取消选择</el-button>
        </div>
      </div>
    </el-card>

    <!-- 设备详情对话框 -->
    <el-dialog 
      v-model="deviceDetailVisible" 
      title="设备状态详情" 
      width="800px"
      @close="closeDeviceDetail"
    >
      <div v-if="selectedDevice" class="device-detail">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="设备ID">
            {{ selectedDevice.deviceId }}
          </el-descriptions-item>
          <el-descriptions-item label="设备名称">
            {{ selectedDevice.deviceName }}
          </el-descriptions-item>
          <el-descriptions-item label="设备类型">
            <el-tag>{{ getDeviceTypeText(selectedDevice.deviceType) }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="连接状态">
            <div class="status-indicator">
              <div :class="['status-dot', selectedDevice.status]"></div>
              <span :class="['status-text', selectedDevice.status]">
                {{ getStatusText(selectedDevice.status) }}
              </span>
            </div>
          </el-descriptions-item>
          <el-descriptions-item label="MQTT客户端ID">
            {{ selectedDevice.mqttClientId }}
          </el-descriptions-item>
          <el-descriptions-item label="IP地址">
            {{ selectedDevice.ipAddress }}
          </el-descriptions-item>
          <el-descriptions-item label="最后心跳">
            {{ selectedDevice.lastHeartbeat }}
          </el-descriptions-item>
          <el-descriptions-item label="心跳间隔">
            {{ selectedDevice.heartbeatInterval }}秒
          </el-descriptions-item>
          <el-descriptions-item label="连接时间">
            {{ selectedDevice.connectTime }}
          </el-descriptions-item>
          <el-descriptions-item label="在线时长">
            {{ selectedDevice.onlineDuration }}
          </el-descriptions-item>
          <el-descriptions-item label="位置">
            {{ selectedDevice.location }}
          </el-descriptions-item>
          <el-descriptions-item label="固件版本">
            {{ selectedDevice.firmwareVersion }}
          </el-descriptions-item>
        </el-descriptions>

        <el-divider />

        <div class="mqtt-topics">
          <h4>MQTT主题配置</h4>
          <el-table :data="selectedDevice.mqttTopics" size="small">
            <el-table-column prop="type" label="类型" width="100" />
            <el-table-column prop="topic" label="主题" />
            <el-table-column prop="qos" label="QoS" width="80" />
            <el-table-column prop="lastMessage" label="最后消息时间" width="180" />
          </el-table>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { 
  Refresh, 
  Delete, 
  Connection, 
  Close, 
  Warning, 
  Monitor, 
  Search, 
  Download,
  Camera
} from '@element-plus/icons-vue'

const loading = ref(false)
const refreshing = ref(false)
const autoRefresh = ref(false)
const autoRefreshTimer = ref(null)
const deviceDetailVisible = ref(false)
const selectedDevice = ref(null)
const selectedDevices = ref([])

const filters = reactive({
  status: '',
  deviceType: '',
  keyword: ''
})

const pagination = reactive({
  currentPage: 1,
  pageSize: 20,
  total: 0
})

const statusStats = reactive({
  online: 0,
  offline: 0,
  pending: 0,
  total: 0
})

const devices = ref([
  {
    id: 1,
    deviceId: 'TEMP_001',
    deviceName: '温度传感器01',
    deviceType: 'sensor',
    status: 'online',
    lastHeartbeat: '2024-01-15 15:30:25',
    mqttClientId: 'TEMP_001_client',
    ipAddress: '192.168.1.101',
    location: '车间A-1号位',
    onlineDuration: '2小时30分',
    connectTime: '2024-01-15 13:00:00',
    heartbeatInterval: 30,
    firmwareVersion: 'v1.2.3',
    mqttTopics: [
      { type: '数据', topic: 'aiot/devices/TEMP_001/data', qos: 1, lastMessage: '2024-01-15 15:30:25' },
      { type: '心跳', topic: 'aiot/devices/TEMP_001/heartbeat', qos: 0, lastMessage: '2024-01-15 15:30:25' },
      { type: '状态', topic: 'aiot/devices/TEMP_001/status', qos: 1, lastMessage: '2024-01-15 13:00:00' }
    ]
  },
  {
    id: 2,
    deviceId: 'CAM_002',
    deviceName: '监控摄像头02',
    deviceType: 'camera',
    status: 'pending',
    lastHeartbeat: '2024-01-15 14:25:12',
    mqttClientId: 'CAM_002_client',
    ipAddress: '192.168.1.102',
    location: '大门入口',
    onlineDuration: '-',
    connectTime: '2024-01-15 12:00:00',
    heartbeatInterval: 60,
    firmwareVersion: 'v2.1.0',
    mqttTopics: [
      { type: '数据', topic: 'aiot/devices/CAM_002/data', qos: 1, lastMessage: '2024-01-15 14:25:12' },
      { type: '心跳', topic: 'aiot/devices/CAM_002/heartbeat', qos: 0, lastMessage: '2024-01-15 14:25:12' },
      { type: '状态', topic: 'aiot/devices/CAM_002/status', qos: 1, lastMessage: '2024-01-15 12:00:00' }
    ]
  },
  {
    id: 3,
    deviceId: 'CTRL_003',
    deviceName: '控制器03',
    deviceType: 'actuator',
    status: 'offline',
    lastHeartbeat: '2024-01-15 12:45:30',
    mqttClientId: 'CTRL_003_client',
    ipAddress: '192.168.1.103',
    location: '配电室',
    onlineDuration: '-',
    connectTime: '2024-01-15 10:00:00',
    heartbeatInterval: 30,
    firmwareVersion: 'v1.0.5',
    mqttTopics: [
      { type: '数据', topic: 'aiot/devices/CTRL_003/data', qos: 1, lastMessage: '2024-01-15 12:45:30' },
      { type: '心跳', topic: 'aiot/devices/CTRL_003/heartbeat', qos: 0, lastMessage: '2024-01-15 12:45:30' },
      { type: '状态', topic: 'aiot/devices/CTRL_003/status', qos: 1, lastMessage: '2024-01-15 10:00:00' }
    ]
  }
])

const filteredDevices = computed(() => {
  let result = devices.value

  if (filters.status) {
    result = result.filter(device => device.status === filters.status)
  }

  if (filters.deviceType) {
    result = result.filter(device => device.deviceType === filters.deviceType)
  }

  if (filters.keyword) {
    const keyword = filters.keyword.toLowerCase()
    result = result.filter(device => 
      device.deviceId.toLowerCase().includes(keyword) ||
      device.deviceName.toLowerCase().includes(keyword) ||
      device.deviceType.toLowerCase().includes(keyword)
    )
  }

  return result
})

const canBatchDisconnect = computed(() => {
  return selectedDevices.value.some(device => device.status === 'pending')
})

const getDeviceTypeText = (type) => {
  const types = {
    'sensor': '传感器',
    'actuator': '执行器',
    'gateway': '网关',
    'camera': '摄像头',
    'controller': '控制器'
  }
  return types[type] || type
}

const getStatusText = (status) => {
  const texts = {
    'online': '在线',
    'offline': '离线',
    'pending': '待断开'
  }
  return texts[status] || status
}

const getHeartbeatAgo = (heartbeatTime) => {
  const now = new Date()
  const heartbeat = new Date(heartbeatTime)
  const diff = Math.floor((now - heartbeat) / 1000 / 60) // 分钟
  
  if (diff < 1) return '刚刚'
  if (diff < 60) return `${diff}分钟前`
  if (diff < 1440) return `${Math.floor(diff / 60)}小时前`
  return `${Math.floor(diff / 1440)}天前`
}

const updateStatusStats = () => {
  const stats = {
    online: 0,
    offline: 0,
    pending: 0,
    total: devices.value.length
  }

  devices.value.forEach(device => {
    stats[device.status]++
  })

  Object.assign(statusStats, stats)
}

const refreshStatus = async () => {
  refreshing.value = true
  try {
    // 模拟刷新状态
    await new Promise(resolve => setTimeout(resolve, 1000))
    updateStatusStats()
    ElMessage.success('设备状态已刷新')
  } catch (error) {
    ElMessage.error('刷新失败')
  } finally {
    refreshing.value = false
  }
}

const cleanupConnections = async () => {
  try {
    await ElMessageBox.confirm(
      '确定要清理所有待断开的MQTT连接吗？此操作不可撤销。',
      '确认清理',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )

    // 模拟清理连接
    await new Promise(resolve => setTimeout(resolve, 1500))
    
    // 移除待断开的设备
    devices.value = devices.value.filter(device => device.status !== 'pending')
    updateStatusStats()
    
    ElMessage.success('MQTT连接清理完成')
  } catch {
    // 用户取消
  }
}

const applyFilters = () => {
  pagination.currentPage = 1
  // 筛选逻辑已在computed中处理
}

const resetFilters = () => {
  Object.assign(filters, {
    status: '',
    deviceType: '',
    keyword: ''
  })
  pagination.currentPage = 1
}

const handleSelectionChange = (selection) => {
  selectedDevices.value = selection
}

const handleSizeChange = (size) => {
  pagination.pageSize = size
  pagination.currentPage = 1
}

const handleCurrentChange = (page) => {
  pagination.currentPage = page
}

const viewDeviceDetail = (device) => {
  selectedDevice.value = device
  deviceDetailVisible.value = true
}

const closeDeviceDetail = () => {
  selectedDevice.value = null
  deviceDetailVisible.value = false
}

const disconnectDevice = async (device) => {
  try {
    await ElMessageBox.confirm(
      `确定要断开设备 ${device.deviceName} 的MQTT连接吗？`,
      '确认断开',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )

    // 模拟断开连接
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    device.status = 'offline'
    updateStatusStats()
    
    ElMessage.success(`设备 ${device.deviceName} 已断开连接`)
  } catch {
    // 用户取消
  }
}

const reconnectDevice = async (device) => {
  try {
    // 模拟重连
    await new Promise(resolve => setTimeout(resolve, 1500))
    
    device.status = 'online'
    device.lastHeartbeat = new Date().toLocaleString()
    updateStatusStats()
    
    ElMessage.success(`设备 ${device.deviceName} 重连成功`)
  } catch (error) {
    ElMessage.error(`设备 ${device.deviceName} 重连失败`)
  }
}

const batchDisconnect = async () => {
  const pendingDevices = selectedDevices.value.filter(device => device.status === 'pending')
  
  if (pendingDevices.length === 0) {
    ElMessage.warning('没有可断开的设备')
    return
  }

  try {
    await ElMessageBox.confirm(
      `确定要断开 ${pendingDevices.length} 个设备的MQTT连接吗？`,
      '批量断开确认',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )

    // 模拟批量断开
    await new Promise(resolve => setTimeout(resolve, 2000))
    
    pendingDevices.forEach(device => {
      device.status = 'offline'
    })
    
    updateStatusStats()
    clearSelection()
    
    ElMessage.success(`已断开 ${pendingDevices.length} 个设备的连接`)
  } catch {
    // 用户取消
  }
}

const batchReconnect = async () => {
  try {
    await ElMessageBox.confirm(
      `确定要重连 ${selectedDevices.value.length} 个设备吗？`,
      '批量重连确认',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'info'
      }
    )

    // 模拟批量重连
    await new Promise(resolve => setTimeout(resolve, 2000))
    
    selectedDevices.value.forEach(device => {
      device.status = 'online'
      device.lastHeartbeat = new Date().toLocaleString()
    })
    
    updateStatusStats()
    clearSelection()
    
    ElMessage.success(`已重连 ${selectedDevices.value.length} 个设备`)
  } catch {
    // 用户取消
  }
}

const clearSelection = () => {
  selectedDevices.value = []
}

const exportStatus = () => {
  ElMessage.success('设备状态导出功能开发中...')
}

const toggleAutoRefresh = (enabled) => {
  if (enabled) {
    autoRefreshTimer.value = setInterval(() => {
      refreshStatus()
    }, 30000) // 30秒自动刷新
    ElMessage.success('已开启自动刷新（30秒间隔）')
  } else {
    if (autoRefreshTimer.value) {
      clearInterval(autoRefreshTimer.value)
      autoRefreshTimer.value = null
    }
    ElMessage.info('已关闭自动刷新')
  }
}

onMounted(() => {
  updateStatusStats()
  pagination.total = devices.value.length
})

onUnmounted(() => {
  if (autoRefreshTimer.value) {
    clearInterval(autoRefreshTimer.value)
  }
})
</script>

<style scoped>
.device-status-container {
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.page-header h2 {
  margin: 0;
  color: #303133;
}

.header-actions {
  display: flex;
  gap: 10px;
}

.status-cards {
  margin-bottom: 20px;
}

.status-card {
  height: 100px;
}

.card-content {
  display: flex;
  align-items: center;
  height: 100%;
}

.card-icon {
  font-size: 32px;
  margin-right: 15px;
  width: 50px;
  text-align: center;
}

.card-info {
  flex: 1;
}

.card-value {
  font-size: 28px;
  font-weight: bold;
  line-height: 1;
  margin-bottom: 5px;
}

.card-label {
  font-size: 14px;
  color: #909399;
}

.online-card .card-icon {
  color: #67c23a;
}

.online-card .card-value {
  color: #67c23a;
}

.offline-card .card-icon {
  color: #f56c6c;
}

.offline-card .card-value {
  color: #f56c6c;
}

.pending-card .card-icon {
  color: #e6a23c;
}

.pending-card .card-value {
  color: #e6a23c;
}

.total-card .card-icon {
  color: #409eff;
}

.total-card .card-value {
  color: #409eff;
}

.filter-card,
.table-card,
.batch-actions-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.device-id {
  display: flex;
  align-items: center;
  gap: 8px;
}

.device-icon {
  color: #409eff;
}

.status-indicator {
  display: flex;
  align-items: center;
  gap: 8px;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

.status-dot.online {
  background-color: #67c23a;
}

.status-dot.offline {
  background-color: #f56c6c;
}

.status-dot.pending {
  background-color: #e6a23c;
}

.status-text.online {
  color: #67c23a;
}

.status-text.offline {
  color: #f56c6c;
}

.status-text.pending {
  color: #e6a23c;
}

.heartbeat-info {
  line-height: 1.2;
}

.heartbeat-ago {
  font-size: 12px;
  color: #909399;
}

.offline-text {
  color: #c0c4cc;
}

.pagination-wrapper {
  display: flex;
  justify-content: center;
  margin-top: 20px;
}

.batch-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.batch-actions .actions {
  display: flex;
  gap: 10px;
}

.device-detail {
  padding: 10px 0;
}

.mqtt-topics {
  margin-top: 20px;
}

.mqtt-topics h4 {
  margin-bottom: 15px;
  color: #303133;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .device-status-container {
    padding: 10px;
  }
  
  .page-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
  }
  
  .status-cards .el-col {
    margin-bottom: 10px;
  }
  
  .card-content {
    flex-direction: column;
    text-align: center;
  }
  
  .card-icon {
    margin-right: 0;
    margin-bottom: 10px;
  }
}
</style>