<template>
  <div class="roles-container">
    <div class="page-header">
      <h2>角色管理</h2>
      <div class="header-actions">
        <el-button type="primary" @click="showCreateDialog = true">
          <el-icon><Plus /></el-icon>
          添加角色
        </el-button>
      </div>
    </div>

    <!-- 角色列表 -->
    <el-card class="roles-card">
      <el-table :data="roles" style="width: 100%">
        <el-table-column prop="name" label="角色名称" />
        <el-table-column prop="displayName" label="显示名称" />
        <el-table-column prop="description" label="描述" />
        <el-table-column prop="userCount" label="用户数量" />
        <el-table-column prop="createdAt" label="创建时间" />
        <el-table-column label="操作" width="250">
          <template #default="{ row }">
            <el-button size="small" @click="viewPermissions(row)">查看权限</el-button>
            <el-button size="small" @click="editRole(row)">编辑</el-button>
            <el-button 
              v-if="!row.isSystem" 
              size="small" 
              type="danger" 
              @click="deleteRole(row)"
            >
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 创建/编辑角色对话框 -->
    <el-dialog v-model="showCreateDialog" :title="editingRole ? '编辑角色' : '添加角色'" width="600px">
      <el-form :model="roleForm" :rules="roleRules" ref="roleFormRef" label-width="100px">
        <el-form-item label="角色名称" prop="name">
          <el-input v-model="roleForm.name" placeholder="请输入角色名称" :disabled="!!editingRole" />
        </el-form-item>
        <el-form-item label="显示名称" prop="displayName">
          <el-input v-model="roleForm.displayName" placeholder="请输入显示名称" />
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input v-model="roleForm.description" type="textarea" :rows="3" placeholder="请输入角色描述" />
        </el-form-item>
        <el-form-item label="权限配置">
          <el-tree
            ref="permissionTreeRef"
            :data="permissionTree"
            :props="treeProps"
            show-checkbox
            node-key="id"
            :default-checked-keys="roleForm.permissions"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="showCreateDialog = false">取消</el-button>
          <el-button type="primary" @click="saveRole">确定</el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 权限查看对话框 -->
    <el-dialog v-model="showPermissionDialog" :title="`${selectedRole?.displayName} - 权限详情`" width="500px">
      <div v-if="selectedRole" class="permission-list">
        <el-tree
          :data="permissionTree"
          :props="treeProps"
          :default-checked-keys="selectedRole.permissions"
          show-checkbox
          disabled
        />
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'

const showCreateDialog = ref(false)
const showPermissionDialog = ref(false)
const roleFormRef = ref()
const permissionTreeRef = ref()
const editingRole = ref(null)
const selectedRole = ref(null)

const roles = ref([
  {
    id: 1,
    name: 'superuser',
    displayName: '超级管理员',
    description: '拥有系统所有权限',
    userCount: 1,
    isSystem: true,
    permissions: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    createdAt: '2024-01-01 00:00:00'
  },
  {
    id: 2,
    name: 'admin',
    displayName: '管理员',
    description: '拥有大部分管理权限',
    userCount: 2,
    isSystem: true,
    permissions: [1, 2, 3, 4, 5, 6, 7, 8],
    createdAt: '2024-01-01 00:00:00'
  },
  {
    id: 3,
    name: 'user',
    displayName: '普通用户',
    description: '基础用户权限',
    userCount: 5,
    isSystem: true,
    permissions: [1, 2, 3, 4],
    createdAt: '2024-01-01 00:00:00'
  }
])

const permissionTree = ref([
  {
    id: 1,
    label: '仪表盘',
    children: [
      { id: 2, label: '查看仪表盘' }
    ]
  },
  {
    id: 3,
    label: '设备管理',
    children: [
      { id: 4, label: '查看设备列表' },
      { id: 5, label: '注册设备' },
      { id: 6, label: '编辑设备' },
      { id: 7, label: '删除设备' }
    ]
  },
  {
    id: 8,
    label: '数据分析',
    children: [
      { id: 9, label: '查看数据概览' },
      { id: 10, label: '查看数据图表' },
      { id: 11, label: '导出数据报告' }
    ]
  },
  {
    id: 12,
    label: '告警管理',
    children: [
      { id: 13, label: '查看告警列表' },
      { id: 14, label: '处理告警' },
      { id: 15, label: '配置告警规则' }
    ]
  },
  {
    id: 16,
    label: '用户管理',
    children: [
      { id: 17, label: '查看用户列表' },
      { id: 18, label: '添加用户' },
      { id: 19, label: '编辑用户' },
      { id: 20, label: '删除用户' }
    ]
  },
  {
    id: 21,
    label: '系统管理',
    children: [
      { id: 22, label: '系统配置' },
      { id: 23, label: '查看系统日志' },
      { id: 24, label: '数据备份' }
    ]
  }
])

const roleForm = reactive({
  name: '',
  displayName: '',
  description: '',
  permissions: []
})

const roleRules = {
  name: [{ required: true, message: '请输入角色名称', trigger: 'blur' }],
  displayName: [{ required: true, message: '请输入显示名称', trigger: 'blur' }],
  description: [{ required: true, message: '请输入角色描述', trigger: 'blur' }]
}

const treeProps = {
  children: 'children',
  label: 'label'
}

const editRole = (role) => {
  editingRole.value = role
  Object.assign(roleForm, {
    name: role.name,
    displayName: role.displayName,
    description: role.description,
    permissions: role.permissions
  })
  showCreateDialog.value = true
}

const deleteRole = async (role) => {
  try {
    await ElMessageBox.confirm(`确定要删除角色"${role.displayName}"吗？`, '确认删除', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    const index = roles.value.findIndex(item => item.id === role.id)
    if (index !== -1) {
      roles.value.splice(index, 1)
    }
    ElMessage.success('角色删除成功')
  } catch {
    // 用户取消操作
  }
}

const viewPermissions = (role) => {
  selectedRole.value = role
  showPermissionDialog.value = true
}

const saveRole = async () => {
  if (!roleFormRef.value) return
  
  await roleFormRef.value.validate((valid) => {
    if (valid) {
      // 获取选中的权限
      const checkedKeys = permissionTreeRef.value.getCheckedKeys()
      const halfCheckedKeys = permissionTreeRef.value.getHalfCheckedKeys()
      const allPermissions = [...checkedKeys, ...halfCheckedKeys]
      
      if (editingRole.value) {
        const index = roles.value.findIndex(item => item.id === editingRole.value.id)
        if (index !== -1) {
          roles.value[index] = { 
            ...roles.value[index], 
            ...roleForm,
            permissions: allPermissions
          }
        }
        ElMessage.success('角色更新成功')
      } else {
        const newRole = {
          id: Date.now(),
          ...roleForm,
          permissions: allPermissions,
          userCount: 0,
          isSystem: false,
          createdAt: new Date().toLocaleString()
        }
        roles.value.push(newRole)
        ElMessage.success('角色创建成功')
      }
      
      resetForm()
      showCreateDialog.value = false
    }
  })
}

const resetForm = () => {
  Object.assign(roleForm, {
    name: '',
    displayName: '',
    description: '',
    permissions: []
  })
  editingRole.value = null
  roleFormRef.value?.resetFields()
  permissionTreeRef.value?.setCheckedKeys([])
}
</script>

<style scoped>
.roles-container {
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

.roles-card {
  margin-bottom: 20px;
}

.permission-list {
  max-height: 400px;
  overflow-y: auto;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}
</style>