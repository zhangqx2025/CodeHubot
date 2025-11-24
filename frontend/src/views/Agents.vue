<template>
  <div class="agents-container">
    <div class="page-header">
      <h2>智能体管理</h2>
    </div>

    <!-- 搜索和筛选 -->
    <div class="filter-section">
      <el-row :gutter="16">
        <el-col :span="10">
          <el-input
            v-model="searchQuery"
            placeholder="搜索智能体名称"
            clearable
            @input="handleSearch"
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>
        </el-col>
        <el-col :span="6">
          <el-select v-model="filterStatus" placeholder="状态筛选" clearable @change="loadAgents" style="width: 100%;">
            <el-option label="激活" :value="1" />
            <el-option label="禁用" :value="0" />
          </el-select>
        </el-col>
        <el-col :span="8" style="text-align: right;">
          <el-button @click="resetFilters">重置筛选</el-button>
          <el-button type="primary" icon="Plus" @click="addAgent">添加智能体</el-button>
        </el-col>
      </el-row>
    </div>

    <!-- 智能体列表 -->
    <el-table
      v-loading="loading"
      :data="agents"
      style="width: 100%"
    >
      <el-table-column prop="name" label="智能体名称" min-width="200" />
      <el-table-column prop="description" label="描述" min-width="250" show-overflow-tooltip />
      <el-table-column label="插件数量" width="120">
        <template #default="scope">
          <el-tag>{{ scope.row.plugin_ids?.length || 0 }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="状态" width="80">
        <template #default="scope">
          <el-tag :type="scope.row.is_active === 1 ? 'success' : 'danger'">
            {{ scope.row.is_active === 1 ? '激活' : '禁用' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="created_at" label="创建时间" width="160">
        <template #default="scope">
          {{ formatDate(scope.row.created_at) }}
        </template>
      </el-table-column>
      <el-table-column label="类型" width="120">
        <template #default="scope">
          <el-tag :type="scope.row.is_system === 1 ? 'warning' : 'info'" size="small">
            {{ scope.row.is_system === 1 ? '系统内置' : '用户创建' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="200" fixed="right">
        <template #default="scope">
          <el-button size="small" @click="editAgent(scope.row)">编辑</el-button>
          <el-button
            size="small"
            type="danger"
            @click="handleDelete(scope.row)"
            :disabled="scope.row.is_system === 1"
          >
            删除
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <el-pagination
      v-model:current-page="currentPage"
      v-model:page-size="pageSize"
      :page-sizes="[10, 20, 50, 100]"
      :total="total"
      layout="total, sizes, prev, pager, next, jumper"
      @size-change="loadAgents"
      @current-change="loadAgents"
      style="margin-top: 20px; justify-content: flex-end;"
    />

    <!-- 编辑对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="800px"
      @close="resetForm"
    >
      <el-form :model="form" :rules="rules" ref="formRef" label-width="120px">
        <el-form-item label="智能体名称" prop="name">
          <el-input v-model="form.name" placeholder="请输入智能体名称" />
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input
            v-model="form.description"
            type="textarea"
            :rows="3"
            placeholder="请输入智能体描述"
          />
        </el-form-item>
        <el-form-item label="系统提示词" prop="system_prompt">
          <el-input
            v-model="form.system_prompt"
            type="textarea"
            :rows="8"
            placeholder="请输入系统提示词，用于指导AI智能体的行为"
          />
        </el-form-item>
        <el-form-item label="关联插件" prop="plugin_ids">
          <el-select
            v-model="form.plugin_ids"
            multiple
            placeholder="请选择插件"
            style="width: 100%"
            filterable
          >
            <el-option
              v-for="plugin in availablePlugins"
              :key="plugin.id"
              :label="plugin.name"
              :value="plugin.id"
            />
          </el-select>
          <div class="form-tip">可以选择多个插件，智能体将可以使用这些插件的功能</div>
        </el-form-item>
        <el-form-item label="状态" prop="is_active" v-if="form.id">
          <el-radio-group v-model="form.is_active">
            <el-radio :label="1">激活</el-radio>
            <el-radio :label="0">禁用</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitting">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Plus } from '@element-plus/icons-vue'
import { getAgents, createAgent, updateAgent, deleteAgent } from '../api/agent'
import { getPlugins } from '../api/plugin'

const loading = ref(false)
const searchQuery = ref('')
const filterStatus = ref(null)
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)
const agents = ref([])
const availablePlugins = ref([])
const dialogVisible = ref(false)
const dialogTitle = ref('添加智能体')
const submitting = ref(false)
const formRef = ref(null)

const form = reactive({
  id: null,
  name: '',
  description: '',
  system_prompt: '',
  plugin_ids: [],
  is_active: 1
})

const rules = {
  name: [
    { required: true, message: '请输入智能体名称', trigger: 'blur' },
    { min: 1, max: 100, message: '长度在 1 到 100 个字符', trigger: 'blur' }
  ]
}

// 加载智能体列表
const loadAgents = async () => {
  loading.value = true
  try {
    const params = {
      skip: (currentPage.value - 1) * pageSize.value,
      limit: pageSize.value,
      search: searchQuery.value || undefined,
      is_active: filterStatus.value !== null ? filterStatus.value : undefined
    }
    const response = await getAgents(params)
    agents.value = response.data.items || []
    total.value = response.data.total || 0
  } catch (error) {
    ElMessage.error('加载智能体列表失败')
  } finally {
    loading.value = false
  }
}

// 加载可用插件列表
const loadPlugins = async () => {
  try {
    const response = await getPlugins({ limit: 1000, is_active: 1 })
    availablePlugins.value = response.data.items || []
  } catch (error) {
    console.error('加载插件列表失败', error)
  }
}

// 搜索
const handleSearch = () => {
  currentPage.value = 1
  loadAgents()
}

// 重置筛选
const resetFilters = () => {
  searchQuery.value = ''
  filterStatus.value = null
  currentPage.value = 1
  loadAgents()
}

// 添加智能体
const addAgent = () => {
  dialogTitle.value = '添加智能体'
  resetForm()
  dialogVisible.value = true
}

// 编辑智能体
const editAgent = (row) => {
  dialogTitle.value = '编辑智能体'
  form.id = row.id
  form.name = row.name
  form.description = row.description || ''
  form.system_prompt = row.system_prompt || ''
  form.plugin_ids = row.plugin_ids || []
  form.is_active = row.is_active
  dialogVisible.value = true
}

// 删除智能体
const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除智能体 "${row.name}" 吗？`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    await deleteAgent(row.id)
    ElMessage.success('删除成功')
    loadAgents()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

// 提交表单
const handleSubmit = async () => {
  if (!formRef.value) return
  await formRef.value.validate(async (valid) => {
    if (!valid) return
    
    submitting.value = true
    try {
      const data = {
        name: form.name,
        description: form.description,
        system_prompt: form.system_prompt,
        plugin_ids: form.plugin_ids
      }
      
      if (form.id) {
        data.is_active = form.is_active
        await updateAgent(form.id, data)
        ElMessage.success('更新成功')
      } else {
        await createAgent(data)
        ElMessage.success('创建成功')
      }
      
      dialogVisible.value = false
      loadAgents()
    } catch (error) {
      ElMessage.error(form.id ? '更新失败' : '创建失败')
    } finally {
      submitting.value = false
    }
  })
}

// 重置表单
const resetForm = () => {
  form.id = null
  form.name = ''
  form.description = ''
  form.system_prompt = ''
  form.plugin_ids = []
  form.is_active = 1
  if (formRef.value) {
    formRef.value.clearValidate()
  }
}

// 格式化日期
const formatDate = (date) => {
  if (!date) return ''
  return new Date(date).toLocaleString('zh-CN')
}

onMounted(() => {
  loadAgents()
  loadPlugins()
})
</script>

<style scoped>
.agents-container {
  padding: 20px;
}

.page-header {
  margin-bottom: 20px;
}

.filter-section {
  margin-bottom: 20px;
  padding: 16px;
  background: #f5f7fa;
  border-radius: 4px;
}

.form-tip {
  font-size: 12px;
  color: #909399;
  margin-top: 4px;
}
</style>

