<template>
  <div class="alerts-container">
    <div class="page-header">
      <h2>告警管理</h2>
      <div class="header-actions">
        <el-button @click="markAllAsRead">
          <el-icon><Check /></el-icon>
          全部已读
        </el-button>
      </div>
    </div>

    <!-- 筛选条件 -->
    <el-card class="filter-card">
      <el-form :model="filterForm" inline>
        <el-form-item label="告警级别">
          <el-select v-model="filterForm.level" placeholder="选择告警级别">
            <el-option label="全部" value="" />
            <el-option label="严重" value="critical" />
            <el-option label="警告" value="warning" />
            <el-option label="信息" value="info" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="filterForm.status" placeholder="选择状态">
            <el-option label="全部" value="" />
            <el-option label="未读" value="unread" />
            <el-option label="已读" value="read" />
            <el-option label="已处理" value="resolved" />
          </el-select>
        </el-form-item>
        <el-form-item label="设备">
          <el-input v-model="filterForm.deviceName" placeholder="输入设备名称" />
        </el-form-item>
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
        <el-form-item>
          <el-button type="primary" @click="searchAlerts">查询</el-button>
          <el-button @click="resetFilter">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 告警列表 -->
    <el-card class="alerts-card">
      <el-table :data="alerts" style="width: 100%" @selection-change="handleSelectionChange">
        <el-table-column type="selection" width="55" />
        <el-table-column prop="level" label="级别" width="80">
          <template #default="{ row }">
            <el-tag :type="getLevelTagType(row.level)">{{ getLevelLabel(row.level) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="title" label="告警标题" />
        <el-table-column prop="deviceName" label="设备名称" />
        <el-table-column prop="message" label="告警内容" show-overflow-tooltip />
        <el-table-column prop="createdAt" label="发生时间" width="180" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusTagType(row.status)">{{ getStatusLabel(row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200">
          <template #default="{ row }">
            <el-button size="small" @click="viewAlert(row)">查看</el-button>
            <el-button v-if="row.status === 'unread'" size="small" @click="markAsRead(row)">标记已读</el-button>
            <el-button v-if="row.status !== 'resolved'" size="small" type="success" @click="resolveAlert(row)">处理</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="table-footer">
        <div class="batch-actions">
          <el-button :disabled="selectedAlerts.length === 0" @click="batchMarkAsRead">批量已读</el-button>
          <el-button :disabled="selectedAlerts.length === 0" @click="batchResolve">批量处理</el-button>
        </div>
        
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

    <!-- 告警详情对话框 -->
    <el-dialog v-model="showAlertDialog" :title="selectedAlert?.title" width="600px">
      <div v-if="selectedAlert" class="alert-detail">
        <el-descriptions :column="1" border>
          <el-descriptions-item label="告警级别">
            <el-tag :type="getLevelTagType(selectedAlert.level)">{{ getLevelLabel(selectedAlert.level) }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="设备名称">{{ selectedAlert.deviceName }}</el-descriptions-item>
          <el-descriptions-item label="设备ID">{{ selectedAlert.deviceId }}</el-descriptions-item>
          <el-descriptions-item label="告警内容">{{ selectedAlert.message }}</el-descriptions-item>
          <el-descriptions-item label="发生时间">{{ selectedAlert.createdAt }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="getStatusTagType(selectedAlert.status)">{{ getStatusLabel(selectedAlert.status) }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="详细信息">{{ selectedAlert.details }}</el-descriptions-item>
        </el-descriptions>
      </div>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="showAlertDialog = false">关闭</el-button>
          <el-button v-if="selectedAlert?.status !== 'resolved'" type="primary" @click="resolveSelectedAlert">处理告警</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Check } from '@element-plus/icons-vue'

const showAlertDialog = ref(false)
const selectedAlert = ref(null)
const selectedAlerts = ref([])
const currentPage = ref(1)
const pageSize = ref(10)
const total = ref(0)

const filterForm = reactive({
  level: '',
  status: '',
  deviceName: '',
  dateRange: []
})

const alerts = ref([
  {
    id: 1,
    level: 'critical',
    title: '设备离线告警',
    deviceName: '温度传感器-001',
    deviceId: 'TEMP_001',
    message: '设备已离线超过5分钟',
    details: '设备在2024-01-15 14:30:00失去连接，可能是网络问题或设备故障',
    createdAt: '2024-01-15 14:35:00',
    status: 'unread'
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
    status: 'read'
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
    status: 'resolved'
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

const getStatusLabel = (status) => {
  const labels = {
    unread: '未读',
    read: '已读',
    resolved: '已处理'
  }
  return labels[status] || status
}

const getStatusTagType = (status) => {
  const types = {
    unread: 'danger',
    read: 'warning',
    resolved: 'success'
  }
  return types[status] || 'default'
}

const searchAlerts = () => {
  ElMessage.success('查询告警列表')
}

const resetFilter = () => {
  filterForm.level = ''
  filterForm.status = ''
  filterForm.deviceName = ''
  filterForm.dateRange = []
  searchAlerts()
}

const viewAlert = (alert) => {
  selectedAlert.value = alert
  showAlertDialog.value = true
  
  // 查看时自动标记为已读
  if (alert.status === 'unread') {
    markAsRead(alert)
  }
}

const markAsRead = (alert) => {
  alert.status = 'read'
  ElMessage.success('已标记为已读')
}

const resolveAlert = (alert) => {
  alert.status = 'resolved'
  ElMessage.success('告警已处理')
}

const resolveSelectedAlert = () => {
  if (selectedAlert.value) {
    resolveAlert(selectedAlert.value)
    showAlertDialog.value = false
  }
}

const markAllAsRead = () => {
  alerts.value.forEach(alert => {
    if (alert.status === 'unread') {
      alert.status = 'read'
    }
  })
  ElMessage.success('所有告警已标记为已读')
}

const handleSelectionChange = (selection) => {
  selectedAlerts.value = selection
}

const batchMarkAsRead = () => {
  selectedAlerts.value.forEach(alert => {
    if (alert.status === 'unread') {
      alert.status = 'read'
    }
  })
  ElMessage.success(`已标记${selectedAlerts.value.length}条告警为已读`)
}

const batchResolve = () => {
  selectedAlerts.value.forEach(alert => {
    if (alert.status !== 'resolved') {
      alert.status = 'resolved'
    }
  })
  ElMessage.success(`已处理${selectedAlerts.value.length}条告警`)
}

const handleSizeChange = (val) => {
  pageSize.value = val
  searchAlerts()
}

const handleCurrentChange = (val) => {
  currentPage.value = val
  searchAlerts()
}

onMounted(() => {
  total.value = alerts.value.length
})
</script>

<style scoped>
.alerts-container {
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

.alerts-card {
  margin-bottom: 20px;
}

.table-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 20px;
}

.batch-actions {
  display: flex;
  gap: 10px;
}

.alert-detail {
  padding: 20px 0;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}
</style>