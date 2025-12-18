<template>
  <el-card class="device-history-card" shadow="hover">
    <template #header>
      <div class="card-header">
        <div class="header-left">
          <el-icon size="20" color="#409EFF"><Document /></el-icon>
          <span class="header-title">历史记录</span>
        </div>
        <div class="header-actions">
          <el-button @click="refreshHistory" :icon="Refresh" size="small" circle />
          <el-button @click="exportHistory" :icon="Download" size="small" circle />
        </div>
      </div>
    </template>

    <div class="history-filters">
      <el-row :gutter="16">
        <el-col :span="8">
          <el-select v-model="filters.type" placeholder="记录类型" clearable @change="applyFilters">
            <el-option label="全部" value="" />
            <el-option label="数据记录" value="data" />
            <el-option label="控制记录" value="control" />
            <el-option label="状态变更" value="status" />
            <el-option label="系统事件" value="system" />
          </el-select>
        </el-col>
        <el-col :span="10">
          <el-date-picker
            v-model="filters.dateRange"
            type="datetimerange"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
            format="YYYY-MM-DD HH:mm"
            value-format="YYYY-MM-DD HH:mm:ss"
            @change="applyFilters"
          />
        </el-col>
        <el-col :span="6">
          <el-input
            v-model="filters.keyword"
            placeholder="搜索关键词"
            :prefix-icon="Search"
            clearable
            @input="debounceSearch"
          />
        </el-col>
      </el-row>
    </div>

    <div class="history-content" v-loading="loading">
      <div v-if="filteredHistory.length === 0" class="no-history">
        <el-empty description="暂无历史记录" />
      </div>

      <div v-else class="history-timeline">
        <div 
          v-for="record in paginatedHistory" 
          :key="record.id"
          class="timeline-item"
          :class="getTimelineItemClass(record)"
        >
          <div class="timeline-marker">
            <el-icon :size="16" :color="getMarkerColor(record.type)">
              <component :is="getRecordIcon(record.type)" />
            </el-icon>
          </div>
          
          <div class="timeline-content">
            <div class="record-header">
              <div class="record-title">{{ record.title }}</div>
              <div class="record-time">{{ formatDateTime(record.timestamp) }}</div>
            </div>
            
            <div class="record-description">{{ record.description }}</div>
            
            <div v-if="record.data" class="record-data">
              <el-tag 
                v-for="(value, key) in record.data" 
                :key="key"
                size="small"
                type="info"
                effect="plain"
                class="data-tag"
              >
                {{ key }}: {{ value }}
              </el-tag>
            </div>
            
            <div class="record-meta">
              <el-tag :type="getRecordTagType(record.type)" size="small">
                {{ getRecordTypeLabel(record.type) }}
              </el-tag>
              <span v-if="record.user" class="record-user">
                <el-icon size="12"><User /></el-icon>
                {{ record.user }}
              </span>
              <span v-if="record.source" class="record-source">
                来源: {{ record.source }}
              </span>
            </div>
          </div>
        </div>
      </div>

      <!-- 分页 -->
      <div v-if="filteredHistory.length > pageSize" class="history-pagination">
        <el-pagination
          v-model:current-page="currentPage"
          :page-size="pageSize"
          :total="filteredHistory.length"
          layout="prev, pager, next, jumper, total"
          @current-change="handlePageChange"
        />
      </div>
    </div>

    <!-- 统计信息 -->
    <div class="history-stats">
      <el-row :gutter="16">
        <el-col :span="6">
          <div class="stat-item">
            <div class="stat-value">{{ totalRecords }}</div>
            <div class="stat-label">总记录数</div>
          </div>
        </el-col>
        <el-col :span="6">
          <div class="stat-item">
            <div class="stat-value">{{ todayRecords }}</div>
            <div class="stat-label">今日记录</div>
          </div>
        </el-col>
        <el-col :span="6">
          <div class="stat-item">
            <div class="stat-value">{{ dataRecords }}</div>
            <div class="stat-label">数据记录</div>
          </div>
        </el-col>
        <el-col :span="6">
          <div class="stat-item">
            <div class="stat-value">{{ controlRecords }}</div>
            <div class="stat-label">控制记录</div>
          </div>
        </el-col>
      </el-row>
    </div>
  </el-card>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { 
  Document, Refresh, Download, Search, User,
  TrendCharts, Operation, Warning, InfoFilled, Clock
} from '@element-plus/icons-vue'

