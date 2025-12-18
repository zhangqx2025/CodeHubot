<template>
  <div class="device-history-data">
    <el-card class="history-card" shadow="hover">
      <template #header>
        <div class="card-header">
          <el-icon size="20" color="#E6A23C"><Clock /></el-icon>
          <span>历史数据</span>
          <div class="card-actions">
            <el-select 
              v-model="historyDataType" 
              placeholder="数据类型" 
              size="small" 
              style="width: 120px; margin-right: 8px;"
              @change="loadHistoryData"
            >
              <el-option label="全部" value="all" />
              <el-option label="环境数据" value="environment" />
              <el-option label="系统数据" value="system" />
              <el-option label="性能数据" value="performance" />
            </el-select>
            <el-date-picker
              v-model="dateRange"
              type="datetimerange"
              range-separator="至"
              start-placeholder="开始日期"
              end-placeholder="结束日期"
              size="small"
              @change="loadHistoryData"
            />
            <el-button size="small" type="text" @click="exportHistoryData">
              <el-icon><Download /></el-icon>
              导出
            </el-button>
          </div>
        </div>
      </template>
      <div class="history-data">
        <div class="data-view-toggle" style="margin-bottom: 16px;">
          <el-radio-group v-model="historyViewMode" size="small" @change="loadHistoryData">
            <el-radio-button label="table">表格视图</el-radio-button>
            <el-radio-button label="chart">图表视图</el-radio-button>
          </el-radio-group>
        </div>
        
        <!-- 表格视图 -->
        <div v-if="historyViewMode === 'table'">
          <el-table 
            :data="filteredHistoryData" 
            style="width: 100%" 
            max-height="300"
            :loading="historyLoading"
            stripe
          >
            <el-table-column prop="timestamp" label="时间" width="140" sortable />
            
            <!-- 环境数据列 -->
            <template v-if="historyDataType === 'all' || historyDataType === 'environment'">
              <el-table-column prop="temperature" label="温度" width="80" sortable>
                <template #default="scope">
                  <span :class="getDataStatusClass('temperature', scope.row.temperature)">
                    {{ scope.row.temperature }}°C
                  </span>
                </template>
              </el-table-column>
              <el-table-column prop="humidity" label="湿度" width="80" sortable>
                <template #default="scope">
                  <span :class="getDataStatusClass('humidity', scope.row.humidity)">
                    {{ scope.row.humidity }}%
                  </span>
                </template>
              </el-table-column>
              <el-table-column prop="pressure" label="压力" width="90" sortable>
                <template #default="scope">
                  {{ scope.row.pressure }}hPa
                </template>
              </el-table-column>
            </template>
            
            <!-- 系统数据列 -->
            <template v-if="historyDataType === 'all' || historyDataType === 'system'">
              <el-table-column prop="cpu_usage" label="CPU" width="70" sortable>
                <template #default="scope">
                  <span :class="getDataStatusClass('cpu_usage', scope.row.cpu_usage)">
                    {{ scope.row.cpu_usage }}%
                  </span>
                </template>
              </el-table-column>
              <el-table-column prop="memory_usage" label="内存" width="70" sortable>
                <template #default="scope">
                  <span :class="getDataStatusClass('memory_usage', scope.row.memory_usage)">
                    {{ scope.row.memory_usage }}%
                  </span>
                </template>
              </el-table-column>
              <el-table-column prop="disk_usage" label="磁盘" width="70" sortable>
                <template #default="scope">
                  <span :class="getDataStatusClass('disk_usage', scope.row.disk_usage)">
                    {{ scope.row.disk_usage }}%
                  </span>
                </template>
              </el-table-column>
            </template>
            
            <!-- 性能数据列 -->
            <template v-if="historyDataType === 'all' || historyDataType === 'performance'">
              <el-table-column prop="network_speed" label="网络" width="80" sortable>
                <template #default="scope">
                  {{ scope.row.network_speed }}KB/s
                </template>
              </el-table-column>
              <el-table-column prop="power_consumption" label="功耗" width="70" sortable>
                <template #default="scope">
                  <span :class="getDataStatusClass('power_consumption', scope.row.power_consumption)">
                    {{ scope.row.power_consumption }}W
                  </span>
                </template>
              </el-table-column>
            </template>
          </el-table>
        </div>
        
        <!-- 图表视图 -->
        <div v-else class="chart-view">
          <div class="chart-container" style="height: 300px; display: flex; align-items: center; justify-content: center; background: #f5f7fa; border-radius: 4px;">
            <div style="text-align: center; color: #909399;">
              <el-icon size="48"><TrendCharts /></el-icon>
              <p style="margin: 8px 0 0 0;">历史数据趋势图</p>
              <p style="margin: 4px 0 0 0; font-size: 12px;">显示选定时间范围内的数据变化趋势</p>
            </div>
          </div>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Clock, Download, TrendCharts } from '@element-plus/icons-vue'

