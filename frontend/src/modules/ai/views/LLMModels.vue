<template>
  <div class="llm-models-container">
    <div class="page-header">
      <h2>大模型配置</h2>
    </div>

    <!-- 搜索和筛选 -->
    <div class="filter-section">
      <el-row :gutter="16">
        <el-col :span="8">
          <el-input
            v-model="searchQuery"
            placeholder="搜索模型名称"
            clearable
            @input="handleSearch"
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>
        </el-col>
        <el-col :span="6">
          <el-select v-model="filterProvider" placeholder="提供商筛选" clearable @change="loadModels" style="width: 100%;">
            <el-option
              v-for="provider in providers"
              :key="provider.code"
              :label="provider.name"
              :value="provider.code"
            />
          </el-select>
        </el-col>
        <el-col :span="6">
          <el-select v-model="filterStatus" placeholder="状态筛选" clearable @change="loadModels" style="width: 100%;">
            <el-option label="激活" :value="1" />
            <el-option label="禁用" :value="0" />
          </el-select>
        </el-col>
        <el-col :span="4" style="text-align: right;">
          <el-button @click="resetFilters">重置筛选</el-button>
          <el-button type="primary" icon="Plus" @click="addModel">添加模型</el-button>
        </el-col>
      </el-row>
    </div>

    <!-- 模型列表 - 卡片形式 -->
    <div v-loading="loading" class="models-grid">
      <el-empty v-if="models.length === 0 && !loading" description="暂无模型配置">
        <el-button type="primary" @click="addModel">添加第一个模型</el-button>
      </el-empty>
      
      <el-card
        v-for="model in models"
        :key="model.id"
        class="model-card"
        shadow="hover"
        :body-style="{ padding: '0' }"
      >
        <div class="card-header">
          <div class="header-top">
            <div class="model-icon">
              <el-icon size="24"><TrendCharts /></el-icon>
            </div>
            <div class="model-info">
              <h3 class="model-name">{{ model.display_name }}</h3>
              <div class="model-badges">
                <el-tag :type="getProviderType(model.provider)" size="small">
                  {{ getProviderName(model.provider) }}
                </el-tag>
                <el-tag :type="model.is_active === 1 ? 'success' : 'info'" size="small">
                  {{ model.is_active === 1 ? '激活' : '禁用' }}
                </el-tag>
                <el-tag v-if="model.is_default === 1" type="warning" size="small">默认</el-tag>
                <el-tag v-if="model.is_system === 1" type="warning" size="small">系统内置</el-tag>
              </div>
            </div>
          </div>
        </div>
        
        <div class="card-body">
          <p class="model-description">{{ model.description || '暂无描述' }}</p>
          
          <div class="model-stats">
            <div class="stat-item">
              <el-icon><Document /></el-icon>
              <span>{{ model.name }}</span>
            </div>
            <div class="stat-item">
              <el-icon><DataLine /></el-icon>
              <span>{{ model.max_tokens }} tokens</span>
            </div>
            <div class="stat-item">
              <el-icon><Sunny /></el-icon>
              <span>温度 {{ model.temperature }}</span>
            </div>
          </div>
        </div>
        
        <div class="card-footer">
          <el-button size="small" @click="viewModel(model)">
            <el-icon><View /></el-icon>
            查看
          </el-button>
          <el-button type="primary" size="small" @click="editModel(model)">
            <el-icon><Edit /></el-icon>
            编辑
          </el-button>
          <el-button
            type="warning"
            size="small"
            @click="setDefault(model)"
            :disabled="model.is_default === 1 || model.is_active === 0"
          >
            <el-icon><Star /></el-icon>
            默认
          </el-button>
          <el-button
            type="danger"
            size="small"
            @click="handleDelete(model)"
            :disabled="model.is_system === 1"
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
      @size-change="loadModels"
      @current-change="loadModels"
      style="margin-top: 20px; justify-content: flex-end;"
    />

    <!-- 添加/编辑对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="800px"
      @close="resetForm"
    >
      <el-form :model="form" :rules="rules" ref="formRef" label-width="120px">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="模型标识" prop="name">
              <el-input v-model="form.name" placeholder="如：gpt-4" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="显示名称" prop="display_name">
              <el-input v-model="form.display_name" placeholder="如：GPT-4" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="提供商" prop="provider">
              <el-select v-model="form.provider" placeholder="选择提供商" @change="onProviderChange" style="width: 100%;">
                <el-option
                  v-for="provider in providers"
                  :key="provider.code"
                  :label="provider.name"
                  :value="provider.code"
                >
                  <span style="float: left">{{ provider.name }}</span>
                  <span style="float: right; color: #8492a6; font-size: 13px">
                    <el-tag v-if="provider.has_free_quota === 1" type="success" size="small">免费额度</el-tag>
                  </span>
                </el-option>
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="模型类型" prop="model_type">
              <el-select v-model="form.model_type" placeholder="选择类型" style="width: 100%;">
                <el-option label="对话模型" value="chat" />
                <el-option label="嵌入模型" value="embedding" />
                <el-option label="图像模型" value="image" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>

        <!-- 提供商信息提示 -->
        <el-alert
          v-if="form.provider && providerInfo[form.provider]"
          :title="providerInfo[form.provider].title"
          type="info"
          :closable="false"
          show-icon
          style="margin-bottom: 16px;"
        >
          <div style="line-height: 1.8;">
            <p style="margin: 0 0 12px 0;">{{ providerInfo[form.provider].description }}</p>
            <div style="display: flex; flex-direction: column; gap: 8px; font-size: 13px;">
              <div v-if="providerInfo[form.provider].applyUrl" style="display: flex; align-items: center; gap: 8px;">
                <el-icon><Link /></el-icon>
                <span style="color: #606266;">申请 API Key：</span>
                <el-link :href="providerInfo[form.provider].applyUrl" target="_blank" type="primary">
                  {{ providerInfo[form.provider].applyUrl }}
                </el-link>
              </div>
              <div v-if="providerInfo[form.provider].docUrl" style="display: flex; align-items: center; gap: 8px;">
                <el-icon><Document /></el-icon>
                <span style="color: #606266;">开发文档：</span>
                <el-link :href="providerInfo[form.provider].docUrl" target="_blank" type="primary">
                  {{ providerInfo[form.provider].docUrl }}
                </el-link>
              </div>
              <div v-if="providerInfo[form.provider].hasFreeQuota" style="display: flex; align-items: center; gap: 8px; color: #67c23a;">
                <el-icon><SuccessFilled /></el-icon>
                <span>提供免费额度</span>
              </div>
            </div>
          </div>
        </el-alert>

        <el-form-item label="API地址" prop="api_base">
          <el-input v-model="form.api_base" placeholder="如：https://api.openai.com/v1">
            <template #append v-if="form.provider && providerInfo[form.provider]">
              <el-button @click="fillDefaultApiBase">使用默认</el-button>
            </template>
          </el-input>
          <div style="font-size: 12px; color: #909399; margin-top: 4px;" v-if="form.provider && providerInfo[form.provider]">
            默认地址: {{ providerInfo[form.provider].defaultApiBase }}
          </div>
        </el-form-item>

        <el-form-item label="API密钥" prop="api_key">
          <el-input v-model="form.api_key" type="password" placeholder="输入API密钥" show-password>
            <template #prepend>
              <el-icon><Key /></el-icon>
            </template>
          </el-input>
          <div style="font-size: 12px; color: #e6a23c; margin-top: 4px;">
            <el-icon><Warning /></el-icon>
            API 密钥将加密存储，请妥善保管
          </div>
        </el-form-item>

        <el-row :gutter="16">
          <el-col :span="8">
            <el-form-item label="最大Tokens" prop="max_tokens">
              <el-input-number v-model="form.max_tokens" :min="1" :max="200000" style="width: 100%;" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="温度" prop="temperature">
              <el-input-number v-model="form.temperature" :min="0" :max="2" :step="0.1" :precision="2" style="width: 100%;" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="Top P" prop="top_p">
              <el-input-number v-model="form.top_p" :min="0" :max="1" :step="0.1" :precision="2" style="width: 100%;" />
            </el-form-item>
          </el-col>
        </el-row>

        <el-form-item label="描述">
          <el-input
            v-model="form.description"
            type="textarea"
            :rows="3"
            placeholder="请输入模型描述"
          />
        </el-form-item>

        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="激活状态">
              <el-switch v-model="form.is_active" :active-value="1" :inactive-value="0" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="设为默认">
              <el-switch v-model="form.is_default" :active-value="1" :inactive-value="0" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitting">
          {{ form.id ? '保存' : '创建' }}
        </el-button>
      </template>
    </el-dialog>

    <!-- 查看对话框 -->
    <el-dialog
      v-model="viewDialogVisible"
      title="模型详情"
      width="700px"
    >
      <el-descriptions :column="2" border v-if="currentModel">
        <el-descriptions-item label="模型标识">{{ currentModel.name }}</el-descriptions-item>
        <el-descriptions-item label="显示名称">{{ currentModel.display_name }}</el-descriptions-item>
        <el-descriptions-item label="提供商">
          <el-tag :type="getProviderType(currentModel.provider)">
            {{ getProviderName(currentModel.provider) }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="模型类型">{{ currentModel.model_type }}</el-descriptions-item>
        <el-descriptions-item label="API地址" :span="2">{{ currentModel.api_base }}</el-descriptions-item>
        <el-descriptions-item label="最大Tokens">{{ currentModel.max_tokens }}</el-descriptions-item>
        <el-descriptions-item label="温度">{{ currentModel.temperature }}</el-descriptions-item>
        <el-descriptions-item label="Top P">{{ currentModel.top_p }}</el-descriptions-item>
        <el-descriptions-item label="频率惩罚">{{ currentModel.frequency_penalty }}</el-descriptions-item>
        <el-descriptions-item label="存在惩罚">{{ currentModel.presence_penalty }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="currentModel.is_active === 1 ? 'success' : 'danger'">
            {{ currentModel.is_active === 1 ? '激活' : '禁用' }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="是否默认">
          <el-tag v-if="currentModel.is_default === 1" type="warning">默认模型</el-tag>
          <span v-else>否</span>
        </el-descriptions-item>
        <el-descriptions-item label="类型">
          <el-tag :type="currentModel.is_system === 1 ? 'warning' : 'info'">
            {{ currentModel.is_system === 1 ? '系统内置' : '自定义' }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="描述" :span="2">{{ currentModel.description || '暂无描述' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间" :span="2">{{ formatDate(currentModel.created_at) }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Plus, TrendCharts, Document, DataLine, Sunny, View, Edit, Star, Delete, Link, Key, Warning, SuccessFilled } from '@element-plus/icons-vue'
import { getLLMModels, createLLMModel, updateLLMModel, deleteLLMModel, setDefaultLLMModel, getLLMProviders } from '../api/llm-model'

const loading = ref(false)
const searchQuery = ref('')
const filterProvider = ref(null)
const filterStatus = ref(null)
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)
const models = ref([])
const dialogVisible = ref(false)
const viewDialogVisible = ref(false)
const dialogTitle = ref('添加模型')
const submitting = ref(false)
const formRef = ref(null)
const currentModel = ref(null)
const providers = ref([])  // 提供商列表

const form = reactive({
  id: null,
  uuid: null,
  name: '',
  display_name: '',
  provider: 'qwen',
  model_type: 'chat',
  api_base: '',
  api_key: '',
  api_version: '',
  max_tokens: 4096,
  temperature: 0.70,
  top_p: 0.90,
  frequency_penalty: 0.00,
  presence_penalty: 0.00,
  description: '',
  is_active: 1,
  is_default: 0
})

const rules = {
  name: [
    { required: true, message: '请输入模型标识', trigger: 'blur' }
  ],
  display_name: [
    { required: true, message: '请输入显示名称', trigger: 'blur' }
  ],
  provider: [
    { required: true, message: '请选择提供商', trigger: 'change' }
  ]
}

// 获取提供商名称（从数据库动态加载）
const getProviderName = (provider) => {
  const item = providers.value.find(p => p.code === provider)
  return item?.name || provider
}

// 获取提供商类型
const getProviderType = (provider) => {
  const item = providers.value.find(p => p.code === provider)
  return item?.tag_type || 'primary'
}

// 提供商信息映射 (computed)
const providerInfo = computed(() => {
  const map = {}
  providers.value.forEach(p => {
    map[p.code] = {
      title: p.title,
      description: p.description,
      applyUrl: p.apply_url,
      docUrl: p.doc_url,
      defaultApiBase: p.default_api_base,
      hasFreeQuota: p.has_free_quota === 1
    }
  })
  return map
})

// 加载提供商列表
const loadProviders = async () => {
  try {
    const response = await getLLMProviders()
    providers.value = response.data || response || []
  } catch (error) {
    console.error('加载提供商列表失败', error)
  }
}

// 提供商变更时的处理
const onProviderChange = (provider) => {
  const info = providerInfo.value[provider]
  if (info?.defaultApiBase && !form.api_base) {
    // 如果API Base为空，自动填充默认值
    form.api_base = info.defaultApiBase
  }
}

// 填充默认 API Base
const fillDefaultApiBase = () => {
  const info = providerInfo.value[form.provider]
  if (info?.defaultApiBase) {
    form.api_base = info.defaultApiBase
    ElMessage.success('已填充默认API地址')
  }
}

// 加载模型列表
const loadModels = async () => {
  loading.value = true
  try {
    const params = {
      skip: (currentPage.value - 1) * pageSize.value,
      limit: pageSize.value,
      search: searchQuery.value || undefined,
      provider: filterProvider.value || undefined,
      is_active: filterStatus.value !== null ? filterStatus.value : undefined
    }
    const response = await getLLMModels(params)
    const data = response.data || response
    models.value = data.items || []
    total.value = data.total || 0
  } catch (error) {
    ElMessage.error('加载模型列表失败')
    console.error(error)
  } finally {
    loading.value = false
  }
}

// 搜索
const handleSearch = () => {
  currentPage.value = 1
  loadModels()
}

// 重置筛选
const resetFilters = () => {
  searchQuery.value = ''
  filterProvider.value = null
  filterStatus.value = null
  currentPage.value = 1
  loadModels()
}

// 添加模型
const addModel = () => {
  dialogTitle.value = '添加模型'
  resetForm()
  dialogVisible.value = true
}

// 编辑模型
const editModel = (row) => {
  dialogTitle.value = '编辑模型'
  form.id = row.id
  form.uuid = row.uuid
  form.name = row.name
  form.display_name = row.display_name
  form.provider = row.provider
  form.model_type = row.model_type
  form.api_base = row.api_base || ''
  form.api_key = row.api_key || ''
  form.api_version = row.api_version || ''
  form.max_tokens = row.max_tokens
  form.temperature = row.temperature
  form.top_p = row.top_p
  form.frequency_penalty = row.frequency_penalty || 0.00
  form.presence_penalty = row.presence_penalty || 0.00
  form.description = row.description || ''
  form.is_active = row.is_active
  form.is_default = row.is_default
  dialogVisible.value = true
}

// 查看模型
const viewModel = (row) => {
  currentModel.value = row
  viewDialogVisible.value = true
}

// 设置默认模型
const setDefault = async (row) => {
  try {
    await setDefaultLLMModel(row.id)
    ElMessage.success('设置成功')
    loadModels()
  } catch (error) {
    ElMessage.error(error.response?.data?.message || '设置失败')
  }
}

// 删除模型
const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除模型 "${row.display_name}" 吗？`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    await deleteLLMModel(row.id)
    ElMessage.success('删除成功')
    loadModels()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error(error.response?.data?.message || '删除失败')
    }
  }
}

// 提交表单
const handleSubmit = async () => {
  if (!formRef.value) return
  
  try {
    await formRef.value.validate()
  } catch {
    return
  }
  
  submitting.value = true
  try {
    if (form.id) {
      // 更新（使用整数 ID）
      await updateLLMModel(form.id, form)
      ElMessage.success('更新成功')
    } else {
      // 创建
      await createLLMModel(form)
      ElMessage.success('创建成功')
    }
    dialogVisible.value = false
    loadModels()
  } catch (error) {
    ElMessage.error(error.response?.data?.message || '操作失败')
    console.error(error)
  } finally {
    submitting.value = false
  }
}

// 重置表单
const resetForm = () => {
  form.id = null
  form.uuid = null
  form.name = ''
  form.display_name = ''
  form.provider = 'qwen'
  form.model_type = 'chat'
  form.api_base = ''
  form.api_key = ''
  form.api_version = ''
  form.max_tokens = 4096
  form.temperature = 0.70
  form.top_p = 0.90
  form.frequency_penalty = 0.00
  form.presence_penalty = 0.00
  form.description = ''
  form.is_active = 1
  form.is_default = 0
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
  loadProviders()
  loadModels()
})
</script>

<style scoped>
.llm-models-container {
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

/* 卡片网格布局 */
.models-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(380px, 1fr));
  gap: 20px;
  margin-bottom: 20px;
}

@media (max-width: 1400px) {
  .models-grid {
    grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  }
}

@media (max-width: 768px) {
  .models-grid {
    grid-template-columns: 1fr;
  }
}

/* 模型卡片样式 */
.model-card {
  transition: all 0.3s;
  cursor: pointer;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.model-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
}

.card-header {
  padding: 20px;
  border-bottom: 1px solid #ebeef5;
}

.header-top {
  display: flex;
  gap: 16px;
}

.model-icon {
  width: 48px;
  height: 48px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  flex-shrink: 0;
}

.model-info {
  flex: 1;
  min-width: 0;
}

.model-name {
  font-size: 18px;
  font-weight: 600;
  color: #303133;
  margin: 0 0 8px 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.model-badges {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.card-body {
  padding: 20px;
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.model-description {
  font-size: 14px;
  color: #606266;
  line-height: 1.6;
  margin: 0;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
}

.model-stats {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.stat-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: #909399;
}

.stat-item .el-icon {
  font-size: 16px;
  color: #409eff;
}

.card-footer {
  padding: 12px 20px;
  border-top: 1px solid #ebeef5;
  display: flex;
  gap: 8px;
  justify-content: space-between;
  flex-wrap: wrap;
}

.card-footer .el-button {
  flex: 1;
  min-width: 70px;
}
</style>