const props = defineProps({
  device: {
    type: Object,
    required: true
  },
  loading: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['refresh', 'export'])

// 响应式数据
const historyData = ref([])
const filters = ref({
  type: '',
  dateRange: null,
  keyword: ''
})
const currentPage = ref(1)
const pageSize = ref(20)
const searchTimeout = ref(null)

// 计算属性
const filteredHistory = computed(() => {
  let filtered = [...historyData.value]
  
  // 类型过滤
  if (filters.value.type) {
    filtered = filtered.filter(record => record.type === filters.value.type)
  }
  
  // 时间范围过滤
  if (filters.value.dateRange && filters.value.dateRange.length === 2) {
    const [startTime, endTime] = filters.value.dateRange
    filtered = filtered.filter(record => {
      const recordTime = new Date(record.timestamp)
      return recordTime >= new Date(startTime) && recordTime <= new Date(endTime)
    })
  }
  
  // 关键词过滤
  if (filters.value.keyword) {
    const keyword = filters.value.keyword.toLowerCase()
    filtered = filtered.filter(record => 
      record.title.toLowerCase().includes(keyword) ||
      record.description.toLowerCase().includes(keyword)
    )
  }
  
  return filtered.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
})

const paginatedHistory = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return filteredHistory.value.slice(start, end)
})

const totalRecords = computed(() => historyData.value.length)

const todayRecords = computed(() => {
  const today = new Date().toDateString()
  return historyData.value.filter(record => 
    new Date(record.timestamp).toDateString() === today
  ).length
})

const dataRecords = computed(() => 
  historyData.value.filter(record => record.type === 'data').length
)

const controlRecords = computed(() => 
  historyData.value.filter(record => record.type === 'control').length
)

// 方法
const getRecordIcon = (type) => {
  const iconMap = {
    'data': TrendCharts,
    'control': Operation,
    'status': Warning,
    'system': InfoFilled,
    'default': Clock
  }
  return iconMap[type] || iconMap.default
}

const getMarkerColor = (type) => {
  const colorMap = {
    'data': '#409EFF',
    'control': '#67C23A',
    'status': '#E6A23C',
    'system': '#909399'
  }
  return colorMap[type] || '#909399'
}

const getTimelineItemClass = (record) => {
  return `timeline-item-${record.type}`
}

const getRecordTagType = (type) => {
  const typeMap = {
    'data': 'primary',
    'control': 'success',
    'status': 'warning',
    'system': 'info'
  }
  return typeMap[type] || 'default'
}

const getRecordTypeLabel = (type) => {
  const labelMap = {
    'data': '数据记录',
    'control': '控制记录',
    'status': '状态变更',
    'system': '系统事件'
  }
  return labelMap[type] || type
}

const formatDateTime = (timestamp) => {
  if (!timestamp) return 'N/A'
  
  const date = new Date(timestamp)
  const now = new Date()
  const diffMs = now - date
  const diffMins = Math.floor(diffMs / 60000)
  const diffHours = Math.floor(diffMins / 60)
  const diffDays = Math.floor(diffHours / 24)
  
  if (diffMins < 1) return '刚刚'
  if (diffMins < 60) return `${diffMins}分钟前`
  if (diffHours < 24) return `${diffHours}小时前`
  if (diffDays < 7) return `${diffDays}天前`
  
  return date.toLocaleString('zh-CN')
}

const applyFilters = () => {
  currentPage.value = 1
}

const debounceSearch = () => {
  if (searchTimeout.value) {
    clearTimeout(searchTimeout.value)
  }
  
  searchTimeout.value = setTimeout(() => {
    applyFilters()
  }, 500)
}

const handlePageChange = (page) => {
  currentPage.value = page
}

const refreshHistory = () => {
  emit('refresh')
  loadHistoryData()
}

const exportHistory = () => {
  emit('export', filteredHistory.value)
  ElMessage.success('历史记录导出功能开发中...')
}