// Props
const props = defineProps({
  deviceId: {
    type: String,
    required: true
  }
})

// 响应式数据
const historyData = ref([])
const historyDataType = ref('all')
const historyViewMode = ref('table')
const historyLoading = ref(false)
const dateRange = ref([])

// 计算属性
const filteredHistoryData = computed(() => {
  return historyData.value
})

// 方法
const loadHistoryData = async () => {
  historyLoading.value = true
  try {
    // 模拟加载历史数据
    await new Promise(resolve => setTimeout(resolve, 500))
    
    const generateHistoryData = () => {
      const data = []
      for (let i = 0; i < 20; i++) {
        const time = new Date(Date.now() - i * 5 * 60 * 1000) // 每5分钟一条数据
        data.push({
          timestamp: time.toLocaleString('zh-CN'),
          temperature: (20 + Math.random() * 15).toFixed(1),
          humidity: (50 + Math.random() * 30).toFixed(1),
          pressure: (1000 + Math.random() * 50).toFixed(2),
          cpu_usage: (10 + Math.random() * 80).toFixed(1),
          memory_usage: (30 + Math.random() * 60).toFixed(1),
          disk_usage: (20 + Math.random() * 70).toFixed(1),
          network_speed: (50 + Math.random() * 200).toFixed(1),
          power_consumption: (8 + Math.random() * 15).toFixed(1)
        })
      }
      return data
    }
    
    historyData.value = generateHistoryData()
  } catch (error) {
    ElMessage.error('加载历史数据失败')
  } finally {
    historyLoading.value = false
  }
}

const exportHistoryData = () => {
  ElMessage.info('导出功能开发中...')
}

const getDataStatusClass = (type, value) => {
  const numValue = parseFloat(value)
  
  const thresholds = {
    temperature: { warning: 35, danger: 40 },
    humidity: { warning: 80, danger: 90 },
    cpu_usage: { warning: 70, danger: 85 },
    memory_usage: { warning: 80, danger: 90 },
    disk_usage: { warning: 80, danger: 90 },
    power_consumption: { warning: 15, danger: 20 }
  }
  
  const threshold = thresholds[type]
  if (!threshold) return ''
  
  if (numValue >= threshold.danger) return 'data-danger'
  if (numValue >= threshold.warning) return 'data-warning'
  return 'data-normal'
}

// 生命周期
onMounted(() => {
  loadHistoryData()
})
</script>

<style scoped>
.device-history-data {
  height: 100%;
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

.history-data {
  padding: 0;
}

.chart-container {
  border: 1px dashed #dcdfe6;
}

:deep(.data-normal) {
  color: #67C23A;
}

:deep(.data-warning) {
  color: #E6A23C;
}

:deep(.data-danger) {
  color: #F56C6C;
}

@media (max-width: 768px) {
  .card-actions {
    flex-direction: column;
    gap: 4px;
  }
  
  .card-actions .el-select,
  .card-actions .el-date-picker {
    width: 100% !important;
  }
}
</style>