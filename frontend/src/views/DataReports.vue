<template>
  <div class="data-reports-container">
    <div class="page-header">
      <h2>数据报告</h2>
      <div class="header-actions">
        <el-button @click="generateReport">
          <el-icon><Document /></el-icon>
          生成报告
        </el-button>
      </div>
    </div>

    <!-- 筛选条件 -->
    <el-card class="filter-card">
      <el-form :model="filterForm" inline>
        <el-form-item label="报告类型">
          <el-select v-model="filterForm.type" placeholder="选择报告类型">
            <el-option label="全部" value="" />
            <el-option label="设备状态报告" value="device_status" />
            <el-option label="数据统计报告" value="data_statistics" />
            <el-option label="告警分析报告" value="alert_analysis" />
            <el-option label="性能分析报告" value="performance" />
          </el-select>
        </el-form-item>
        <el-form-item label="时间范围">
          <el-date-picker
            v-model="filterForm.dateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            format="YYYY-MM-DD"
            value-format="YYYY-MM-DD"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="searchReports">查询</el-button>
          <el-button @click="resetFilter">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 报告列表 -->
    <el-card class="reports-card">
      <el-table :data="reports" style="width: 100%">
        <el-table-column prop="title" label="报告标题" />
        <el-table-column prop="type" label="报告类型">
          <template #default="{ row }">
            <el-tag :type="getTypeTagType(row.type)">{{ getTypeLabel(row.type) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="period" label="统计周期" />
        <el-table-column prop="createdAt" label="生成时间" />
        <el-table-column prop="status" label="状态">
          <template #default="{ row }">
            <el-tag :type="getStatusTagType(row.status)">{{ getStatusLabel(row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200">
          <template #default="{ row }">
            <el-button size="small" @click="viewReport(row)">查看</el-button>
            <el-button size="small" @click="downloadReport(row)">下载</el-button>
            <el-button size="small" type="danger" @click="deleteReport(row)">删除</el-button>
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

    <!-- 报告详情对话框 -->
    <el-dialog v-model="showReportDialog" :title="selectedReport?.title" width="80%">
      <div v-if="selectedReport" class="report-content">
        <div class="report-summary">
          <h3>报告摘要</h3>
          <p>{{ selectedReport.summary }}</p>
        </div>
        
        <div class="report-data">
          <h3>数据详情</h3>
          <el-descriptions :column="2" border>
            <el-descriptions-item label="统计周期">{{ selectedReport.period }}</el-descriptions-item>
            <el-descriptions-item label="数据点数">{{ selectedReport.dataPoints }}</el-descriptions-item>
            <el-descriptions-item label="设备数量">{{ selectedReport.deviceCount }}</el-descriptions-item>
            <el-descriptions-item label="告警数量">{{ selectedReport.alertCount }}</el-descriptions-item>
          </el-descriptions>
        </div>

        <div class="report-charts">
          <h3>图表分析</h3>
          <div class="chart-placeholder">
            图表内容区域 - {{ selectedReport.type }}
          </div>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Document } from '@element-plus/icons-vue'

const showReportDialog = ref(false)
const selectedReport = ref(null)
const currentPage = ref(1)
const pageSize = ref(10)
const total = ref(0)

const filterForm = reactive({
  type: '',
  dateRange: []
})

const reports = ref([
  {
    id: 1,
    title: '2024年1月设备状态报告',
    type: 'device_status',
    period: '2024-01-01 至 2024-01-31',
    createdAt: '2024-01-31 23:59:59',
    status: 'completed',
    summary: '本月设备整体运行状况良好，在线率达到98.5%',
    dataPoints: 125000,
    deviceCount: 150,
    alertCount: 23
  },
  {
    id: 2,
    title: '数据统计月报',
    type: 'data_statistics',
    period: '2024-01-01 至 2024-01-31',
    createdAt: '2024-01-31 18:30:00',
    status: 'completed',
    summary: '本月数据采集量稳定增长，数据质量良好',
    dataPoints: 89000,
    deviceCount: 150,
    alertCount: 12
  },
  {
    id: 3,
    title: '告警分析报告',
    type: 'alert_analysis',
    period: '2024-01-15 至 2024-01-31',
    createdAt: '2024-01-31 16:45:00',
    status: 'generating',
    summary: '正在生成告警分析报告...',
    dataPoints: 0,
    deviceCount: 0,
    alertCount: 0
  }
])

const getTypeLabel = (type) => {
  const labels = {
    device_status: '设备状态报告',
    data_statistics: '数据统计报告',
    alert_analysis: '告警分析报告',
    performance: '性能分析报告'
  }
  return labels[type] || type
}

const getTypeTagType = (type) => {
  const types = {
    device_status: 'primary',
    data_statistics: 'success',
    alert_analysis: 'warning',
    performance: 'info'
  }
  return types[type] || 'default'
}

const getStatusLabel = (status) => {
  const labels = {
    completed: '已完成',
    generating: '生成中',
    failed: '生成失败'
  }
  return labels[status] || status
}

const getStatusTagType = (status) => {
  const types = {
    completed: 'success',
    generating: 'warning',
    failed: 'danger'
  }
  return types[status] || 'default'
}

const generateReport = () => {
  ElMessage.info('报告生成功能开发中...')
}

const searchReports = () => {
  ElMessage.success('查询报告列表')
}

const resetFilter = () => {
  filterForm.type = ''
  filterForm.dateRange = []
  searchReports()
}

const viewReport = (report) => {
  selectedReport.value = report
  showReportDialog.value = true
}

const downloadReport = (report) => {
  ElMessage.success(`下载报告: ${report.title}`)
}

const deleteReport = async (report) => {
  try {
    await ElMessageBox.confirm(`确定要删除报告"${report.title}"吗？`, '确认删除', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    const index = reports.value.findIndex(item => item.id === report.id)
    if (index !== -1) {
      reports.value.splice(index, 1)
    }
    ElMessage.success('报告删除成功')
  } catch {
    // 用户取消操作
  }
}

const handleSizeChange = (val) => {
  pageSize.value = val
  searchReports()
}

const handleCurrentChange = (val) => {
  currentPage.value = val
  searchReports()
}

onMounted(() => {
  total.value = reports.value.length
})
</script>

<style scoped>
.data-reports-container {
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

.reports-card {
  margin-bottom: 20px;
}

.pagination {
  display: flex;
  justify-content: center;
  margin-top: 20px;
}

.report-content {
  padding: 20px 0;
}

.report-summary,
.report-data,
.report-charts {
  margin-bottom: 30px;
}

.report-summary h3,
.report-data h3,
.report-charts h3 {
  margin-bottom: 15px;
  color: #303133;
}

.chart-placeholder {
  height: 300px;
  background: #f8f9fa;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #999;
  font-size: 16px;
}
</style>