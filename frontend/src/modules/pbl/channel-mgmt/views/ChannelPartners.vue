<template>
  <div class="channel-partners">
    <el-card class="header-card" shadow="never">
      <div class="header-content">
        <div>
          <h2 class="page-title">渠道商管理</h2>
          <p class="page-description">管理平台所有渠道商账号</p>
        </div>
        <el-button type="primary" :icon="Plus" @click="showCreateDialog">
          新增渠道商
        </el-button>
      </div>
    </el-card>

    <el-card class="content-card" shadow="never" v-loading="loading">
      <template #header>
        <div class="card-header">
          <span class="card-title">渠道商列表</span>
          <el-input
            v-model="searchText"
            placeholder="搜索渠道商名称"
            style="width: 300px"
            clearable
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>
        </div>
      </template>

      <el-table :data="filteredPartners" style="width: 100%">
        <el-table-column prop="username" label="账号" width="150" />
        <el-table-column prop="name" label="渠道商名称" width="150" />
        <el-table-column prop="company_name" label="公司名称" min-width="200" />
        <el-table-column prop="phone" label="联系电话" width="130" />
        <el-table-column prop="email" label="邮箱" min-width="180" />
        
        <el-table-column prop="school_count" label="负责学校数" width="120" align="center">
          <template #default="{ row }">
            <el-tag>{{ row.school_count || 0 }}</el-tag>
          </template>
        </el-table-column>
        
        <el-table-column prop="course_count" label="课程数" width="100" align="center">
          <template #default="{ row }">
            <el-tag type="success">{{ row.course_count || 0 }}</el-tag>
          </template>
        </el-table-column>
        
        <el-table-column prop="is_active" label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.is_active ? 'success' : 'info'">
              {{ row.is_active ? '正常' : '已禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        
        <el-table-column label="操作" width="300" align="center" fixed="right">
          <template #default="{ row }">
            <el-button size="small" @click="viewDetail(row)">查看</el-button>
            <el-button size="small" type="primary" @click="showEditDialog(row)">编辑</el-button>
            <el-button size="small" type="warning" @click="resetPassword(row)">重置密码</el-button>
            <el-button
              size="small"
              :type="row.is_active ? 'danger' : 'success'"
              @click="toggleStatus(row)"
            >
              {{ row.is_active ? '禁用' : '启用' }}
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <div v-if="filteredPartners.length === 0 && !loading" class="empty-state">
        <el-empty description="暂无渠道商数据" />
      </div>
    </el-card>

    <!-- 创建/编辑对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="dialogType === 'create' ? '新增渠道商' : '编辑渠道商'"
      width="600px"
    >
      <el-form :model="formData" :rules="formRules" ref="formRef" label-width="100px">
        <el-form-item label="账号" prop="username" v-if="dialogType === 'create'">
          <el-input v-model="formData.username" placeholder="请输入账号" />
        </el-form-item>
        <el-form-item label="密码" prop="password" v-if="dialogType === 'create'">
          <el-input v-model="formData.password" type="password" placeholder="请输入密码（至少6位）" />
        </el-form-item>
        <el-form-item label="渠道商名称" prop="name">
          <el-input v-model="formData.name" placeholder="请输入渠道商名称" />
        </el-form-item>
        <el-form-item label="公司名称" prop="company_name">
          <el-input v-model="formData.company_name" placeholder="请输入公司名称" />
        </el-form-item>
        <el-form-item label="联系电话" prop="phone">
          <el-input v-model="formData.phone" placeholder="请输入联系电话" />
        </el-form-item>
        <el-form-item label="邮箱" prop="email">
          <el-input v-model="formData.email" placeholder="请输入邮箱" />
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
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Plus } from '@element-plus/icons-vue'
import {
  getChannelPartners,
  createChannelPartner,
  updateChannelPartner,
  resetPartnerPassword
} from '../api'

const router = useRouter()

const loading = ref(false)
const partners = ref([])
const searchText = ref('')
const dialogVisible = ref(false)
const dialogType = ref('create')
const formRef = ref(null)
const submitting = ref(false)

const formData = ref({
  username: '',
  password: '',
  name: '',
  company_name: '',
  phone: '',
  email: ''
})

const formRules = {
  username: [{ required: true, message: '请输入账号', trigger: 'blur' }],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码至少6位', trigger: 'blur' }
  ],
  name: [{ required: true, message: '请输入渠道商名称', trigger: 'blur' }]
}

