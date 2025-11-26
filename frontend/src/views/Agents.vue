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

    <!-- 智能体列表 - 卡片形式 -->
    <div v-loading="loading" class="agents-grid">
      <el-empty v-if="agents.length === 0 && !loading" description="暂无智能体">
        <el-button type="primary" @click="addAgent">创建第一个智能体</el-button>
      </el-empty>
      
      <el-card
        v-for="agent in agents"
        :key="agent.id"
        class="agent-card"
        shadow="hover"
        :body-style="{ padding: '0' }"
      >
        <div class="card-header">
          <div class="header-top">
            <div class="agent-icon">
              <el-icon size="24"><ChatDotRound /></el-icon>
            </div>
            <div class="agent-info">
              <h3 class="agent-name">{{ agent.name }}</h3>
              <div class="agent-badges">
                <el-tag :type="agent.is_active === 1 ? 'success' : 'info'" size="small">
                  {{ agent.is_active === 1 ? '激活' : '禁用' }}
                </el-tag>
                <el-tag v-if="agent.is_system === 1" type="warning" size="small">系统内置</el-tag>
              </div>
            </div>
          </div>
        </div>
        
        <div class="card-body">
          <p class="agent-description">{{ agent.description || '暂无描述' }}</p>
          
          <div class="agent-stats">
            <div class="stat-item">
              <el-icon><Connection /></el-icon>
              <span>{{ agent.plugin_ids?.length || 0 }} 个插件</span>
            </div>
            <div class="stat-item">
              <el-icon><Clock /></el-icon>
              <span>{{ formatDate(agent.created_at) }}</span>
            </div>
          </div>
        </div>
        
        <div class="card-footer">
          <el-button type="success" size="small" @click="useAgent(agent)">
            <el-icon><ChatDotRound /></el-icon>
            立即使用
          </el-button>
          <el-button type="primary" size="small" @click="editAgent(agent)">
            <el-icon><Edit /></el-icon>
            编排
          </el-button>
          <el-button
            type="danger"
            size="small"
            @click="handleDelete(agent)"
            :disabled="agent.is_system === 1"
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
      @size-change="loadAgents"
      @current-change="loadAgents"
      style="margin-top: 20px; justify-content: flex-end;"
    />

    <!-- 快速添加/编辑对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="500px"
      @close="resetForm"
    >
      <el-form :model="form" :rules="rules" ref="formRef" label-width="100px">
        <el-form-item label="智能体名称" prop="name">
          <el-input v-model="form.name" placeholder="请输入智能体名称" />
        </el-form-item>
        <el-form-item label="简介" prop="description">
          <el-input
            v-model="form.description"
            type="textarea"
            :rows="4"
            placeholder="请简要描述智能体的功能和用途"
          />
        </el-form-item>
        <el-alert
          v-if="!form.id"
          title="提示"
          type="info"
          :closable="false"
          show-icon
          style="margin-top: 10px;"
        >
          创建后可以在"编排"页面配置系统提示词和插件
        </el-alert>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit" :loading="submitting">
          创建并编排
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Plus, ChatDotRound, Connection, Clock, Edit, Delete } from '@element-plus/icons-vue'
import { getAgents, createAgent, updateAgent, deleteAgent } from '../api/agent'

const router = useRouter()

const loading = ref(false)
const searchQuery = ref('')
const filterStatus = ref(null)
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)
const agents = ref([])
const dialogVisible = ref(false)
const dialogTitle = ref('添加智能体')
const submitting = ref(false)
const formRef = ref(null)

const form = reactive({
  id: null,
  name: '',
  description: ''
})

const rules = {
  name: [
    { required: true, message: '请输入智能体名称', trigger: 'blur' },
    { min: 1, max: 100, message: '长度在 1 到 100 个字符', trigger: 'blur' }
  ],
  description: [
    { max: 500, message: '描述最多500个字符', trigger: 'blur' }
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

// 添加智能体（快速创建）
const addAgent = () => {
  dialogTitle.value = '添加智能体'
  resetForm()
  dialogVisible.value = true
}

// 跳转到编排页面
const editAgent = (row) => {
  router.push(`/agents/${row.uuid}/edit`)
}

// 立即使用智能体
const useAgent = (agent) => {
  router.push(`/agents/${agent.uuid}/chat`)
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
    await deleteAgent(row.uuid)
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
  
  try {
    await formRef.value.validate()
  } catch {
    return
  }
  
  submitting.value = true
  try {
    // 创建并跳转到编排页面
    const response = await createAgent({
      name: form.name,
      description: form.description
    })
      const newAgentUuid = response.data.uuid
      ElMessage.success('创建成功，正在跳转到编排页面...')
      dialogVisible.value = false
      // 跳转到编排页面
      router.push(`/agents/${newAgentUuid}/edit`)
  } catch (error) {
    ElMessage.error(error.response?.data?.detail || '操作失败')
    console.error(error)
  } finally {
    submitting.value = false
  }
}

// 重置表单
const resetForm = () => {
  form.id = null
  form.name = ''
  form.description = ''
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

/* 卡片网格布局 */
.agents-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
  margin-bottom: 20px;
}

/* 智能体卡片 */
.agent-card {
  border-radius: 12px;
  overflow: hidden;
  transition: all 0.3s ease;
  border: 1px solid #e4e7ed;
}

.agent-card:hover {
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

.agent-icon {
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

.agent-info {
  flex: 1;
  min-width: 0;
}

.agent-name {
  margin: 0 0 8px 0;
  font-size: 18px;
  font-weight: 600;
  color: #ffffff;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.agent-badges {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

/* 卡片主体 */
.card-body {
  padding: 20px;
  background: #ffffff;
}

.agent-description {
  margin: 0 0 16px 0;
  font-size: 14px;
  color: #606266;
  line-height: 1.6;
  min-height: 44px;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  text-overflow: ellipsis;
}

.agent-stats {
  display: flex;
  gap: 20px;
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
  .agents-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 768px) {
  .agents-grid {
    grid-template-columns: 1fr;
  }
}
</style>