const loadHistoryData = () => {
  // 模拟历史数据
  const mockHistory = []
  const now = new Date()
  
  for (let i = 0; i < 100; i++) {
    const timestamp = new Date(now.getTime() - i * 3600000) // 每小时一条记录
    const types = ['data', 'control', 'status', 'system']
    const type = types[Math.floor(Math.random() * types.length)]
    
    let record = {
      id: i + 1,
      timestamp: timestamp.toISOString(),
      type: type
    }
    
    switch (type) {
      case 'data':
        record = {
          ...record,
          title: '传感器数据上报',
          description: '设备上报了最新的传感器数据',
          data: {
            '温度': `${(20 + Math.random() * 10).toFixed(1)}°C`,
            '湿度': `${(40 + Math.random() * 40).toFixed(1)}%`,
            '压力': `${(1000 + Math.random() * 100).toFixed(0)}hPa`
          },
          source: '传感器模块'
        }
        break
      case 'control':
        record = {
          ...record,
          title: '设备控制操作',
          description: '用户执行了设备控制命令',
          data: {
            '操作': Math.random() > 0.5 ? '开启' : '关闭',
            '端口': `GPIO${Math.floor(Math.random() * 8) + 1}`
          },
          user: 'admin',
          source: 'Web控制台'
        }
        break
      case 'status':
        record = {
          ...record,
          title: '设备状态变更',
          description: Math.random() > 0.5 ? '设备上线' : '设备离线',
          source: '状态监控'
        }
        break
      case 'system':
        record = {
          ...record,
          title: '系统事件',
          description: '设备固件更新完成',
          data: {
            '版本': 'v2.1.0',
            '大小': '1.2MB'
          },
          source: 'OTA服务'
        }
        break
    }
    
    mockHistory.push(record)
  }
  
  historyData.value = mockHistory
}

onMounted(() => {
  loadHistoryData()
})

watch(() => props.device, () => {
  loadHistoryData()
}, { deep: true })
</script>

<style scoped>
.device-history-card {
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

.header-actions {
  display: flex;
  gap: 8px;
}

.history-filters {
  margin-bottom: 20px;
  padding: 16px;
  background: rgba(255, 255, 255, 0.6);
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.no-history {
  padding: 40px 0;
}

.history-timeline {
  position: relative;
  padding-left: 30px;
}

.history-timeline::before {
  content: '';
  position: absolute;
  left: 15px;
  top: 0;
  bottom: 0;
  width: 2px;
  background: linear-gradient(to bottom, #409EFF, #e2e8f0);
}

.timeline-item {
  position: relative;
  margin-bottom: 24px;
  padding-bottom: 16px;
}

.timeline-marker {
  position: absolute;
  left: -22px;
  top: 4px;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: white;
  border: 2px solid #e2e8f0;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1;
}

.timeline-content {
  background: rgba(255, 255, 255, 0.8);
  border-radius: 12px;
  padding: 16px;
  border: 1px solid #e2e8f0;
  transition: all 0.3s ease;
}

.timeline-content:hover {
  transform: translateX(4px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.record-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 8px;
}

.record-title {
  font-size: 1rem;
  font-weight: 600;
  color: #1e293b;
}

.record-time {
  font-size: 0.85rem;
  color: #64748b;
  white-space: nowrap;
}

.record-description {
  font-size: 0.9rem;
  color: #475569;
  margin-bottom: 12px;
  line-height: 1.5;
}

.record-data {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-bottom: 12px;
}

.data-tag {
  font-size: 0.8rem;
}

.record-meta {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
}

.record-user, .record-source {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 0.8rem;
  color: #64748b;
}

.history-pagination {
  margin-top: 24px;
  display: flex;
  justify-content: center;
}

.history-stats {
  margin-top: 24px;
  padding-top: 20px;
  border-top: 1px solid #e2e8f0;
}

.stat-item {
  text-align: center;
  padding: 12px;
  background: rgba(255, 255, 255, 0.6);
  border-radius: 8px;
  border: 1px solid #e2e8f0;
}

.stat-value {
  font-size: 1.5rem;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 0.85rem;
  color: #64748b;
}

/* 不同类型的时间线项目样式 */
.timeline-item-data .timeline-marker {
  border-color: #409EFF;
  background: #f0f9ff;
}

.timeline-item-control .timeline-marker {
  border-color: #67C23A;
  background: #f0f9ff;
}

.timeline-item-status .timeline-marker {
  border-color: #E6A23C;
  background: #fefcf3;
}

.timeline-item-system .timeline-marker {
  border-color: #909399;
  background: #f8fafc;
}

@media (max-width: 768px) {
  .history-filters .el-row {
    flex-direction: column;
    gap: 12px;
  }
  
  .record-header {
    flex-direction: column;
    gap: 4px;
  }
  
  .record-meta {
    flex-direction: column;
    align-items: flex-start;
    gap: 6px;
  }
  
  .timeline-content {
    margin-left: -10px;
  }
}
</style>