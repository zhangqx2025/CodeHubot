<template>
  <div class="users-container">
    <div class="page-header">
      <h2>用户管理</h2>
      <div class="header-actions">
        <el-button type="primary" @click="handleAddUser">
          <el-icon><Plus /></el-icon>
          添加用户
        </el-button>
      </div>
    </div>

    <!-- 筛选条件 -->
    <el-card class="filter-card">
      <el-form :model="filterForm" inline>
        <el-form-item label="用户名">
          <el-input v-model="filterForm.username" placeholder="输入用户名" clearable />
        </el-form-item>
        <el-form-item label="角色">
          <el-select v-model="filterForm.role" placeholder="选择角色" clearable>
            <el-option label="全部" value="" />
            <el-option label="管理员" value="admin" />
            <el-option label="普通用户" value="user" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="filterForm.is_active" placeholder="选择状态" clearable>
            <el-option label="全部" :value="null" />
            <el-option label="启用" :value="true" />
            <el-option label="禁用" :value="false" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="loadUsers">查询</el-button>
          <el-button @click="resetFilter">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 用户列表 -->
    <el-card class="users-card">
      <el-table :data="users" v-loading="loading" style="width: 100%">
        <el-table-column prop="username" label="用户名" />
        <el-table-column prop="email" label="邮箱" />
        <el-table-column prop="role" label="角色">
          <template #default="{ row }">
            <el-tag :type="getRoleTagType(row.role)">{{ getRoleLabel(row.role) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="is_active" label="状态">
          <template #default="{ row }">
            <el-switch 
              v-model="row.is_active" 
              @change="handleToggleStatus(row)"
              :disabled="row.role === 'admin' && row.email === 'admin@aiot.com'"
            />
          </template>
        </el-table-column>
        <el-table-column prop="last_login" label="最后登录">
          <template #default="{ row }">
            {{ formatDateTime(row.last_login) }}
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间">
          <template #default="{ row }">
            {{ formatDateTime(row.created_at) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="250">
          <template #default="{ row }">
            <el-button size="small" @click="handleEditUser(row)">编辑</el-button>
            <el-button size="small" @click="handleResetPassword(row)">重置密码</el-button>
            <el-button 
              v-if="!(row.role === 'admin' && row.email === 'admin@aiot.com')" 
              size="small" 
              type="danger" 
              @click="handleDeleteUser(row)"
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
          :page-sizes="[10, 20, 50, 100]"
          :total="total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 创建/编辑用户对话框 -->
    <el-dialog v-model="showCreateDialog" :title="editingUser ? '编辑用户' : '添加用户'" width="600px">
      <el-form :model="userForm" :rules="userRules" ref="userFormRef" label-width="100px" autocomplete="off">
        <el-form-item label="用户名" prop="username">
          <el-input 
            v-model="userForm.username" 
            placeholder="请输入用户名" 
            :disabled="!!editingUser" 
            autocomplete="off"
            :name="`username-${Date.now()}`"
          />
        </el-form-item>
        <el-form-item label="邮箱" prop="email">
          <el-input 
            v-model="userForm.email" 
            placeholder="请输入邮箱" 
            autocomplete="off"
            :name="`email-${Date.now()}`"
          />
        </el-form-item>
        <el-form-item v-if="!editingUser" label="密码" prop="password">
          <el-input 
            v-model="userForm.password" 
            type="password" 
            placeholder="请输入密码" 
            show-password 
            autocomplete="new-password"
            :name="`password-${Date.now()}`"
          />
          <div class="form-tip">密码需包含：至少8位，大小写字母、数字和特殊字符</div>
        </el-form-item>
        <el-form-item label="角色" prop="role">
          <el-select 
            v-model="userForm.role" 
            placeholder="请选择角色"
            autocomplete="off"
          >
            <el-option label="普通用户" value="user" />
            <el-option label="管理员" value="admin" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="showCreateDialog = false">取消</el-button>
          <el-button type="primary" @click="handleSaveUser" :loading="saving">确定</el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 重置密码对话框 -->
    <el-dialog v-model="showPasswordDialog" title="重置密码" width="500px">
      <el-form :model="passwordForm" :rules="passwordRules" ref="passwordFormRef" label-width="100px" autocomplete="off">
        <el-form-item label="新密码" prop="newPassword">
          <el-input 
            v-model="passwordForm.newPassword" 
            type="password" 
            placeholder="请输入新密码" 
            show-password 
            autocomplete="new-password"
            :name="`new-password-${Date.now()}`"
          />
          <div class="form-tip">密码需包含：至少8位，大小写字母、数字和特殊字符</div>
        </el-form-item>
        <el-form-item label="确认密码" prop="confirmPassword">
          <el-input 
            v-model="passwordForm.confirmPassword" 
            type="password" 
            placeholder="请再次输入密码" 
            show-password 
            autocomplete="new-password"
            :name="`confirm-password-${Date.now()}`"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="showPasswordDialog = false">取消</el-button>
          <el-button type="primary" @click="handleConfirmResetPassword" :loading="resetting">确定</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'
import { getUserList, createUser, updateUser, deleteUser, toggleUserStatus, resetUserPassword } from '@/api/users'

const showCreateDialog = ref(false)
const showPasswordDialog = ref(false)
const userFormRef = ref()
const passwordFormRef = ref()
const editingUser = ref(null)
const resettingUser = ref(null)
const currentPage = ref(1)
const pageSize = ref(10)
const total = ref(0)
const loading = ref(false)
const saving = ref(false)
const resetting = ref(false)

const filterForm = reactive({
  username: '',
  role: '',
  is_active: null
})

const users = ref([])

const userForm = reactive({
  username: '',
  email: '',
  password: '',
  role: 'user'
})

const passwordForm = reactive({
  newPassword: '',
  confirmPassword: ''
})

const userRules = {
  username: [{ required: true, message: '请输入用户名', trigger: 'blur' }],
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    { type: 'email', message: '请输入正确的邮箱格式', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 8, message: '密码长度至少8位', trigger: 'blur' }
  ],
  role: [{ required: true, message: '请选择角色', trigger: 'change' }]
}

const passwordRules = {
  newPassword: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 8, message: '密码长度至少8位', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请再次输入密码', trigger: 'blur' },
    {
      validator: (rule, value, callback) => {
        if (value !== passwordForm.newPassword) {
          callback(new Error('两次输入的密码不一致'))
        } else {
          callback()
        }
      },
      trigger: 'blur'
    }
  ]
}

const getRoleLabel = (role) => {
  const labels = {
    admin: '管理员',
    user: '普通用户'
  }
  return labels[role] || role
}

const getRoleTagType = (role) => {
  const types = {
    admin: 'warning',
    user: 'primary'
  }
  return types[role] || 'default'
}

const formatDateTime = (dateTime) => {
  if (!dateTime) return '-'
  const date = new Date(dateTime)
  return date.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  })
}

