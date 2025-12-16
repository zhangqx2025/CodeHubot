<template>
  <div class="permissions-container">
    <div class="page-header">
      <h2>权限管理</h2>
      <div class="header-actions">
        <el-button type="primary" @click="showCreateDialog = true">
          <el-icon><Plus /></el-icon>
          添加权限
        </el-button>
      </div>
    </div>

    <!-- 权限树形结构 -->
    <el-card class="permissions-card">
      <el-tree
        :data="permissionTree"
        :props="treeProps"
        default-expand-all
        node-key="id"
        class="permission-tree"
      >
        <template #default="{ node, data }">
          <div class="tree-node">
            <div class="node-content">
              <span class="node-label">{{ data.label }}</span>
              <el-tag v-if="data.code" size="small" type="info">{{ data.code }}</el-tag>
            </div>
            <div class="node-actions">
              <el-button size="small" @click="editPermission(data)">编辑</el-button>
              <el-button size="small" @click="addChild(data)">添加子权限</el-button>
              <el-button 
                v-if="!data.isSystem" 
                size="small" 
                type="danger" 
                @click="deletePermission(data)"
              >
                删除
              </el-button>
            </div>
          </div>
        </template>
      </el-tree>
    </el-card>

    <!-- 创建/编辑权限对话框 -->
    <el-dialog v-model="showCreateDialog" :title="editingPermission ? '编辑权限' : '添加权限'" width="600px">
      <el-form :model="permissionForm" :rules="permissionRules" ref="permissionFormRef" label-width="100px">
        <el-form-item label="权限名称" prop="label">
          <el-input v-model="permissionForm.label" placeholder="请输入权限名称" />
        </el-form-item>
        <el-form-item label="权限代码" prop="code">
          <el-input v-model="permissionForm.code" placeholder="请输入权限代码，如：user:create" />
        </el-form-item>
        <el-form-item label="父级权限" prop="parentId">
          <el-tree-select
            v-model="permissionForm.parentId"
            :data="permissionTreeForSelect"
            :props="treeSelectProps"
            placeholder="选择父级权限（可选）"
            clearable
            check-strictly
          />
        </el-form-item>
        <el-form-item label="权限类型" prop="type">
          <el-select v-model="permissionForm.type" placeholder="请选择权限类型">
            <el-option label="菜单" value="menu" />
            <el-option label="按钮" value="button" />
            <el-option label="API" value="api" />
          </el-select>
        </el-form-item>
        <el-form-item label="排序" prop="sort">
          <el-input-number v-model="permissionForm.sort" :min="0" placeholder="排序值" />
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input v-model="permissionForm.description" type="textarea" :rows="3" placeholder="请输入权限描述" />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="showCreateDialog = false">取消</el-button>
          <el-button type="primary" @click="savePermission">确定</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus } from '@element-plus/icons-vue'

const showCreateDialog = ref(false)
const permissionFormRef = ref()
const editingPermission = ref(null)
const parentPermission = ref(null)

const permissionTree = ref([
  {
    id: 1,
    label: '仪表盘',
    code: 'dashboard',
    type: 'menu',
    sort: 1,
    isSystem: true,
    description: '仪表盘访问权限',
    children: [
      {
        id: 2,
        label: '查看仪表盘',
        code: 'dashboard:view',
        type: 'button',
        sort: 1,
        isSystem: true,
        description: '查看仪表盘数据'
      }
    ]
  },
  {
    id: 3,
    label: '设备管理',
    code: 'device',
    type: 'menu',
    sort: 2,
    isSystem: true,
    description: '设备管理模块',
    children: [
      {
        id: 4,
        label: '查看设备列表',
        code: 'device:list',
        type: 'button',
        sort: 1,
        isSystem: true,
        description: '查看设备列表'
      },
      {
        id: 5,
        label: '注册设备',
        code: 'device:create',
        type: 'button',
        sort: 2,
        isSystem: true,
        description: '注册新设备'
      },
      {
        id: 6,
        label: '编辑设备',
        code: 'device:update',
        type: 'button',
        sort: 3,
        isSystem: true,
        description: '编辑设备信息'
      },
      {
        id: 7,
        label: '删除设备',
        code: 'device:delete',
        type: 'button',
        sort: 4,
        isSystem: true,
        description: '删除设备'
      }
    ]
  },
  {
    id: 8,
    label: '数据分析',
    code: 'data',
    type: 'menu',
    sort: 3,
    isSystem: true,
    description: '数据分析模块',
    children: [
      {
        id: 9,
        label: '查看数据概览',
        code: 'data:overview',
        type: 'button',
        sort: 1,
        isSystem: true,
        description: '查看数据概览'
      },
      {
        id: 10,
        label: '查看数据图表',
        code: 'data:charts',
        type: 'button',
        sort: 2,
        isSystem: true,
        description: '查看数据图表'
      },
      {
        id: 11,
        label: '导出数据报告',
        code: 'data:export',
        type: 'button',
        sort: 3,
        isSystem: true,
        description: '导出数据报告'
      }
    ]
  }
])

