<template>
  <div class="system-logs-container">
    <div class="page-header">
      <h2>系统日志</h2>
      <div class="header-actions">
        <el-button @click="refreshLogs">
          <el-icon><Refresh /></el-icon>
          刷新
        </el-button>
        <el-button @click="clearLogs" type="danger">
          <el-icon><Delete /></el-icon>
          清空日志
        </el-button>
        <el-button @click="exportLogs">
          <el-icon><Download /></el-icon>
          导出日志
        </el-button>
      </div>
    </div>

    <!-- 筛选条件 -->
    <el-card class="filter-card">
      <el-form :model="filters" inline>
        <el-form-item label="日志级别">
          <el-select v-model="filters.level" placeholder="请选择日志级别" clearable>
            <el-option label="全部" value="" />
            <el-option label="DEBUG" value="DEBUG" />
            <el-option label="INFO" value="INFO" />
            <el-option label="WARNING" value="WARNING" />
            <el-option label="ERROR" value="ERROR" />
            <el-option label="CRITICAL" value="CRITICAL" />
          </el-select>
        </el-form-item>
        <el-form-item label="日志模块">
          <el-select v-model="filters.module" placeholder="请选择模块" clearable>
            <el-option label="全部" value="" />
            <el-option label="用户管理" value="user" />
            <el-option label="设备管理" value="device" />
            <el-option label="数据分析" value="data" />
            <el-option label="告警系统" value="alert" />
            <el-option label="系统管理" value="system" />
          </el-select>
        </el-form-item>
        <el-form-item label="时间范围">
          <el-date-picker
            v-model="filters.dateRange"
            type="datetimerange"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
            format="YYYY-MM-DD HH:mm:ss"
            value-format="YYYY-MM-DD HH:mm:ss"
          />
        </el-form-item>
        <el-form-item label="关键词">
          <el-input v-model="filters.keyword" placeholder="请输入关键词" clearable />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="searchLogs">
            <el-icon><Search /></el-icon>
            搜索
          </el-button>
          <el-button @click="resetFilters">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 日志统计 -->
    <el-row :gutter="20" class="stats-row">
      <el-col :span="6">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-value">{{ stats.total }}</div>
            <div class="stat-label">总日志数</div>
          </div>
          <el-icon class="stat-icon"><Document /></el-icon>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stat-card error">
          <div class="stat-content">
            <div class="stat-value">{{ stats.error }}</div>
            <div class="stat-label">错误日志</div>
          </div>
          <el-icon class="stat-icon"><Warning /></el-icon>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stat-card warning">
          <div class="stat-content">
            <div class="stat-value">{{ stats.warning }}</div>
            <div class="stat-label">警告日志</div>
          </div>
          <el-icon class="stat-icon"><InfoFilled /></el-icon>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stat-card info">
          <div class="stat-content">
            <div class="stat-value">{{ stats.info }}</div>
            <div class="stat-label">信息日志</div>
          </div>
          <el-icon class="stat-icon"><SuccessFilled /></el-icon>
        </el-card>
      </el-col>
    </el-row>

    <!-- 日志表格 -->
    <el-card class="table-card">
      <el-table :data="logs" v-loading="loading" stripe>
        <el-table-column prop="timestamp" label="时间" width="180" sortable>
          <template #default="{ row }">
            <span>{{ formatTime(row.timestamp) }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="level" label="级别" width="100">
          <template #default="{ row }">
            <el-tag :type="getLevelType(row.level)" size="small">
              {{ row.level }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="module" label="模块" width="120">
          <template #default="{ row }">
            <el-tag type="info" size="small">{{ row.module }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="user" label="用户" width="120" />
        <el-table-column prop="ip" label="IP地址" width="140" />
        <el-table-column prop="message" label="日志内容" min-width="300">
          <template #default="{ row }">
            <div class="log-message" @click="showLogDetail(row)">
              {{ row.message }}
            </div>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button size="small" @click="showLogDetail(row)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-container">
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

    <!-- 日志详情对话框 -->
    <el-dialog v-model="detailDialogVisible" title="日志详情" width="60%">
      <div v-if="selectedLog" class="log-detail">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="时间">
            {{ formatTime(selectedLog.timestamp) }}
          </el-descriptions-item>
          <el-descriptions-item label="级别">
            <el-tag :type="getLevelType(selectedLog.level)">
              {{ selectedLog.level }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="模块">
            {{ selectedLog.module }}
          </el-descriptions-item>
          <el-descriptions-item label="用户">
            {{ selectedLog.user || '系统' }}
          </el-descriptions-item>
          <el-descriptions-item label="IP地址">
            {{ selectedLog.ip || '-' }}
          </el-descriptions-item>
          <el-descriptions-item label="请求ID">
            {{ selectedLog.requestId || '-' }}
          </el-descriptions-item>
        </el-descriptions>
        
        <div class="log-content">
          <h4>日志内容</h4>
          <pre>{{ selectedLog.message }}</pre>
        </div>
        
        <div v-if="selectedLog.stackTrace" class="stack-trace">
          <h4>堆栈跟踪</h4>
          <pre>{{ selectedLog.stackTrace }}</pre>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { 
  Refresh, 
  Delete, 
  Download, 
  Search, 
  Document, 
  Warning, 
  InfoFilled, 
  SuccessFilled 
} from '@element-plus/icons-vue'

const loading = ref(false)
const detailDialogVisible = ref(false)
const selectedLog = ref(null)

const filters = reactive({
  level: '',
  module: '',
  dateRange: [],
  keyword: ''
})

const stats = reactive({
  total: 1250,
  error: 23,
  warning: 156,
  info: 1071
})

const pagination = reactive({
  currentPage: 1,
  pageSize: 20,
  total: 1250
})

const logs = ref([
  {
    id: 1,
    timestamp: '2024-01-15 10:30:25',
    level: 'INFO',
    module: 'user',
    user: 'admin',
    ip: '192.168.1.100',
    message: '用户登录成功',
    requestId: 'req-001'
  },
  {
    id: 2,
    timestamp: '2024-01-15 10:28:15',
    level: 'ERROR',
    module: 'device',
    user: 'system',
    ip: '192.168.1.50',
    message: '设备连接失败: 设备ID DEV001 连接超时',
    requestId: 'req-002',
    stackTrace: 'ConnectionTimeoutError: Device DEV001 connection timeout\n  at DeviceManager.connect(device.py:45)\n  at DeviceService.checkStatus(service.py:123)'
  },
  {
    id: 3,
    timestamp: '2024-01-15 10:25:30',
    level: 'WARNING',
    module: 'data',
    user: 'system',
    ip: '192.168.1.50',
    message: '数据采集延迟: 传感器 SEN001 数据采集延迟超过阈值',
    requestId: 'req-003'
  },
  {
    id: 4,
    timestamp: '2024-01-15 10:20:45',
    level: 'INFO',
    module: 'alert',
    user: 'system',
    ip: '192.168.1.50',
    message: '告警规则触发: 温度超过阈值',
    requestId: 'req-004'
  },
  {
    id: 5,
    timestamp: '2024-01-15 10:15:12',
    level: 'DEBUG',
    module: 'system',
    user: 'admin',
    ip: '192.168.1.100',
    message: '系统配置更新: 邮件服务器配置已更新',
    requestId: 'req-005'
  }
])

const getLevelType = (level) => {
  const types = {
    'DEBUG': '',
    'INFO': 'success',
    'WARNING': 'warning',
    'ERROR': 'danger',
    'CRITICAL': 'danger'
  }
  return types[level] || ''
}

const formatTime = (timestamp) => {
  return timestamp
}

const searchLogs = () => {
  loading.value = true
  setTimeout(() => {
    loading.value = false
    ElMessage.success('搜索完成')
  }, 1000)
}

const resetFilters = () => {
  filters.level = ''
  filters.module = ''
  filters.dateRange = []
  filters.keyword = ''
  searchLogs()
}

const refreshLogs = () => {
  loading.value = true
  setTimeout(() => {
    loading.value = false
    ElMessage.success('日志已刷新')
  }, 1000)
}

const clearLogs = () => {
  ElMessageBox.confirm(
    '确定要清空所有日志吗？此操作不可恢复。',
    '警告',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    }
  ).then(() => {
    ElMessage.success('日志已清空')
  })
}

const exportLogs = () => {
  ElMessage.info('正在导出日志...')
  setTimeout(() => {
    ElMessage.success('日志导出成功')
  }, 2000)
}

const showLogDetail = (log) => {
  selectedLog.value = log
  detailDialogVisible.value = true
}

const handleSizeChange = (size) => {
  pagination.pageSize = size
  searchLogs()
}

const handleCurrentChange = (page) => {
  pagination.currentPage = page
  searchLogs()
}

onMounted(() => {
  searchLogs()
})
</script>

<style scoped>
.system-logs-container {
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

.filter-card {
  margin-bottom: 20px;
}

.stats-row {
  margin-bottom: 20px;
}

.stat-card {
  position: relative;
  overflow: hidden;
}

.stat-card.error {
  border-left: 4px solid #f56c6c;
}

.stat-card.warning {
  border-left: 4px solid #e6a23c;
}

.stat-card.info {
  border-left: 4px solid #67c23a;
}

.stat-content {
  position: relative;
  z-index: 2;
}

.stat-value {
  font-size: 24px;
  font-weight: bold;
  color: #303133;
  margin-bottom: 5px;
}

.stat-label {
  font-size: 14px;
  color: #909399;
}

.stat-icon {
  position: absolute;
  right: 20px;
  top: 50%;
  transform: translateY(-50%);
  font-size: 40px;
  color: #e4e7ed;
  z-index: 1;
}

.table-card {
  margin-bottom: 20px;
}

.log-message {
  cursor: pointer;
  max-width: 300px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.log-message:hover {
  color: #409eff;
}

.pagination-container {
  display: flex;
  justify-content: center;
  margin-top: 20px;
}

.log-detail {
  padding: 20px 0;
}

.log-content,
.stack-trace {
  margin-top: 20px;
}

.log-content h4,
.stack-trace h4 {
  margin-bottom: 10px;
  color: #303133;
}

.log-content pre,
.stack-trace pre {
  background-color: #f5f7fa;
  padding: 15px;
  border-radius: 4px;
  font-size: 13px;
  line-height: 1.5;
  white-space: pre-wrap;
  word-wrap: break-word;
}

.stack-trace pre {
  background-color: #fef0f0;
  color: #f56c6c;
}
</style>