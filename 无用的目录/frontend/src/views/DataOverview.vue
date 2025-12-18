<template>
  <div class="data-overview-container">
    <div class="page-header">
      <h2>数据概览</h2>
      <div class="time-range-selector">
        <el-select v-model="timeRange" @change="handleTimeRangeChange">
          <el-option label="最近1小时" value="1h" />
          <el-option label="最近24小时" value="24h" />
          <el-option label="最近7天" value="7d" />
          <el-option label="最近30天" value="30d" />
        </el-select>
      </div>
    </div>

    <!-- 统计卡片 -->
    <el-row :gutter="20" class="stats-cards">
      <el-col :span="6">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-icon temperature">
              <el-icon><TrendCharts /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ formatNumber(stats.totalDataPoints) }}</div>
              <div class="stat-label">总数据点</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-icon online">
              <el-icon><DataLine /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ formatNumber(stats.avgDataRate) }}</div>
              <div class="stat-label">平均数据率/分钟</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-icon offline">
              <el-icon><Warning /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ formatNumber(stats.anomalies) }}</div>
              <div class="stat-label">异常数据</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card class="stat-card">
          <div class="stat-content">
            <div class="stat-icon alerts">
              <el-icon><Connection /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ formatNumber(stats.activeStreams) }}</div>
              <div class="stat-label">活跃数据流</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 数据趋势图表 -->
    <el-row :gutter="20" class="charts-row">
      <el-col :span="12">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>数据量趋势</span>
              <el-button size="small" @click="refreshChart('dataVolume')">刷新</el-button>
            </div>
          </template>
          <div ref="dataVolumeChart" class="chart-container"></div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>设备数据分布</span>
              <el-button size="small" @click="refreshChart('deviceDistribution')">刷新</el-button>
            </div>
          </template>
          <div ref="deviceDistributionChart" class="chart-container"></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 实时数据表格 -->
    <el-card class="recent-data-card">
      <template #header>
        <div class="card-header">
          <span>最新数据</span>
          <div>
            <el-button size="small" @click="refreshRecentData">刷新</el-button>
            <el-button size="small" type="primary" @click="exportData">导出数据</el-button>
          </div>
        </div>
      </template>
      
      <el-table :data="recentData" style="width: 100%" v-loading="loading">
        <el-table-column prop="timestamp" label="时间戳" width="180">
          <template #default="scope">
            {{ formatDate(scope.row.timestamp) }}
          </template>
        </el-table-column>
        <el-table-column prop="device_name" label="设备名称" />
        <el-table-column prop="data_type" label="数据类型" />
        <el-table-column prop="value" label="数值" />
        <el-table-column prop="unit" label="单位" width="80" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="scope">
            <el-tag :type="getStatusType(scope.row.status)">
              {{ getStatusLabel(scope.row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120">
          <template #default="scope">
            <el-button size="small" @click="viewDataDetail(scope.row)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination-container">
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

    <!-- 数据详情对话框 -->
    <el-dialog v-model="showDetailDialog" title="数据详情" width="600px">
      <el-descriptions :column="2" border>
        <el-descriptions-item label="设备名称">{{ selectedData?.device_name }}</el-descriptions-item>
        <el-descriptions-item label="数据类型">{{ selectedData?.data_type }}</el-descriptions-item>
        <el-descriptions-item label="数值">{{ selectedData?.value }}</el-descriptions-item>
        <el-descriptions-item label="单位">{{ selectedData?.unit }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="getStatusType(selectedData?.status)">
            {{ getStatusLabel(selectedData?.status) }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="时间戳">{{ formatDate(selectedData?.timestamp) }}</el-descriptions-item>
        <el-descriptions-item label="设备位置" :span="2">{{ selectedData?.location }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ selectedData?.remarks || '无' }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, nextTick } from 'vue'
import { ElMessage } from 'element-plus'
import { TrendCharts, DataLine, Warning, Connection } from '@element-plus/icons-vue'

// 响应式数据
const loading = ref(false)
const timeRange = ref('24h')
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)
const showDetailDialog = ref(false)
const selectedData = ref(null)

// 图表引用
const dataVolumeChart = ref()
const deviceDistributionChart = ref()

// 统计数据（初始化为0，从后端获取）
const stats = reactive({
  totalDataPoints: 0,
  avgDataRate: 0,
  anomalies: 0,
  activeStreams: 0
})

// 最新数据（初始化为空数组，从后端获取）
const recentData = ref([])

// 方法
const handleTimeRangeChange = (value) => {
  timeRange.value = value
  refreshCharts()
  refreshRecentData()
}

const refreshChart = (chartType) => {
  ElMessage.success(`${chartType === 'dataVolume' ? '数据量趋势' : '设备数据分布'}图表已刷新`)
  // 这里可以添加实际的图表刷新逻辑
}

const refreshCharts = () => {
  // 刷新所有图表
  refreshChart('dataVolume')
  refreshChart('deviceDistribution')
}

const refreshRecentData = () => {
  loading.value = true
  // 模拟数据刷新
  setTimeout(() => {
    ElMessage.success('数据已刷新')
    loading.value = false
  }, 1000)
}

const exportData = () => {
  ElMessage.success('数据导出功能开发中...')
  // 这里可以添加实际的数据导出逻辑
}

const viewDataDetail = (data) => {
  selectedData.value = data
  showDetailDialog.value = true
}

const getStatusType = (status) => {
  const types = {
    normal: 'success',
    warning: 'warning',
    error: 'danger'
  }
  return types[status] || ''
}

const getStatusLabel = (status) => {
  const labels = {
    normal: '正常',
    warning: '警告',
    error: '异常'
  }
  return labels[status] || status
}

const handleSizeChange = (val) => {
  pageSize.value = val
  currentPage.value = 1
}

const handleCurrentChange = (val) => {
  currentPage.value = val
}

const formatDate = (dateString) => {
  if (!dateString) return '-'
  return new Date(dateString).toLocaleString('zh-CN')
}

const formatNumber = (num) => {
  if (num === null || num === undefined) return '0'
  if (typeof num === 'string') return num
  return num.toLocaleString('zh-CN')
}

// 初始化图表（这里使用模拟数据，实际项目中可以使用 ECharts 等图表库）
const initCharts = () => {
  nextTick(() => {
    // 模拟图表初始化
    if (dataVolumeChart.value) {
      dataVolumeChart.value.innerHTML = '<div style="height: 300px; display: flex; align-items: center; justify-content: center; color: #999;">数据量趋势图表区域</div>'
    }
    if (deviceDistributionChart.value) {
      deviceDistributionChart.value.innerHTML = '<div style="height: 300px; display: flex; align-items: center; justify-content: center; color: #999;">设备数据分布图表区域</div>'
    }
  })
}

onMounted(() => {
  // 初始化：统计数据为0，最近数据为空数组
  total.value = 0
  recentData.value = []
  initCharts()
})
</script>

<style scoped>
.data-overview-container {
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

.stats-cards {
  margin-bottom: 20px;
}

.stat-card {
  height: 120px;
}

.stat-content {
  display: flex;
  align-items: center;
  height: 100%;
}

.stat-icon {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 15px;
  font-size: 24px;
  color: white;
}

.stat-icon.temperature {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.stat-icon.online {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
}

.stat-icon.offline {
  background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
}

.stat-icon.alerts {
  background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
}

.stat-info {
  flex: 1;
}

.stat-value {
  font-size: 28px;
  font-weight: bold;
  color: #303133;
  line-height: 1;
}

.stat-label {
  font-size: 14px;
  color: #909399;
  margin-top: 5px;
}

.charts-row {
  margin-bottom: 20px;
}

.chart-container {
  height: 300px;
  background: #f8f9fa;
  border-radius: 4px;
}

.recent-data-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.pagination-container {
  margin-top: 20px;
  text-align: right;
}
</style>