const permissionForm = reactive({
  label: '',
  code: '',
  parentId: null,
  type: '',
  sort: 0,
  description: ''
})

const permissionRules = {
  label: [{ required: true, message: '请输入权限名称', trigger: 'blur' }],
  code: [{ required: true, message: '请输入权限代码', trigger: 'blur' }],
  type: [{ required: true, message: '请选择权限类型', trigger: 'change' }]
}

const treeProps = {
  children: 'children',
  label: 'label'
}

const treeSelectProps = {
  children: 'children',
  label: 'label',
  value: 'id'
}

// 用于选择父级权限的树形数据（排除当前编辑的权限及其子权限）
const permissionTreeForSelect = computed(() => {
  const filterTree = (nodes, excludeId = null) => {
    return nodes.filter(node => node.id !== excludeId).map(node => ({
      ...node,
      children: node.children ? filterTree(node.children, excludeId) : undefined
    }))
  }
  
  return filterTree(permissionTree.value, editingPermission.value?.id)
})

const editPermission = (permission) => {
  editingPermission.value = permission
  Object.assign(permissionForm, {
    label: permission.label,
    code: permission.code,
    parentId: findParentId(permission.id),
    type: permission.type,
    sort: permission.sort,
    description: permission.description
  })
  showCreateDialog.value = true
}

const addChild = (permission) => {
  parentPermission.value = permission
  permissionForm.parentId = permission.id
  showCreateDialog.value = true
}

const deletePermission = async (permission) => {
  try {
    await ElMessageBox.confirm(`确定要删除权限"${permission.label}"吗？`, '确认删除', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    
    removePermissionFromTree(permission.id)
    ElMessage.success('权限删除成功')
  } catch {
    // 用户取消操作
  }
}

const findParentId = (permissionId) => {
  const findParent = (nodes, targetId, parentId = null) => {
    for (const node of nodes) {
      if (node.id === targetId) {
        return parentId
      }
      if (node.children) {
        const result = findParent(node.children, targetId, node.id)
        if (result !== null) {
          return result
        }
      }
    }
    return null
  }
  
  return findParent(permissionTree.value, permissionId)
}

const removePermissionFromTree = (permissionId) => {
  const removeFromNodes = (nodes) => {
    for (let i = 0; i < nodes.length; i++) {
      if (nodes[i].id === permissionId) {
        nodes.splice(i, 1)
        return true
      }
      if (nodes[i].children && removeFromNodes(nodes[i].children)) {
        return true
      }
    }
    return false
  }
  
  removeFromNodes(permissionTree.value)
}

const addPermissionToTree = (permission, parentId = null) => {
  if (!parentId) {
    permissionTree.value.push(permission)
    return
  }
  
  const addToNodes = (nodes) => {
    for (const node of nodes) {
      if (node.id === parentId) {
        if (!node.children) {
          node.children = []
        }
        node.children.push(permission)
        return true
      }
      if (node.children && addToNodes(node.children)) {
        return true
      }
    }
    return false
  }
  
  addToNodes(permissionTree.value)
}

const updatePermissionInTree = (permission) => {
  const updateInNodes = (nodes) => {
    for (let i = 0; i < nodes.length; i++) {
      if (nodes[i].id === permission.id) {
        nodes[i] = { ...nodes[i], ...permission }
        return true
      }
      if (nodes[i].children && updateInNodes(nodes[i].children)) {
        return true
      }
    }
    return false
  }
  
  updateInNodes(permissionTree.value)
}

const savePermission = async () => {
  if (!permissionFormRef.value) return
  
  await permissionFormRef.value.validate((valid) => {
    if (valid) {
      if (editingPermission.value) {
        const updatedPermission = {
          ...editingPermission.value,
          ...permissionForm
        }
        updatePermissionInTree(updatedPermission)
        ElMessage.success('权限更新成功')
      } else {
        const newPermission = {
          id: Date.now(),
          ...permissionForm,
          isSystem: false,
          children: []
        }
        addPermissionToTree(newPermission, permissionForm.parentId)
        ElMessage.success('权限创建成功')
      }
      
      resetForm()
      showCreateDialog.value = false
    }
  })
}

const resetForm = () => {
  Object.assign(permissionForm, {
    label: '',
    code: '',
    parentId: null,
    type: '',
    sort: 0,
    description: ''
  })
  editingPermission.value = null
  parentPermission.value = null
  permissionFormRef.value?.resetFields()
}
</script>

<style scoped>
.permissions-container {
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

.permissions-card {
  margin-bottom: 20px;
}

.permission-tree {
  margin-top: 10px;
}

.tree-node {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  padding: 5px 0;
}

.node-content {
  display: flex;
  align-items: center;
  gap: 10px;
}

.node-label {
  font-weight: 500;
}

.node-actions {
  display: flex;
  gap: 5px;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}
</style>