<template>
  <div class="plugins-container">
    <div class="page-header">
      <h2>插件管理</h2>
    </div>

    <!-- 搜索和筛选 -->
    <div class="filter-section">
      <el-row :gutter="16">
        <el-col :span="10">
          <el-input
            v-model="searchQuery"
            placeholder="搜索插件名称"
            clearable
            @input="handleSearch"
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>
        </el-col>
        <el-col :span="6">
          <el-select v-model="filterStatus" placeholder="状态筛选" clearable @change="loadPlugins" style="width: 100%;">
            <el-option label="激活" :value="1" />
            <el-option label="禁用" :value="0" />
          </el-select>
        </el-col>
        <el-col :span="8" style="text-align: right;">
          <el-button @click="resetFilters">重置筛选</el-button>
          <el-button type="primary" icon="Plus" @click="addPlugin">添加插件</el-button>
          <el-button type="success" icon="Upload" @click="importFromFile">从文件导入</el-button>
        </el-col>
      </el-row>
    </div>

    <!-- 插件列表 -->
    <el-table
      v-loading="loading"
      :data="plugins"
      style="width: 100%"
    >
      <el-table-column prop="name" label="插件名称" min-width="200" />
      <el-table-column prop="description" label="描述" min-width="250" show-overflow-tooltip />
      <el-table-column label="OpenAPI版本" width="150">
        <template #default="scope">
          <el-tag>{{ scope.row.openapi_spec?.openapi || 'N/A' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="API数量" width="120">
        <template #default="scope">
          <el-tag>{{ Object.keys(scope.row.openapi_spec?.paths || {}).length }}</el-tag>
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
      <el-table-column label="操作" width="250" fixed="right">
        <template #default="scope">
          <el-button size="small" @click="viewPlugin(scope.row)">查看</el-button>
          <el-button size="small" @click="editPlugin(scope.row)">编辑</el-button>
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
      @size-change="loadPlugins"
      @current-change="loadPlugins"
      style="margin-top: 20px; justify-content: flex-end;"
    />

    <!-- 编辑对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="900px"
      @close="resetForm"
    >
      <el-form :model="form" :rules="rules" ref="formRef" label-width="120px">
        <el-form-item label="插件名称" prop="name">
          <el-input v-model="form.name" placeholder="请输入插件名称" />
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input
            v-model="form.description"
            type="textarea"
            :rows="3"
            placeholder="请输入插件描述"
          />
        </el-form-item>
        <el-form-item label="OpenAPI规范" prop="openapi_spec">
          <div style="border: 1px solid #dcdfe6; border-radius: 4px;">
            <el-input
              v-model="jsonString"
              type="textarea"
              :rows="20"
              placeholder="请输入 OpenAPI 3.0.0 规范的 JSON"
              @blur="validateJson"
            />
          </div>
          <div class="form-tip">
            ⚠️ 必须符合 OpenAPI 3.0.0 格式，包含 openapi、info、paths 字段
          </div>
          <div v-if="jsonError" class="form-error">
            {{ jsonError }}
          </div>
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

    <!-- 查看对话框 -->
    <el-dialog
      v-model="viewDialogVisible"
      title="查看插件详情"
      width="900px"
    >
      <el-descriptions :column="2" border>
        <el-descriptions-item label="插件名称">{{ viewPluginData.name }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="viewPluginData.is_active === 1 ? 'success' : 'danger'">
            {{ viewPluginData.is_active === 1 ? '激活' : '禁用' }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="描述" :span="2">{{ viewPluginData.description || '无' }}</el-descriptions-item>
        <el-descriptions-item label="OpenAPI版本">{{ viewPluginData.openapi_spec?.openapi || 'N/A' }}</el-descriptions-item>
        <el-descriptions-item label="API数量">{{ Object.keys(viewPluginData.openapi_spec?.paths || {}).length }}</el-descriptions-item>
        <el-descriptions-item label="创建时间" :span="2">{{ formatDate(viewPluginData.created_at) }}</el-descriptions-item>
      </el-descriptions>
      <el-divider>OpenAPI 规范</el-divider>
      <pre style="background: #f5f7fa; padding: 16px; border-radius: 4px; max-height: 400px; overflow: auto;">{{ JSON.stringify(viewPluginData.openapi_spec, null, 2) }}</pre>
    </el-dialog>

    <!-- 文件上传（隐藏） -->
    <input
      ref="fileInput"
      type="file"
      accept=".json"
      style="display: none"
      @change="handleFileImport"
    />
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed, watch } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Plus, Upload } from '@element-plus/icons-vue'
import { getPlugins, createPlugin, updatePlugin, deletePlugin } from '../api/plugin'

const loading = ref(false)
const searchQuery = ref('')
const filterStatus = ref(null)
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)
const plugins = ref([])
const dialogVisible = ref(false)
const viewDialogVisible = ref(false)
const dialogTitle = ref('添加插件')
const submitting = ref(false)
const formRef = ref(null)
const fileInput = ref(null)
const jsonError = ref('')
const viewPluginData = ref({})

const form = reactive({
  id: null,
  name: '',
  description: '',
  openapi_spec: {},
  is_active: 1
})

const jsonString = computed({
  get: () => {
    try {
      return JSON.stringify(form.openapi_spec, null, 2)
    } catch {
      return ''
    }
  },
  set: (value) => {
    try {
      form.openapi_spec = JSON.parse(value)
      jsonError.value = ''
    } catch (e) {
      jsonError.value = 'JSON 格式错误：' + e.message
    }
  }
})

const rules = {
  name: [
    { required: true, message: '请输入插件名称', trigger: 'blur' },
    { min: 1, max: 100, message: '长度在 1 到 100 个字符', trigger: 'blur' }
  ],
  openapi_spec: [
    { required: true, message: '请输入 OpenAPI 规范', trigger: 'blur' },
    {
      validator: (rule, value, callback) => {
        if (!value || typeof value !== 'object') {
          callback(new Error('OpenAPI 规范必须是有效的 JSON 对象'))
          return
        }
        if (!value.openapi) {
          callback(new Error('缺少 openapi 字段'))
          return
        }
        if (!value.info || !value.info.title) {
          callback(new Error('缺少 info.title 字段'))
          return
        }
        if (!value.paths || typeof value.paths !== 'object') {
          callback(new Error('缺少 paths 字段或格式不正确'))
          return
        }
        callback()
      },
      trigger: 'blur'
    }
  ]
}

// 加载插件列表
const loadPlugins = async () => {
  loading.value = true
  try {
    const params = {
      skip: (currentPage.value - 1) * pageSize.value,
      limit: pageSize.value,
      search: searchQuery.value || undefined,
      is_active: filterStatus.value !== null ? filterStatus.value : undefined
    }
    const response = await getPlugins(params)
    plugins.value = response.data.items || []
    total.value = response.data.total || 0
  } catch (error) {
    ElMessage.error('加载插件列表失败')
  } finally {
    loading.value = false
  }
}

// 搜索
const handleSearch = () => {
  currentPage.value = 1
  loadPlugins()
}

// 重置筛选
const resetFilters = () => {
  searchQuery.value = ''
  filterStatus.value = null
  currentPage.value = 1
  loadPlugins()
}

// 添加插件
const addPlugin = () => {
  dialogTitle.value = '添加插件'
  resetForm()
  dialogVisible.value = true
}

// 编辑插件
const editPlugin = (row) => {
  dialogTitle.value = '编辑插件'
  form.id = row.id
  form.name = row.name
  form.description = row.description || ''
  form.openapi_spec = JSON.parse(JSON.stringify(row.openapi_spec))
  form.is_active = row.is_active
  dialogVisible.value = true
}

// 查看插件
const viewPlugin = (row) => {
  viewPluginData.value = row
  viewDialogVisible.value = true
}

// 删除插件
const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除插件 "${row.name}" 吗？`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    await deletePlugin(row.id)
    ElMessage.success('删除成功')
    loadPlugins()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error(error.response?.data?.detail || '删除失败')
    }
  }
}

// 从文件导入
const importFromFile = () => {
  fileInput.value?.click()
}

// 处理文件导入
const handleFileImport = async (event) => {
  const file = event.target.files[0]
  if (!file) return

  const reader = new FileReader()
  reader.onload = (e) => {
    try {
      const json = JSON.parse(e.target.result)
      if (!json.openapi || !json.info || !json.paths) {
        ElMessage.error('文件格式不正确，必须包含 openapi、info、paths 字段')
        return
      }
      
      // 填充表单
      form.name = json.info.title || ''
      form.description = json.info.description || ''
      form.openapi_spec = json
      jsonError.value = ''
      
      dialogTitle.value = '添加插件'
      form.id = null
      form.is_active = 1
      dialogVisible.value = true
      
      ElMessage.success('文件导入成功')
    } catch (error) {
      ElMessage.error('文件解析失败：' + error.message)
    }
  }
  reader.readAsText(file)
  
  // 重置文件输入
  event.target.value = ''
}

// 验证 JSON
const validateJson = () => {
  try {
    const parsed = JSON.parse(jsonString.value)
    if (!parsed.openapi || !parsed.info || !parsed.paths) {
      jsonError.value = '缺少必需字段：openapi、info 或 paths'
      return false
    }
    jsonError.value = ''
    return true
  } catch (e) {
    jsonError.value = 'JSON 格式错误：' + e.message
    return false
  }
}

// 提交表单
const handleSubmit = async () => {
  if (!formRef.value) return
  
  // 先验证 JSON
  if (!validateJson()) {
    ElMessage.warning('请先修正 JSON 格式错误')
    return
  }
  
  await formRef.value.validate(async (valid) => {
    if (!valid) return
    
    submitting.value = true
    try {
      const data = {
        name: form.name,
        description: form.description,
        openapi_spec: form.openapi_spec
      }
      
      if (form.id) {
        data.is_active = form.is_active
        await updatePlugin(form.id, data)
        ElMessage.success('更新成功')
      } else {
        await createPlugin(data)
        ElMessage.success('创建成功')
      }
      
      dialogVisible.value = false
      loadPlugins()
    } catch (error) {
      ElMessage.error(error.response?.data?.detail || (form.id ? '更新失败' : '创建失败'))
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
  form.openapi_spec = {}
  form.is_active = 1
  jsonError.value = ''
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
  loadPlugins()
})
</script>

<style scoped>
.plugins-container {
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

.form-error {
  font-size: 12px;
  color: #f56c6c;
  margin-top: 4px;
}

pre {
  font-family: 'Courier New', monospace;
  font-size: 12px;
  line-height: 1.5;
}
</style>