// 加载用户列表
const loadUsers = async () => {
  loading.value = true
  try {
    const params = {
      skip: (currentPage.value - 1) * pageSize.value,
      limit: pageSize.value
    }
    
    if (filterForm.username) {
      params.username = filterForm.username
    }
    
    if (filterForm.role) {
      params.role = filterForm.role
    }
    
    if (filterForm.is_active !== null) {
      params.is_active = filterForm.is_active
    }
    
    const response = await getUserList(params)
    console.log('用户列表响应:', response.data)
    
    // 后端返回格式：{ data: [...], total: 100, skip: 0, limit: 10 }
    // axios会将后端响应放在response.data中
    if (response.data) {
      if (Array.isArray(response.data.data)) {
        // 标准格式：response.data = { data: [...], total: 7 }
        users.value = response.data.data
        total.value = response.data.total || response.data.data.length
        console.log('加载用户数据:', users.value.length, '条，总计:', total.value)
      } else if (Array.isArray(response.data)) {
        // 兼容直接返回数组的情况
        users.value = response.data
        total.value = response.data.length
        console.log('加载用户数据（数组格式）:', users.value.length, '条')
      } else {
        console.warn('无法解析的响应格式:', response.data)
        users.value = []
        total.value = 0
      }
    } else {
      console.warn('响应数据为空')
      users.value = []
      total.value = 0
    }
  } catch (error) {
    ElMessage.error(error.response?.data?.detail || '获取用户列表失败')
  } finally {
    loading.value = false
  }
}

