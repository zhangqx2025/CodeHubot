<template>
  <div class="prompt-templates">
    <el-card shadow="never">
      <template #header>
        <div class="card-header">
          <span>提示词模板管理</span>
          <el-button type="primary" @click="handleCreate">
            <el-icon><Plus /></el-icon> 新建模板
          </el-button>
        </div>
      </template>
      
      <div class="filter-section">
        <el-input
          v-model="searchQuery"
          placeholder="搜索模板名称或描述"
          :prefix-icon="Search"
          clearable
          style="width: 300px; margin-right: 10px;"
          @input="handleSearch"
        />
        <el-input
          v-model="categoryFilter"
          placeholder="按分类筛选"
          clearable
          style="width: 150px; margin-right: 10px;"
          @change="loadTemplates"
        />
        <!-- 激活状态筛选暂时隐藏 -->
        <el-checkbox v-model="showActiveOnly" @change="loadTemplates" v-if="false">仅显示激活</el-checkbox>
      </div>
      
      <el-table v-loading="loading" :data="templates" style="margin-top: 20px;">
        <el-table-column prop="name" label="模板名称" min-width="180">
          <template #default="{ row }">
            <div style="display: flex; align-items: center; gap: 8px;">
              <span>{{ row.name }}</span>
              <el-tag v-if="row.is_system" type="warning" size="small">系统</el-tag>
              <el-tag v-else type="info" size="small">个人</el-tag>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="category" label="分类" width="120">
          <template #default="{ row }">
            <el-tag>{{ row.category || '未分类' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="description" label="描述" min-width="250" show-overflow-tooltip />
        <!-- 状态列暂时隐藏 -->
        <el-table-column prop="is_active" label="状态" width="80" align="center" v-if="false">
          <template #default="{ row }">
            <el-tag :type="row.is_active ? 'success' : 'info'" size="small">
              {{ row.is_active ? '激活' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="180">
          <template #default="{ row }">
            {{ formatDate(row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="handleView(row)">查看</el-button>
            <el-button 
              link 
              type="primary" 
              @click="handleEdit(row)"
              :disabled="!canEdit(row)"
            >
              编辑
            </el-button>
            <el-button 
              link 
              type="danger" 
              @click="handleDelete(row)"
              :disabled="!canDelete(row)"
            >
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
      
      <div class="pagination">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :total="total"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="loadTemplates"
          @current-change="loadTemplates"
        />
      </div>
    </el-card>
    
    <!-- 查看/编辑对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="700px"
      :close-on-click-modal="false"
    >
      <el-form :model="form" :rules="rules" ref="formRef" label-width="100px">
        <el-form-item label="模板名称" prop="name">
          <el-input 
            v-model="form.name" 
            :disabled="dialogMode === 'view'" 
            placeholder="请输入模板名称"
          />
        </el-form-item>
        
        <!-- 模板类型：只有管理员在创建时才显示 -->
        <el-form-item label="模板类型" v-if="dialogMode !== 'view' && authStore.isAdmin && dialogMode === 'create'">
          <el-radio-group v-model="form.is_system">
            <el-radio :label="false">个人模板</el-radio>
            <el-radio :label="true">系统模板</el-radio>
          </el-radio-group>
          <div style="font-size: 12px; color: #909399; margin-top: 5px;">
            {{ form.is_system ? '系统模板对所有用户可见，只有管理员可创建' : '个人模板仅自己可见' }}
          </div>
        </el-form-item>
        
        <!-- 编辑模式下显示当前模板类型（只读） -->
        <el-form-item label="模板类型" v-if="dialogMode === 'edit'">
          <el-tag :type="form.is_system ? 'warning' : 'info'">
            {{ form.is_system ? '系统模板' : '个人模板' }}
          </el-tag>
          <div style="font-size: 12px; color: #909399; margin-top: 5px;">
            模板类型创建后不可修改
          </div>
        </el-form-item>
        
        <el-form-item label="分类" prop="category">
          <el-input 
            v-model="form.category" 
            :disabled="dialogMode === 'view'"
            placeholder="如：通用助手、编程学习、物联网"
          />
        </el-form-item>
        
        <el-form-item label="描述" prop="description">
          <el-input
            v-model="form.description" 
            type="textarea"
            :rows="3" 
            :disabled="dialogMode === 'view'"
            placeholder="简要描述模板的功能和用途"
          />
        </el-form-item>
        
        <el-form-item label="提示词内容" prop="content">
          <el-input
            v-model="form.content"
            type="textarea"
            :rows="15"
            :disabled="dialogMode === 'view'"
            placeholder="请输入详细的提示词内容，定义智能体的角色、能力和行为规范"
          />
        </el-form-item>
        
        <!-- 激活状态功能暂时隐藏 -->
        <el-form-item label="是否激活" v-if="false">
          <el-switch v-model="form.is_active" :disabled="dialogMode === 'view'" />
          <span style="margin-left: 10px; font-size: 12px; color: #909399;">
            关闭后该模板将不会显示在智能体配置中
          </span>
        </el-form-item>
      </el-form>
      
      <template #footer v-if="dialogMode !== 'view'">
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSave" :loading="saving">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Search } from '@element-plus/icons-vue'
import { useAuthStore } from '@/stores/auth'
import {
  getPromptTemplates,
  getPromptTemplate,
  createPromptTemplate,
  updatePromptTemplate,
  deletePromptTemplate
} from '../api/prompt-template'

const authStore = useAuthStore()

const loading = ref(false)
const saving = ref(false)
const searchQuery = ref('')
const categoryFilter = ref('')
const showActiveOnly = ref(false) // 修改为默认显示所有模板（包括禁用的）
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)
const templates = ref([])
const dialogVisible = ref(false)
const dialogMode = ref('view') // view, edit, create
const formRef = ref(null)

const form = ref({
  name: '',
  category: '',
  description: '',
  content: '',
  is_active: true,
  is_system: false
})

const rules = {
  name: [
    { required: true, message: '请输入模板名称', trigger: 'blur' },
    { min: 1, max: 100, message: '长度在 1 到 100 个字符', trigger: 'blur' }
  ],
  content: [
    { required: true, message: '请输入提示词内容', trigger: 'blur' }
  ]
}

const dialogTitle = computed(() => {
  const titles = {
    view: '查看模板',
    edit: '编辑模板',
    create: '新建模板'
  }
  return titles[dialogMode.value]
})

onMounted(() => {
  loadTemplates()
})

// 加载模板列表
async function loadTemplates() {
  loading.value = true
  try {
    const params = {
      page: currentPage.value,
      page_size: pageSize.value,
      category: categoryFilter.value || undefined,
      is_active: showActiveOnly.value ? true : undefined
    }
    
    const response = await getPromptTemplates(params)
    templates.value = response.data.items || []
    total.value = response.data.total || 0
  } catch (error) {
    console.error('加载模板列表失败:', error)
    ElMessage.error('加载模板列表失败')
  } finally {
    loading.value = false
  }
}

// 搜索（前端过滤）
function handleSearch() {
  // 简单的前端过滤，也可以改为调用API
  loadTemplates()
}

// 权限判断
function canEdit(row) {
  // 管理员可以编辑所有模板
  if (authStore.isAdmin) return true
  // 系统模板只有管理员可以编辑
  if (row.is_system) return false
  // 个人模板只能编辑自己的
  return row.user_id === authStore.userInfo?.id
}

function canDelete(row) {
  // 管理员可以删除所有模板
  if (authStore.isAdmin) return true
  // 系统模板只有管理员可以删除
  if (row.is_system) return false
  // 个人模板只能删除自己的
  return row.user_id === authStore.userInfo?.id
}

// 格式化日期
function formatDate(date) {
  if (!date) return ''
  return new Date(date).toLocaleString('zh-CN')
}

// 创建模板
function handleCreate() {
  dialogMode.value = 'create'
  form.value = {
    name: '',
    category: '',
    description: '',
    content: '',
    is_active: true,
    is_system: false
  }
  dialogVisible.value = true
}

// 查看模板
async function handleView(row) {
  dialogMode.value = 'view'
  try {
    const response = await getPromptTemplate(row.uuid)
    form.value = { ...response.data }
  } catch (error) {
    console.error('加载模板详情失败:', error)
    ElMessage.error('加载模板详情失败')
  }
  dialogVisible.value = true
}

// 编辑模板
async function handleEdit(row) {
  if (!canEdit(row)) {
    ElMessage.warning('您没有权限编辑此模板')
    return
  }
  
  dialogMode.value = 'edit'
  try {
    const response = await getPromptTemplate(row.uuid)
    form.value = { ...response.data }
  } catch (error) {
    console.error('加载模板详情失败:', error)
    ElMessage.error('加载模板详情失败')
    return
  }
  dialogVisible.value = true
}

// 删除模板
async function handleDelete(row) {
  if (!canDelete(row)) {
    ElMessage.warning('您没有权限删除此模板')
    return
  }
  
  try {
    await ElMessageBox.confirm(
      `确定要删除模板 "${row.name}" 吗？`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await deletePromptTemplate(row.uuid)
    ElMessage.success('删除成功')
    loadTemplates()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('删除失败:', error)
      ElMessage.error(error.response?.data?.detail || '删除失败')
    }
  }
}

// 保存模板
async function handleSave() {
  if (!formRef.value) return
  
  try {
    await formRef.value.validate()
  } catch {
    return
  }
  
  // 检查权限
  if (form.value.is_system && !authStore.isAdmin) {
    ElMessage.error('只有管理员可以创建系统模板')
    return
  }
  
  saving.value = true
  try {
    // 准备提交的数据，只包含需要的字段
    const submitData = {
      name: form.value.name,
      category: form.value.category || null,
      description: form.value.description || null,
      content: form.value.content,
      is_active: form.value.is_active,
      is_system: form.value.is_system,
      // 为后端兼容性设置默认值
      tags: [],
      difficulty: null,
      suitable_for: null,
      requires_plugin: false,
      recommended_temperature: 0.70,
      sort_order: 0
    }
    
    if (dialogMode.value === 'create') {
      await createPromptTemplate(submitData)
      ElMessage.success('创建成功')
    } else {
      await updatePromptTemplate(form.value.uuid, submitData)
      ElMessage.success('更新成功')
    }
    
  dialogVisible.value = false
  loadTemplates()
  } catch (error) {
    console.error('保存失败:', error)
    ElMessage.error(error.response?.data?.detail || '保存失败')
  } finally {
    saving.value = false
  }
}
</script>

<style scoped lang="scss">
.prompt-templates {
  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  
  .filter-section {
    display: flex;
    gap: 10px;
    align-items: center;
    flex-wrap: wrap;
  }
  
  .pagination {
    margin-top: 20px;
    display: flex;
    justify-content: flex-end;
  }
}
</style>
