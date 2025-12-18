<template>
  <div class="data-charts-container">
    <div class="page-header">
      <h2>数据图表</h2>
      <div class="header-actions">
        <el-button @click="showCreateDialog = true">
          <el-icon><Plus /></el-icon>
          创建图表
        </el-button>
      </div>
    </div>

    <!-- 图表网格 -->
    <div class="charts-grid">
      <el-row :gutter="20">
        <el-col :span="12" v-for="chart in charts" :key="chart.id">
          <el-card class="chart-card">
            <template #header>
              <div class="chart-header">
                <span>{{ chart.title }}</span>
                <div class="chart-actions">
                  <el-button size="small" @click="editChart(chart)">编辑</el-button>
                  <el-button size="small" type="danger" @click="deleteChart(chart)">删除</el-button>
                </div>
              </div>
            </template>
            <div class="chart-content">
              <div class="chart-placeholder">
                {{ chart.type }} 图表 - {{ chart.title }}
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>
    </div>

    <!-- 创建图表对话框 -->
    <el-dialog v-model="showCreateDialog" title="创建图表" width="600px">
      <el-form :model="chartForm" :rules="rules" ref="chartFormRef" label-width="100px">
        <el-form-item label="图表标题" prop="title">
          <el-input v-model="chartForm.title" placeholder="请输入图表标题" />
        </el-form-item>
        <el-form-item label="图表类型" prop="type">
          <el-select v-model="chartForm.type" placeholder="请选择图表类型">
            <el-option label="折线图" value="line" />
            <el-option label="柱状图" value="bar" />
            <el-option label="饼图" value="pie" />
            <el-option label="散点图" value="scatter" />
          </el-select>
        </el-form-item>
        <el-form-item label="数据源" prop="dataSource">
          <el-select v-model="chartForm.dataSource" placeholder="请选择数据源">
            <el-option label="温度数据" value="temperature" />
            <el-option label="湿度数据" value="humidity" />
            <el-option label="设备状态" value="device_status" />
            <el-option label="功耗数据" value="power_consumption" />
          </el-select>
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input v-model="chartForm.description" type="textarea" :rows="3" placeholder="请输入图表描述" />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="showCreateDialog = false">取消</el-button>
          <el-button type="primary" @click="saveChart">确定</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'

const showCreateDialog = ref(false)
const chartFormRef = ref()
const editingChart = ref(null)

const charts = ref([
  {
    id: 1,
    title: '温度趋势图',
    type: 'line',
    dataSource: 'temperature',
    description: '显示过去24小时的温度变化趋势'
  },
  {
    id: 2,
    title: '设备状态分布',
    type: 'pie',
    dataSource: 'device_status',
    description: '显示所有设备的在线/离线状态分布'
  }
])

const chartForm = reactive({
  title: '',
  type: '',
  dataSource: '',
  description: ''
})

const rules = {
  title: [{ required: true, message: '请输入图表标题', trigger: 'blur' }],
  type: [{ required: true, message: '请选择图表类型', trigger: 'change' }],
  dataSource: [{ required: true, message: '请选择数据源', trigger: 'change' }]
}

const editChart = (chart) => {
  editingChart.value = chart
  Object.assign(chartForm, chart)
  showCreateDialog.value = true
}

const deleteChart = async (chart) => {
  try {
    await ElMessageBox.confirm(`确定要删除图表"${chart.title}"吗？`, '确认删除', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    const index = charts.value.findIndex(item => item.id === chart.id)
    if (index !== -1) {
      charts.value.splice(index, 1)
    }
    ElMessage.success('图表删除成功')
  } catch {
    // 用户取消操作
  }
}

const saveChart = async () => {
  if (!chartFormRef.value) return
  
  await chartFormRef.value.validate((valid) => {
    if (valid) {
      if (editingChart.value) {
        const index = charts.value.findIndex(item => item.id === editingChart.value.id)
        if (index !== -1) {
          charts.value[index] = { ...charts.value[index], ...chartForm }
        }
        ElMessage.success('图表更新成功')
      } else {
        const newChart = {
          id: Date.now(),
          ...chartForm
        }
        charts.value.push(newChart)
        ElMessage.success('图表创建成功')
      }
      
      resetForm()
      showCreateDialog.value = false
    }
  })
}

const resetForm = () => {
  Object.assign(chartForm, {
    title: '',
    type: '',
    dataSource: '',
    description: ''
  })
  editingChart.value = null
  chartFormRef.value?.resetFields()
}
</script>

<style scoped>
.data-charts-container {
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

.charts-grid {
  margin-bottom: 20px;
}

.chart-card {
  margin-bottom: 20px;
  height: 400px;
}

.chart-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.chart-content {
  height: 300px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f8f9fa;
  border-radius: 4px;
}

.chart-placeholder {
  color: #999;
  font-size: 16px;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}
</style>