const filteredPartners = computed(() => {
  if (!searchText.value) return partners.value
  return partners.value.filter(partner =>
    partner.name?.toLowerCase().includes(searchText.value.toLowerCase()) ||
    partner.username?.toLowerCase().includes(searchText.value.toLowerCase()) ||
    partner.company_name?.toLowerCase().includes(searchText.value.toLowerCase())
  )
})

async function fetchPartners() {
  loading.value = true
  try {
    const response = await getChannelPartners()
    partners.value = response.data || []
  } catch (error) {
    console.error('获取渠道商列表失败:', error)
    ElMessage.error(error.message || '获取渠道商列表失败')
  } finally {
    loading.value = false
  }
}

function showCreateDialog() {
  dialogType.value = 'create'
  formData.value = {
    username: '',
    password: '',
    name: '',
    company_name: '',
    phone: '',
    email: ''
  }
  dialogVisible.value = true
}

function showEditDialog(partner) {
  dialogType.value = 'edit'
  formData.value = {
    id: partner.id,
    name: partner.name,
    company_name: partner.company_name,
    phone: partner.phone,
    email: partner.email
  }
  dialogVisible.value = true
}

async function handleSubmit() {
  try {
    await formRef.value.validate()
    submitting.value = true

    if (dialogType.value === 'create') {
      await createChannelPartner(formData.value)
      ElMessage.success('渠道商创建成功')
    } else {
      await updateChannelPartner(formData.value.id, formData.value)
      ElMessage.success('渠道商信息更新成功')
    }

    dialogVisible.value = false
    fetchPartners()
  } catch (error) {
    if (error.message) {
      ElMessage.error(error.message)
    }
  } finally {
    submitting.value = false
  }
}

function resetPassword(partner) {
  ElMessageBox.prompt('请输入新密码（至少6位）', '重置密码', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    inputType: 'password',
    inputValidator: (value) => {
      if (!value) return '请输入新密码'
      if (value.length < 6) return '密码至少6位'
      return true
    }
  }).then(async ({ value }) => {
    try {
      await resetPartnerPassword(partner.id, value)
      ElMessage.success('密码重置成功')
    } catch (error) {
      ElMessage.error(error.message || '密码重置失败')
    }
  }).catch(() => {})
}

function toggleStatus(partner) {
  const action = partner.is_active ? '禁用' : '启用'
  ElMessageBox.confirm(`确定要${action}该渠道商吗？`, '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(async () => {
    try {
      await updateChannelPartner(partner.id, { is_active: !partner.is_active })
      ElMessage.success(`${action}成功`)
      fetchPartners()
    } catch (error) {
      ElMessage.error(error.message || `${action}失败`)
    }
  }).catch(() => {})
}

function viewDetail(partner) {
  router.push({
    name: 'ChannelPartnerDetail',
    params: { partnerId: partner.id }
  })
}

onMounted(() => {
  fetchPartners()
})
</script>

<style scoped lang="scss">
.channel-partners {
  .header-card {
    margin-bottom: 20px;
    
    .header-content {
      display: flex;
      justify-content: space-between;
      align-items: center;
      
      .page-title {
        font-size: 24px;
        font-weight: 600;
        color: #2c3e50;
        margin: 0 0 8px 0;
      }
      
      .page-description {
        color: #909399;
        margin: 0;
      }
    }
  }
  
  .content-card {
    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      
      .card-title {
        font-size: 16px;
        font-weight: 600;
        color: #2c3e50;
      }
    }
    
    .empty-state {
      padding: 40px 0;
    }
  }
}
</style>
