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
        />
        <el-select v-model="categoryFilter" placeholder="分类" clearable style="width: 150px;">
          <el-option label="全部" value="" />
          <el-option label="通用" value="general" />
          <el-option label="设备" value="device" />
          <el-option label="教育" value="education" />
          <el-option label="客服" value="customer_service" />
        </el-select>
      </div>
      
      <el-table :data="filteredTemplates" style="margin-top: 20px;">
        <el-table-column prop="name" label="模板名称" min-width="150" />
        <el-table-column prop="category" label="分类" width="120">
          <template #default="{ row }">
            <el-tag>{{ getCategoryLabel(row.category) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="description" label="描述" min-width="200" show-overflow-tooltip />
        <el-table-column prop="usage_count" label="使用次数" width="120" align="center" />
        <el-table-column prop="created_at" label="创建时间" width="180">
          <template #default="{ row }">
            {{ formatDate(row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="handleView(row)">查看</el-button>
            <el-button link type="primary" @click="handleEdit(row)">编辑</el-button>
            <el-button link type="danger" @click="handleDelete(row)">删除</el-button>
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
        />
      </div>
    </el-card>
    
    <!-- 查看/编辑对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogMode === 'view' ? '查看模板' : (dialogMode === 'edit' ? '编辑模板' : '新建模板')"
      width="800px"
    >
      <el-form :model="form" label-width="100px">
        <el-form-item label="模板名称">
          <el-input v-model="form.name" :disabled="dialogMode === 'view'" />
        </el-form-item>
        <el-form-item label="分类">
          <el-select v-model="form.category" :disabled="dialogMode === 'view'">
            <el-option label="通用" value="general" />
            <el-option label="设备" value="device" />
            <el-option label="教育" value="education" />
            <el-option label="客服" value="customer_service" />
          </el-select>
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="form.description" type="textarea" :rows="2" :disabled="dialogMode === 'view'" />
        </el-form-item>
        <el-form-item label="提示词内容">
          <el-input
            v-model="form.content"
            type="textarea"
            :rows="10"
            :disabled="dialogMode === 'view'"
            placeholder="请输入提示词内容，可以使用 {{variable}} 作为变量占位符"
          />
        </el-form-item>
        <el-form-item label="变量说明">
          <el-input
            v-model="form.variables"
            type="textarea"
            :rows="3"
            :disabled="dialogMode === 'view'"
            placeholder="变量说明，如：{{user_name}} - 用户名称"
          />
        </el-form-item>
      </el-form>
      
      <template #footer v-if="dialogMode !== 'view'">
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSave">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Search } from '@element-plus/icons-vue'

const searchQuery = ref('')
const categoryFilter = ref('')
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)
const templates = ref([])
const dialogVisible = ref(false)
const dialogMode = ref('view') // view, edit, create
const form = ref({
  name: '',
  category: '',
  description: '',
  content: '',
  variables: ''
})

const filteredTemplates = computed(() => {
  let result = templates.value
  
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    result = result.filter(t => 
      t.name.toLowerCase().includes(query) || 
      t.description.toLowerCase().includes(query)
    )
  }
  
  if (categoryFilter.value) {
    result = result.filter(t => t.category === categoryFilter.value)
  }
  
  return result
})

onMounted(() => {
  loadTemplates()
})

function loadTemplates() {
  // TODO: 从API加载数据
  templates.value = [
    {
      id: 1,
      name: '设备故障诊断',
      category: 'device',
      description: '用于诊断设备故障的提示词模板',
      content: '请根据以下设备信息进行故障诊断...',
      usage_count: 156,
      created_at: '2024-01-15 10:30:00'
    }
  ]
  total.value = templates.value.length
}

function getCategoryLabel(category) {
  const labels = {
    general: '通用',
    device: '设备',
    education: '教育',
    customer_service: '客服'
  }
  return labels[category] || category
}

function formatDate(date) {
  return date
}

function handleCreate() {
  dialogMode.value = 'create'
  form.value = {
    name: '',
    category: '',
    description: '',
    content: '',
    variables: ''
  }
  dialogVisible.value = true
}

function handleView(row) {
  dialogMode.value = 'view'
  form.value = { ...row }
  dialogVisible.value = true
}

function handleEdit(row) {
  dialogMode.value = 'edit'
  form.value = { ...row }
  dialogVisible.value = true
}

function handleDelete(row) {
  ElMessageBox.confirm('确定要删除这个模板吗？', '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(() => {
    // TODO: 调用删除API
    ElMessage.success('删除成功')
    loadTemplates()
  })
}

function handleSave() {
  // TODO: 调用保存API
  ElMessage.success('保存成功')
  dialogVisible.value = false
  loadTemplates()
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
  }
  
  .pagination {
    margin-top: 20px;
    display: flex;
    justify-content: flex-end;
  }
}
</style>
