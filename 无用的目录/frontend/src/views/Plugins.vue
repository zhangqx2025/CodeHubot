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

    <!-- 插件列表 - 卡片形式 -->
    <div v-loading="loading" class="plugins-grid">
      <el-empty v-if="plugins.length === 0 && !loading" description="暂无插件">
        <el-button type="primary" @click="addPlugin">创建第一个插件</el-button>
      </el-empty>
      
      <el-card
        v-for="plugin in plugins"
        :key="plugin.id"
        class="plugin-card"
        shadow="hover"
        :body-style="{ padding: '0' }"
      >
        <div class="card-header">
          <div class="header-top">
            <div class="plugin-icon">
              <el-icon size="24"><Connection /></el-icon>
            </div>
            <div class="plugin-info">
              <h3 class="plugin-name">{{ plugin.name }}</h3>
              <div class="plugin-badges">
                <el-tag :type="plugin.is_active === 1 ? 'success' : 'info'" size="small">
                  {{ plugin.is_active === 1 ? '激活' : '禁用' }}
                </el-tag>
                <el-tag v-if="plugin.is_system === 1" type="warning" size="small">系统内置</el-tag>
              </div>
            </div>
          </div>
        </div>
        
        <div class="card-body">
          <p class="plugin-description">{{ plugin.description || '暂无描述' }}</p>
          
          <div class="plugin-stats">
            <div class="stat-item">
              <el-icon><Document /></el-icon>
              <span>{{ plugin.openapi_spec?.openapi || 'N/A' }}</span>
            </div>
            <div class="stat-item">
              <el-icon><Link /></el-icon>
              <span>{{ Object.keys(plugin.openapi_spec?.paths || {}).length }} 个API</span>
            </div>
            <div class="stat-item">
              <el-icon><Clock /></el-icon>
              <span>{{ formatDate(plugin.created_at) }}</span>
            </div>
          </div>
        </div>
        
        <div class="card-footer">
          <el-button size="small" @click="viewPlugin(plugin)">
            <el-icon><View /></el-icon>
            查看
          </el-button>
          <el-button type="primary" size="small" @click="editPlugin(plugin)">
            <el-icon><Edit /></el-icon>
            编辑
          </el-button>
          <el-button
            type="danger"
            size="small"
            @click="handleDelete(plugin)"
            :disabled="plugin.is_system === 1"
          >
            <el-icon><Delete /></el-icon>
            删除
          </el-button>
        </div>
      </el-card>
    </div>

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
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Plus, Upload, Connection, Document, Link, Clock, View, Edit, Delete } from '@element-plus/icons-vue'
import { getPlugins, createPlugin, updatePlugin, deletePlugin } from '../api/plugin'

const router = useRouter()

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
const editPlugin = (plugin) => {
  router.push(`/plugins/${plugin.uuid}/edit`)
}

// 查看插件
const viewPlugin = (plugin) => {
  router.push(`/plugins/${plugin.uuid}/view`)
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
    await deletePlugin(row.uuid)
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

/* 卡片网格布局 */
.plugins-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
  margin-bottom: 20px;
}

/* 插件卡片 */
.plugin-card {
  border-radius: 12px;
  overflow: hidden;
  transition: all 0.3s ease;
  border: 1px solid #e4e7ed;
}

.plugin-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
}

/* 卡片头部 */
.card-header {
  padding: 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.header-top {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.plugin-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
  flex-shrink: 0;
}

.plugin-info {
  flex: 1;
  min-width: 0;
}

.plugin-name {
  margin: 0 0 8px 0;
  font-size: 18px;
  font-weight: 600;
  color: #ffffff;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.plugin-badges {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

/* 卡片主体 */
.card-body {
  padding: 20px;
  background: #ffffff;
}

.plugin-description {
  margin: 0 0 16px 0;
  font-size: 14px;
  color: #606266;
  line-height: 1.6;
  min-height: 44px;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
}

.plugin-stats {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding-top: 12px;
  border-top: 1px solid #f0f0f0;
}

.stat-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  color: #909399;
}

.stat-item .el-icon {
  font-size: 16px;
}

/* 卡片底部 */
.card-footer {
  padding: 12px 20px;
  background: #f5f7fa;
  display: flex;
  gap: 8px;
  border-top: 1px solid #e4e7ed;
}

.card-footer .el-button {
  flex: 1;
}

/* 响应式设计 */
@media (max-width: 1200px) {
  .plugins-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 768px) {
  .plugins-grid {
    grid-template-columns: 1fr;
  }
}
</style>

