<template>
  <div class="device-interaction-stats">
    <el-card class="interaction-card" shadow="hover">
      <template #header>
        <div class="card-header">
          <el-icon size="20" color="#409EFF"><Connection /></el-icon>
          <span>设备交互数据</span>
          <div class="card-actions">
            <el-select v-model="interactionTimeRange" placeholder="选择时间范围" size="small" style="width: 150px">
              <el-option label="今天" value="today" />
              <el-option label="最近7天" value="week" />
              <el-option label="最近30天" value="month" />
            </el-select>
            <el-button size="small" type="text" @click="refreshInteractionData">
              <el-icon><Refresh /></el-icon>
              刷新
            </el-button>
          </div>
        </div>
      </template>
      
      <!-- 交互统计概览 -->
      <div class="interaction-stats">
        <div class="stats-grid">
          <div class="stat-item">
            <div class="stat-icon online">
              <el-icon><Connection /></el-icon>
            </div>
            <div class="stat-content">
              <div class="stat-value">{{ deviceInfo.today_interactions || 0 }}</div>
              <div class="stat-label">今日交互次数</div>
            </div>
          </div>
          <div class="stat-item">
            <div class="stat-icon data">
              <el-icon><DataBoard /></el-icon>
            </div>
            <div class="stat-content">
              <div class="stat-value">{{ formatDataSize(deviceInfo.data_transferred || 0) }}</div>
              <div class="stat-label">今日数据传输</div>
            </div>
          </div>
          <div class="stat-item">
            <div class="stat-icon success">
              <el-icon><CircleCheck /></el-icon>
            </div>
            <div class="stat-content">
              <div class="stat-value">{{ deviceInfo.success_rate || '99.5' }}%</div>
              <div class="stat-label">通信成功率</div>
            </div>
          </div>
          <div class="stat-item">
            <div class="stat-icon response">
              <el-icon><Timer /></el-icon>
            </div>
            <div class="stat-content">
              <div class="stat-value">{{ deviceInfo.avg_response_time || '120' }}ms</div>
              <div class="stat-label">平均响应时间</div>
            </div>
          </div>
        </div>
      </div>

      <!-- 交互历史记录 -->
      <div class="interaction-history" style="margin-top: 24px;">
        <h4>交互历史记录</h4>
        <el-table :data="interactionLogs" style="width: 100%" max-height="400" v-loading="interactionLoading">
          <el-table-column prop="timestamp" label="时间" width="180">
            <template #default="scope">
              {{ formatTime(scope.row.timestamp) }}
            </template>
          </el-table-column>
          <el-table-column prop="type" label="交互类型" width="120">
            <template #default="scope">
              <el-tag :type="getInteractionTypeColor(scope.row.type)" size="small">
                {{ scope.row.type }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="status" label="状态" width="100">
            <template #default="scope">
              <el-tag :type="scope.row.status === 'success' ? 'success' : 'danger'" size="small">
                {{ scope.row.status === 'success' ? '成功' : '失败' }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="data_size" label="数据大小" width="120">
            <template #default="scope">
              {{ formatDataSize(scope.row.data_size) }}
            </template>
          </el-table-column>
          <el-table-column prop="response_time" label="响应时间" width="120">
            <template #default="scope">
              {{ scope.row.response_time }}ms
            </template>
          </el-table-column>
          <el-table-column prop="description" label="描述" min-width="200" />
          <el-table-column label="操作" width="100">
            <template #default="scope">
              <el-button type="text" size="small" @click="viewInteractionDetail(scope.row)">
                详情
              </el-button>
            </template>
          </el-table-column>
        </el-table>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { 
  Connection, Refresh, DataBoard, CircleCheck, Timer
} from '@element-plus/icons-vue'

// Props
const props = defineProps({
  deviceInfo: {
    type: Object,
    required: true
  }
})

// 响应式数据
const interactionTimeRange = ref('today')
const interactionLogs = ref([])
const interactionLoading = ref(false)

// 方法
const refreshInteractionData = async () => {
  interactionLoading.value = true
  try {
    await loadInteractionHistory()
    ElMessage.success('交互数据已刷新')
  } catch (error) {
    ElMessage.error('刷新交互数据失败')
  } finally {
    interactionLoading.value = false
  }
}

const loadInteractionHistory = async () => {
  try {
    // 模拟加载交互历史数据
    const interactionTypes = ['数据上报', '命令执行', '状态查询', '配置更新', '固件升级']
    const logs = []
    
    for (let i = 0; i < 10; i++) {
      const time = new Date(Date.now() - i * 30 * 60 * 1000) // 每30分钟一条记录
      logs.push({
        id: i + 1,
        timestamp: time.toISOString(),
        type: interactionTypes[Math.floor(Math.random() * interactionTypes.length)],
        status: Math.random() > 0.1 ? 'success' : 'failed',
        data_size: Math.floor(Math.random() * 10000) + 100,
        response_time: Math.floor(Math.random() * 500) + 50,
        description: `设备交互记录 #${i + 1}`
      })
    }
    
    interactionLogs.value = logs
  } catch (error) {
    ElMessage.error('加载交互历史失败')
  }
}

const formatTime = (timestamp) => {
  return new Date(timestamp).toLocaleString('zh-CN')
}

const formatDataSize = (bytes) => {
  if (!bytes) return '0 B'
  
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(1024))
  return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i]
}

const getInteractionTypeColor = (type) => {
  const colorMap = {
    '数据上报': 'success',
    '命令执行': 'primary',
    '状态查询': 'info',
    '配置更新': 'warning',
    '固件升级': 'danger'
  }
  return colorMap[type] || 'info'
}

const viewInteractionDetail = (row) => {
  ElMessage.info(`查看交互详情: ${row.description}`)
}

// 生命周期
onMounted(() => {
  loadInteractionHistory()
})
</script>

<style scoped>
.device-interaction-stats {
  width: 100%;
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
  align-items: center;
}

.interaction-stats {
  margin-bottom: 24px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 16px;
}

.stat-item {
  display: flex;
  align-items: center;
  padding: 16px;
  background: #f8f9fa;
  border-radius: 8px;
  border: 1px solid #e9ecef;
  transition: all 0.3s ease;
}

.stat-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.stat-icon {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-right: 16px;
  font-size: 20px;
  color: white;
}

.stat-icon.online {
  background: linear-gradient(135deg, #67C23A, #85CE61);
}

.stat-icon.data {
  background: linear-gradient(135deg, #409EFF, #66B1FF);
}

.stat-icon.success {
  background: linear-gradient(135deg, #67C23A, #85CE61);
}

.stat-icon.response {
  background: linear-gradient(135deg, #E6A23C, #EEBE77);
}

.stat-content {
  flex: 1;
}

.stat-value {
  font-size: 24px;
  font-weight: 700;
  color: #303133;
  line-height: 1;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 14px;
  color: #909399;
  line-height: 1;
}

.interaction-history h4 {
  margin: 0 0 16px 0;
  color: #303133;
  font-size: 16px;
  font-weight: 600;
}

@media (max-width: 768px) {
  .stats-grid {
    grid-template-columns: 1fr;
  }
  
  .card-actions {
    flex-direction: column;
    gap: 4px;
  }
  
  .card-actions .el-select {
    width: 100% !important;
  }
}
</style>