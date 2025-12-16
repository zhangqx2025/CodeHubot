<template>
  <div class="alert-rules-container">
    <div class="page-header">
      <h2>告警规则</h2>
      <div class="header-actions">
        <el-button type="primary" @click="showCreateDialog = true">
          <el-icon><Plus /></el-icon>
          创建规则
        </el-button>
      </div>
    </div>

    <!-- 规则列表 -->
    <el-card class="rules-card">
      <el-table :data="rules" style="width: 100%">
        <el-table-column prop="name" label="规则名称" />
        <el-table-column prop="deviceType" label="设备类型" />
        <el-table-column prop="condition" label="触发条件" />
        <el-table-column prop="level" label="告警级别">
          <template #default="{ row }">
            <el-tag :type="getLevelTagType(row.level)">{{ getLevelLabel(row.level) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="enabled" label="状态">
          <template #default="{ row }">
            <el-switch v-model="row.enabled" @change="toggleRule(row)" />
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200">
          <template #default="{ row }">
            <el-button size="small" @click="editRule(row)">编辑</el-button>
            <el-button size="small" type="danger" @click="deleteRule(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 创建/编辑规则对话框 -->
    <el-dialog v-model="showCreateDialog" :title="editingRule ? '编辑规则' : '创建规则'" width="600px">
      <el-form :model="ruleForm" :rules="ruleRules" ref="ruleFormRef" label-width="100px">
        <el-form-item label="规则名称" prop="name">
          <el-input v-model="ruleForm.name" placeholder="请输入规则名称" />
        </el-form-item>
        <el-form-item label="设备类型" prop="deviceType">
          <el-select v-model="ruleForm.deviceType" placeholder="请选择设备类型">
            <el-option label="温度传感器" value="temperature" />
            <el-option label="湿度传感器" value="humidity" />
            <el-option label="压力传感器" value="pressure" />
            <el-option label="所有设备" value="all" />
          </el-select>
        </el-form-item>
        <el-form-item label="监控指标" prop="metric">
          <el-select v-model="ruleForm.metric" placeholder="请选择监控指标">
            <el-option label="温度" value="temperature" />
            <el-option label="湿度" value="humidity" />
            <el-option label="压力" value="pressure" />
            <el-option label="设备状态" value="status" />
          </el-select>
        </el-form-item>
        <el-form-item label="条件" prop="operator">
          <el-select v-model="ruleForm.operator" placeholder="请选择条件">
            <el-option label="大于" value="gt" />
            <el-option label="小于" value="lt" />
            <el-option label="等于" value="eq" />
            <el-option label="不等于" value="ne" />
          </el-select>
        </el-form-item>
        <el-form-item label="阈值" prop="threshold">
          <el-input v-model="ruleForm.threshold" placeholder="请输入阈值" />
        </el-form-item>
        <el-form-item label="告警级别" prop="level">
          <el-select v-model="ruleForm.level" placeholder="请选择告警级别">
            <el-option label="信息" value="info" />
            <el-option label="警告" value="warning" />
            <el-option label="严重" value="critical" />
          </el-select>
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input v-model="ruleForm.description" type="textarea" :rows="3" placeholder="请输入规则描述" />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="showCreateDialog = false">取消</el-button>
          <el-button type="primary" @click="saveRule">确定</el-button>
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
const ruleFormRef = ref()
const editingRule = ref(null)

const rules = ref([
  {
    id: 1,
    name: '温度过高告警',
    deviceType: 'temperature',
    metric: 'temperature',
    operator: 'gt',
    threshold: '35',
    condition: '温度 > 35°C',
    level: 'warning',
    description: '当温度超过35度时触发告警',
    enabled: true
  },
  {
    id: 2,
    name: '设备离线告警',
    deviceType: 'all',
    metric: 'status',
    operator: 'eq',
    threshold: 'offline',
    condition: '设备状态 = 离线',
    level: 'critical',
    description: '当设备离线时立即触发告警',
    enabled: true
  }
])

const ruleForm = reactive({
  name: '',
  deviceType: '',
  metric: '',
  operator: '',
  threshold: '',
  level: '',
  description: ''
})

const ruleRules = {
  name: [{ required: true, message: '请输入规则名称', trigger: 'blur' }],
  deviceType: [{ required: true, message: '请选择设备类型', trigger: 'change' }],
  metric: [{ required: true, message: '请选择监控指标', trigger: 'change' }],
  operator: [{ required: true, message: '请选择条件', trigger: 'change' }],
  threshold: [{ required: true, message: '请输入阈值', trigger: 'blur' }],
  level: [{ required: true, message: '请选择告警级别', trigger: 'change' }]
}

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

const editRule = (rule) => {
  editingRule.value = rule
  Object.assign(ruleForm, rule)
  showCreateDialog.value = true
}

const deleteRule = async (rule) => {
  try {
    await ElMessageBox.confirm(`确定要删除规则"${rule.name}"吗？`, '确认删除', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    const index = rules.value.findIndex(item => item.id === rule.id)
    if (index !== -1) {
      rules.value.splice(index, 1)
    }
    ElMessage.success('规则删除成功')
  } catch {
    // 用户取消操作
  }
}

const toggleRule = (rule) => {
  ElMessage.success(`规则已${rule.enabled ? '启用' : '禁用'}`)
}

const saveRule = async () => {
  if (!ruleFormRef.value) return
  
  await ruleFormRef.value.validate((valid) => {
    if (valid) {
      // 生成条件描述
      const conditionText = generateConditionText()
      
      if (editingRule.value) {
        const index = rules.value.findIndex(item => item.id === editingRule.value.id)
        if (index !== -1) {
          rules.value[index] = { 
            ...rules.value[index], 
            ...ruleForm,
            condition: conditionText
          }
        }
        ElMessage.success('规则更新成功')
      } else {
        const newRule = {
          id: Date.now(),
          ...ruleForm,
          condition: conditionText,
          enabled: true
        }
        rules.value.push(newRule)
        ElMessage.success('规则创建成功')
      }
      
      resetForm()
      showCreateDialog.value = false
    }
  })
}

const generateConditionText = () => {
  const metricLabels = {
    temperature: '温度',
    humidity: '湿度',
    pressure: '压力',
    status: '设备状态'
  }
  
  const operatorLabels = {
    gt: '>',
    lt: '<',
    eq: '=',
    ne: '!='
  }
  
  const metric = metricLabels[ruleForm.metric] || ruleForm.metric
  const operator = operatorLabels[ruleForm.operator] || ruleForm.operator
  
  return `${metric} ${operator} ${ruleForm.threshold}`
}

const resetForm = () => {
  Object.assign(ruleForm, {
    name: '',
    deviceType: '',
    metric: '',
    operator: '',
    threshold: '',
    level: '',
    description: ''
  })
  editingRule.value = null
  ruleFormRef.value?.resetFields()
}
</script>

<style scoped>
.alert-rules-container {
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

.rules-card {
  margin-bottom: 20px;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}
</style>