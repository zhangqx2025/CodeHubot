<template>
  <div class="alert-history-container">
    <div class="page-header">
      <h2>告警历史</h2>
      <div class="header-actions">
        <el-button @click="exportHistory">
          <el-icon><Download /></el-icon>
          导出历史
        </el-button>
      </div>
    </div>

    <!-- 筛选条件 -->
    <el-card class="filter-card">
      <el-form :model="filterForm" inline>
        <el-form-item label="时间范围">
          <el-date-picker
            v-model="filterForm.dateRange"
            type="datetimerange"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
            format="YYYY-MM-DD HH:mm:ss"
            value-format="YYYY-MM-DD HH:mm:ss"
          />
        </el-form-item>
        <el-form-item label="告警级别">
          <el-select v-model="filterForm.level" placeholder="选择告警级别">
            <el-option label="全部" value="" />
            <el-option label="严重" value="critical" />
            <el-option label="警告" value="warning" />
            <el-option label="信息" value="info" />
          </el-select>
        </el-form-item>
        <el-form-item label="设备">
          <el-input v-model="filterForm.deviceName" placeholder="输入设备名称" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="searchHistory">查询</el-button>
          <el-button @click="resetFilter">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 统计信息 -->
    <el-row :gutter="20" class="stats-row">
      <el-col :span="6">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-number">{{ stats.total }}</div>
            <div class="stat-label">总告警数</div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stat-card critical">
          <div class="stat-content">
            <div class="stat-number">{{ stats.critical }}</div>
            <div class="stat-label">严重告警</div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stat-card warning">
          <div class="stat-content">
            <div class="stat-number">{{ stats.warning }}</div>
            <div class="stat-label">警告告警</div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stat-card resolved">
          <div class="stat-content">
            <div class="stat-number">{{ stats.resolved }}</div>
            <div class="stat-label">已处理</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 历史记录列表 -->
    <el-card class="history-card">
      <el-table :data="historyList" style="width: 100%">
        <el-table-column prop="level" label="级别" width="80">
          <template #default="{ row }">
            <el-tag :type="getLevelTagType(row.level)">{{ getLevelLabel(row.level) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="title" label="告警标题" />
        <el-table-column prop="deviceName" label="设备名称" />
        <el-table-column prop="message" label="告警内容" show-overflow-tooltip />
        <el-table-column prop="createdAt" label="发生时间" width="180" />
        <el-table-column prop="resolvedAt" label="处理时间" width="180">
          <template #default="{ row }">
            {{ row.resolvedAt || '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="duration" label="持续时间" width="120">
          <template #default="{ row }">
            {{ calculateDuration(row) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="100">
          <template #default="{ row }">
            <el-button size="small" @click="viewHistory(row)">查看</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50, 100]"
          :total="total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 历史详情对话框 -->
    <el-dialog v-model="showHistoryDialog" :title="selectedHistory?.title" width="600px">
      <div v-if="selectedHistory" class="history-detail">
        <el-descriptions :column="1" border>
          <el-descriptions-item label="告警级别">
            <el-tag :type="getLevelTagType(selectedHistory.level)">{{ getLevelLabel(selectedHistory.level) }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="设备名称">{{ selectedHistory.deviceName }}</el-descriptions-item>
          <el-descriptions-item label="设备ID">{{ selectedHistory.deviceId }}</el-descriptions-item>
          <el-descriptions-item label="告警内容">{{ selectedHistory.message }}</el-descriptions-item>
          <el-descriptions-item label="发生时间">{{ selectedHistory.createdAt }}</el-descriptions-item>
          <el-descriptions-item label="处理时间">{{ selectedHistory.resolvedAt || '未处理' }}</el-descriptions-item>
          <el-descriptions-item label="持续时间">{{ calculateDuration(selectedHistory) }}</el-descriptions-item>
          <el-descriptions-item label="处理人">{{ selectedHistory.resolvedBy || '-' }}</el-descriptions-item>
          <el-descriptions-item label="详细信息">{{ selectedHistory.details }}</el-descriptions-item>
        </el-descriptions>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Download } from '@element-plus/icons-vue'

const showHistoryDialog = ref(false)
const selectedHistory = ref(null)
const currentPage = ref(1)
const pageSize = ref(10)
const total = ref(0)

const filterForm = reactive({
  dateRange: [],
  level: '',
  deviceName: ''
})

const stats = ref({
  total: 156,
  critical: 23,
  warning: 89,
  resolved: 134
})

const historyList = ref([
  {
    id: 1,
    level: 'critical',
    title: '设备离线告警',
    deviceName: '温度传感器-001',
    deviceId: 'TEMP_001',
    message: '设备已离线超过5分钟',
    details: '设备在2024-01-15 14:30:00失去连接，网络故障导致',
    createdAt: '2024-01-15 14:35:00',
    resolvedAt: '2024-01-15 15:20:00',
    resolvedBy: '张三',
    duration: '45分钟'
  },
  {
    id: 2,
    level: 'warning',
    title: '温度异常告警',
    deviceName: '温度传感器-002',
    deviceId: 'TEMP_002',
    message: '温度超过阈值35°C',
    details: '当前温度37.5°C，超过设定阈值35°C',
    createdAt: '2024-01-15 13:20:00',
    resolvedAt: '2024-01-15 13:45:00',
    resolvedBy: '李四',
    duration: '25分钟'
  },
  {
    id: 3,
    level: 'info',
    title: '设备重启通知',
    deviceName: '湿度传感器-001',
    deviceId: 'HUM_001',
    message: '设备已自动重启',
    details: '设备检测到异常后自动重启，现已恢复正常运行',
    createdAt: '2024-01-15 12:15:00',
    resolvedAt: '2024-01-15 12:16:00',
    resolvedBy: '系统',
    duration: '1分钟'
  }
])

const getLevelLabel = (level) => {
  const labels = {
    critical: '严重',
    warning: '警告',
    info: '信息'
  }
  return labels[level] || level
}

const getLevelTagType = (level) => {
  const types = {
    critical: 'danger',
    warning: 'warning',
    info: 'info'
  }
  return types[level] || 'default'
}

const calculateDuration = (record) => {
  if (record.duration) {
    return record.duration
  }
  
  if (!record.resolvedAt) {
    return '未处理'
  }
  
  // 这里可以计算实际的持续时间
  return '计算中...'
}

const searchHistory = () => {
  ElMessage.success('查询告警历史')
}

const resetFilter = () => {
  filterForm.dateRange = []
  filterForm.level = ''
  filterForm.deviceName = ''
  searchHistory()
}

const exportHistory = () => {
  ElMessage.success('导出告警历史数据')
}

const viewHistory = (history) => {
  selectedHistory.value = history
  showHistoryDialog.value = true
}

const handleSizeChange = (val) => {
  pageSize.value = val
  searchHistory()
}

const handleCurrentChange = (val) => {
  currentPage.value = val
  searchHistory()
}

onMounted(() => {
  total.value = historyList.value.length
})
</script>

<style scoped>
.alert-history-container {
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
  text-align: center;
}

.stat-card.critical {
  border-left: 4px solid #f56c6c;
}

.stat-card.warning {
  border-left: 4px solid #e6a23c;
}

.stat-card.resolved {
  border-left: 4px solid #67c23a;
}

.stat-content {
  padding: 10px;
}

.stat-number {
  font-size: 28px;
  font-weight: bold;
  color: #303133;
  margin-bottom: 5px;
}

.stat-label {
  font-size: 14px;
  color: #909399;
}

.history-card {
  margin-bottom: 20px;
}

.pagination {
  display: flex;
  justify-content: center;
  margin-top: 20px;
}

.history-detail {
  padding: 20px 0;
}
</style>