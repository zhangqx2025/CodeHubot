<template>
  <div class="device-interactions">
    <!-- 页面标题 -->
    <div class="page-header">
      <div class="header-content">
        <h1 class="page-title">
          <el-icon><TrendCharts /></el-icon>
          设备交互日志
        </h1>
        <p class="page-description">查看和分析所有设备与服务器的交互数据</p>
      </div>
      <div class="header-actions">
        <el-button type="primary" @click="refreshData" :loading="loading">
          <el-icon><Refresh /></el-icon>
          刷新数据
        </el-button>
        <el-button @click="exportData">
          <el-icon><Download /></el-icon>
          导出数据
        </el-button>
      </div>
    </div>

    <!-- 统计概览 -->
    <el-row :gutter="20" class="stats-overview">
      <el-col :span="6">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-icon total">
              <el-icon><DataAnalysis /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ totalInteractions.toLocaleString() }}</div>
              <div class="stat-label">总交互次数</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-icon success">
              <el-icon><CircleCheck /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ successRate }}%</div>
              <div class="stat-label">成功率</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-icon data">
              <el-icon><Upload /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ formatDataSize(totalDataTransferred) }}</div>
              <div class="stat-label">数据传输量</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-icon time">
              <el-icon><Timer /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ avgResponseTime }}ms</div>
              <div class="stat-label">平均响应时间</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 筛选和搜索 -->
    <el-card class="filter-card">
      <el-row :gutter="20">
        <el-col :span="6">
          <el-select v-model="filters.deviceId" placeholder="选择设备" clearable @change="loadInteractionData">
            <el-option label="全部设备" value="" />
            <el-option 
              v-for="device in deviceList" 
              :key="device.device_id" 
              :label="device.name" 
              :value="device.device_id" 
            />
          </el-select>
        </el-col>
        <el-col :span="6">
          <el-select v-model="filters.type" placeholder="交互类型" clearable @change="loadInteractionData">
            <el-option label="全部类型" value="" />
            <el-option label="数据上报" value="data_upload" />
            <el-option label="命令下发" value="command" />
            <el-option label="心跳包" value="heartbeat" />
            <el-option label="配置更新" value="config" />
          </el-select>
        </el-col>
        <el-col :span="6">
          <el-select v-model="filters.status" placeholder="状态" clearable @change="loadInteractionData">
            <el-option label="全部状态" value="" />
            <el-option label="成功" value="success" />
            <el-option label="失败" value="failed" />
          </el-select>
        </el-col>
        <el-col :span="6">
          <el-date-picker
            v-model="filters.dateRange"
            type="datetimerange"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
            format="YYYY-MM-DD HH:mm:ss"
            value-format="YYYY-MM-DD HH:mm:ss"
            @change="loadInteractionData"
          />
        </el-col>
      </el-row>
    </el-card>

    <!-- 交互数据表格 -->
    <el-card class="table-card">
      <template #header>
        <div class="card-header">
          <span>交互记录</span>
          <div class="header-actions">
            <el-input
              v-model="searchText"
              placeholder="搜索设备名称、ID或描述"
              style="width: 200px"
              @input="handleSearch"
            >
              <template #prefix>
                <el-icon><Search /></el-icon>
              </template>
            </el-input>
          </div>
        </div>
      </template>

      <el-table 
        :data="filteredInteractionData" 
        v-loading="loading"
        stripe
        height="500"
        @sort-change="handleSortChange"
      >
        <el-table-column prop="timestamp" label="时间" width="180" sortable="custom">
          <template #default="{ row }">
            <el-icon><Clock /></el-icon>
            {{ row.timestamp }}
          </template>
        </el-table-column>
        
        <el-table-column prop="deviceName" label="设备" width="150">
          <template #default="{ row }">
            <div class="device-info">
              <div class="device-name">{{ row.deviceName }}</div>
              <div class="device-id">{{ row.deviceId }}</div>
            </div>
          </template>
        </el-table-column>
        
        <el-table-column prop="type" label="类型" width="120">
          <template #default="{ row }">
            <el-tag :type="getTypeTagType(row.type)">
              {{ getInteractionTypeLabel(row.type) }}
            </el-tag>
          </template>
        </el-table-column>
        
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusTagType(row.status)">
              {{ row.status === 'success' ? '成功' : '失败' }}
            </el-tag>
          </template>
        </el-table-column>
        
        <el-table-column prop="dataSize" label="数据大小" width="120" sortable="custom">
          <template #default="{ row }">
            {{ formatDataSize(row.dataSize) }}
          </template>
        </el-table-column>
        
        <el-table-column prop="responseTime" label="响应时间" width="120" sortable="custom">
          <template #default="{ row }">
            <span :class="getResponseTimeClass(row.responseTime)">
              {{ row.responseTime }}ms
            </span>
          </template>
        </el-table-column>
        
        <el-table-column prop="description" label="描述" min-width="200">
          <template #default="{ row }">
            {{ row.description }}
          </template>
        </el-table-column>
        
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button type="text" size="small" @click="viewDetails(row)">
              <el-icon><View /></el-icon>
              详情
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination-wrapper">
        <el-pagination
          v-model:current-page="pagination.currentPage"
          v-model:page-size="pagination.pageSize"
          :page-sizes="[20, 50, 100, 200]"
          :total="pagination.total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 详情对话框 -->
    <el-dialog v-model="detailDialogVisible" title="交互详情" width="600px">
      <div v-if="selectedInteraction" class="interaction-detail">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="时间">
            {{ selectedInteraction.timestamp }}
          </el-descriptions-item>
          <el-descriptions-item label="设备">
            {{ selectedInteraction.deviceName }} ({{ selectedInteraction.deviceId }})
          </el-descriptions-item>
          <el-descriptions-item label="类型">
            <el-tag :type="getTypeTagType(selectedInteraction.type)">
              {{ getInteractionTypeLabel(selectedInteraction.type) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="getStatusTagType(selectedInteraction.status)">
              {{ selectedInteraction.status === 'success' ? '成功' : '失败' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="数据大小">
            {{ formatDataSize(selectedInteraction.dataSize) }}
          </el-descriptions-item>
          <el-descriptions-item label="响应时间">
            {{ selectedInteraction.responseTime }}ms
          </el-descriptions-item>
          <el-descriptions-item label="描述" :span="2">
            {{ selectedInteraction.description }}
          </el-descriptions-item>
        </el-descriptions>
        
        <div v-if="selectedInteraction.errorMessage" class="error-info">
          <h4>错误信息</h4>
          <el-alert type="error" :closable="false">
            {{ selectedInteraction.errorMessage }}
          </el-alert>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import {
  TrendCharts, Refresh, Download, DataAnalysis, CircleCheck, Upload, Timer,
  Search, Clock, View
} from '@element-plus/icons-vue'

// 响应式数据
const loading = ref(false)
const searchText = ref('')
const detailDialogVisible = ref(false)
const selectedInteraction = ref(null)

// 统计数据
const totalInteractions = ref(0)
const successRate = ref(0)
const totalDataTransferred = ref(0)
const avgResponseTime = ref(0)

// 设备列表
const deviceList = ref([])

// 筛选条件
const filters = reactive({
  deviceId: '',
  type: '',
  status: '',
  dateRange: []
})

// 交互数据
const interactionData = ref([])

// 分页
const pagination = reactive({
  currentPage: 1,
  pageSize: 20,
  total: 0
})

// 计算属性
const filteredInteractionData = computed(() => {
  let data = interactionData.value
  
  if (searchText.value) {
    const search = searchText.value.toLowerCase()
    data = data.filter(item => 
      item.deviceName.toLowerCase().includes(search) ||
      item.deviceId.toLowerCase().includes(search) ||
      item.description.toLowerCase().includes(search)
    )
  }
  
  return data
})

// 方法
const loadDeviceList = async () => {
  // 模拟加载设备列表
  deviceList.value = [
    { device_id: 'DEV001', name: '温湿度传感器-01' },
    { device_id: 'DEV002', name: '压力传感器-01' },
    { device_id: 'DEV003', name: '光照传感器-01' },
    { device_id: 'DEV004', name: '运动传感器-01' },
    { device_id: 'DEV005', name: '温湿度传感器-02' }
  ]
}

const loadStatistics = async () => {
  // 模拟加载统计数据
  totalInteractions.value = 15847
  successRate.value = 98.2
  totalDataTransferred.value = 125.6 * 1024 * 1024 // 125.6MB
  avgResponseTime.value = 142
}

const loadInteractionData = async () => {
  loading.value = true
  try {
    // 模拟加载交互数据
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    const mockData = []
    const devices = deviceList.value
    const types = ['data_upload', 'command', 'heartbeat', 'config']
    const statuses = ['success', 'failed']
    
    for (let i = 0; i < 100; i++) {
      const device = devices[Math.floor(Math.random() * devices.length)]
      const type = types[Math.floor(Math.random() * types.length)]
      const status = Math.random() > 0.1 ? 'success' : 'failed'
      const responseTime = status === 'success' ? 
        Math.floor(Math.random() * 500) + 50 : 
        Math.floor(Math.random() * 5000) + 1000
      
      mockData.push({
        id: i + 1,
        timestamp: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000).toLocaleString(),
        deviceId: device.device_id,
        deviceName: device.name,
        type,
        status,
        dataSize: Math.floor(Math.random() * 10240) + 64,
        responseTime,
        description: getInteractionDescription(type, status),
        errorMessage: status === 'failed' ? '网络连接超时' : null
      })
    }
    
    interactionData.value = mockData
    pagination.total = mockData.length
  } catch (error) {
    ElMessage.error('加载交互数据失败')
  } finally {
    loading.value = false
  }
}

const refreshData = async () => {
  await Promise.all([
    loadStatistics(),
    loadInteractionData()
  ])
  ElMessage.success('数据已刷新')
}

const exportData = () => {
  ElMessage.info('导出功能开发中...')
}

const handleSearch = () => {
  // 搜索逻辑已在计算属性中处理
}

const handleSortChange = ({ prop, order }) => {
  // 排序逻辑
  if (!order) return
  
  interactionData.value.sort((a, b) => {
    let aVal = a[prop]
    let bVal = b[prop]
    
    if (prop === 'timestamp') {
      aVal = new Date(aVal).getTime()
      bVal = new Date(bVal).getTime()
    }
    
    if (order === 'ascending') {
      return aVal > bVal ? 1 : -1
    } else {
      return aVal < bVal ? 1 : -1
    }
  })
}

const handleSizeChange = (size) => {
  pagination.pageSize = size
  loadInteractionData()
}

const handleCurrentChange = (page) => {
  pagination.currentPage = page
  loadInteractionData()
}

const viewDetails = (row) => {
  selectedInteraction.value = row
  detailDialogVisible.value = true
}

const formatDataSize = (bytes) => {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

const getInteractionTypeLabel = (type) => {
  const labels = {
    data_upload: '数据上报',
    command: '命令下发',
    heartbeat: '心跳包',
    config: '配置更新'
  }
  return labels[type] || type
}

const getInteractionDescription = (type, status) => {
  const descriptions = {
    data_upload: status === 'success' ? '设备数据上报成功' : '设备数据上报失败',
    command: status === 'success' ? '命令下发成功' : '命令下发失败',
    heartbeat: status === 'success' ? '心跳包正常' : '心跳包超时',
    config: status === 'success' ? '配置更新成功' : '配置更新失败'
  }
  return descriptions[type] || '未知操作'
}

const getStatusTagType = (status) => {
  return status === 'success' ? 'success' : 'danger'
}

const getTypeTagType = (type) => {
  const types = {
    data_upload: 'primary',
    command: 'warning',
    heartbeat: 'info',
    config: 'success'
  }
  return types[type] || 'info'
}

const getResponseTimeClass = (time) => {
  if (time < 200) return 'response-fast'
  if (time < 1000) return 'response-normal'
  return 'response-slow'
}

// 生命周期
onMounted(() => {
  loadDeviceList()
  loadStatistics()
  loadInteractionData()
})
</script>

<style scoped>
.device-interactions {
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 20px;
}

.header-content {
  flex: 1;
}

.page-title {
  font-size: 24px;
  font-weight: 600;
  color: #303133;
  margin: 0 0 8px 0;
  display: flex;
  align-items: center;
  gap: 8px;
}

.page-description {
  color: #606266;
  margin: 0;
  font-size: 14px;
}

.header-actions {
  display: flex;
  gap: 12px;
}

.stats-overview {
  margin-bottom: 20px;
}

.stat-card {
  height: 100px;
}

.stat-content {
  display: flex;
  align-items: center;
  height: 100%;
}

.stat-icon {
  width: 60px;
  height: 60px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 16px;
  font-size: 24px;
  color: white;
}

.stat-icon.total {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.stat-icon.success {
  background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
}

.stat-icon.data {
  background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
}

.stat-icon.time {
  background: linear-gradient(135deg, #fa709a 0%, #fee140 100%);
}

.stat-info {
  flex: 1;
}

.stat-value {
  font-size: 28px;
  font-weight: 600;
  color: #303133;
  line-height: 1;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 14px;
  color: #909399;
}

.filter-card {
  margin-bottom: 20px;
}

.table-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.device-info {
  display: flex;
  flex-direction: column;
}

.device-name {
  font-weight: 500;
  color: #303133;
}

.device-id {
  font-size: 12px;
  color: #909399;
  margin-top: 2px;
}

.response-fast {
  color: #67c23a;
  font-weight: 500;
}

.response-normal {
  color: #e6a23c;
  font-weight: 500;
}

.response-slow {
  color: #f56c6c;
  font-weight: 500;
}

.pagination-wrapper {
  display: flex;
  justify-content: center;
  margin-top: 20px;
}

.interaction-detail {
  padding: 20px 0;
}

.error-info {
  margin-top: 20px;
}

.error-info h4 {
  margin: 0 0 10px 0;
  color: #f56c6c;
}
</style>