const resetFilter = () => {
  filterForm.username = ''
  filterForm.role = ''
  filterForm.is_active = null
  currentPage.value = 1
  loadUsers()
}

const handleAddUser = () => {
  editingUser.value = null
  resetForm()
  showCreateDialog.value = true
}

const handleEditUser = (user) => {
  editingUser.value = user
  Object.assign(userForm, {
    username: user.username,
    email: user.email,
    role: user.role,
    password: '' // 编辑时不显示密码
  })
  showCreateDialog.value = true
}

const handleSaveUser = async () => {
  if (!userFormRef.value) return
  
  await userFormRef.value.validate(async (valid) => {
    if (valid) {
      saving.value = true
      try {
        if (editingUser.value) {
          // 更新用户
          await updateUser(editingUser.value.id, {
            username: userForm.username,
            is_active: editingUser.value.is_active // 保持原有状态
          })
          ElMessage.success('用户更新成功')
        } else {
          // 创建用户
          await createUser({
            username: userForm.username,
            email: userForm.email,
            password: userForm.password,
            role: userForm.role
          })
          ElMessage.success('用户创建成功')
        }
        
        resetForm()
        showCreateDialog.value = false
        loadUsers()
      } catch (error) {
        ElMessage.error(error.response?.data?.detail || '操作失败')
      } finally {
        saving.value = false
      }
    }
  })
}

const handleDeleteUser = async (user) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除用户"${user.username}"吗？此操作不可恢复！`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await deleteUser(user.id)
    ElMessage.success('用户删除成功')
    loadUsers()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error(error.response?.data?.detail || '删除用户失败')
    }
  }
}

const handleToggleStatus = async (user) => {
  try {
    await toggleUserStatus(user.id)
    ElMessage.success(`用户已${user.is_active ? '启用' : '禁用'}`)
    loadUsers()
  } catch (error) {
    // 如果失败，恢复原状态
    user.is_active = !user.is_active
    ElMessage.error(error.response?.data?.detail || '操作失败')
  }
}

const handleResetPassword = (user) => {
  resettingUser.value = user
  passwordForm.newPassword = ''
  passwordForm.confirmPassword = ''
  showPasswordDialog.value = true
}

const handleConfirmResetPassword = async () => {
  if (!passwordFormRef.value) return
  
  await passwordFormRef.value.validate(async (valid) => {
    if (valid) {
      resetting.value = true
      try {
        await resetUserPassword(resettingUser.value.id, passwordForm.newPassword)
        ElMessage.success('密码重置成功')
        showPasswordDialog.value = false
        passwordForm.newPassword = ''
        passwordForm.confirmPassword = ''
      } catch (error) {
        ElMessage.error(error.response?.data?.detail || '密码重置失败')
      } finally {
        resetting.value = false
      }
    }
  })
}

const resetForm = () => {
  Object.assign(userForm, {
    username: '',
    email: '',
    password: '',
    role: 'user'
  })
  editingUser.value = null
  userFormRef.value?.resetFields()
}

const handleSizeChange = (val) => {
  pageSize.value = val
  currentPage.value = 1
  loadUsers()
}

const handleCurrentChange = (val) => {
  currentPage.value = val
  loadUsers()
}

onMounted(() => {
  loadUsers()
})
</script>

<style scoped>
.users-container {
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

.filter-card {
  margin-bottom: 20px;
}

.users-card {
  margin-bottom: 20px;
}

.pagination {
  display: flex;
  justify-content: center;
  margin-top: 20px;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.form-tip {
  font-size: 12px;
  color: #909399;
  margin-top: 4px;
}
</style>
