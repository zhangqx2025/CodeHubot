<template>
  <div class="device-groups-container">
    <div class="page-header">
      <h2>设备分组管理</h2>
      <el-button type="primary" @click="showAddDialog = true">
        <el-icon><Plus /></el-icon>
        创建分组
      </el-button>
    </div>

    <!-- 搜索和筛选 -->
    <div class="search-bar">
      <el-row :gutter="20">
        <el-col :span="8">
          <el-input
            v-model="searchQuery"
            placeholder="搜索分组名称"
            clearable
            @input="handleSearch"
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>
        </el-col>
        <el-col :span="6">
          <el-select v-model="typeFilter" placeholder="分组类型" clearable>
            <el-option label="全部" value="" />
            <el-option label="区域分组" value="area" />
            <el-option label="功能分组" value="function" />
            <el-option label="设备类型分组" value="device_type" />
          </el-select>
        </el-col>
      </el-row>
    </div>

    <!-- 设备分组表格 -->
    <el-table :data="filteredDeviceGroups" style="width: 100%" v-loading="loading">
      <el-table-column prop="id" label="ID" width="80" />
      <el-table-column prop="name" label="分组名称" />
      <el-table-column prop="description" label="描述" />
      <el-table-column prop="type" label="分组类型" width="120">
        <template #default="scope">
          <el-tag :type="getTypeTagType(scope.row.type)">
            {{ getTypeLabel(scope.row.type) }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="device_count" label="设备数量" width="100" />
      <el-table-column prop="parent_group" label="父分组" width="120">
        <template #default="scope">
          {{ scope.row.parent_group || '-' }}
        </template>
      </el-table-column>
      <el-table-column prop="created_at" label="创建时间" width="180">
        <template #default="scope">
          {{ formatDate(scope.row.created_at) }}
        </template>
      </el-table-column>
      <el-table-column label="操作" width="250">
        <template #default="scope">
          <el-button size="small" @click="viewDevices(scope.row)">查看设备</el-button>
          <el-button size="small" @click="editDeviceGroup(scope.row)">编辑</el-button>
          <el-button size="small" type="danger" @click="deleteDeviceGroup(scope.row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <div class="pagination-container">
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

    <!-- 添加/编辑对话框 -->
    <el-dialog
      v-model="showAddDialog"
      :title="editingDeviceGroup ? '编辑设备分组' : '创建设备分组'"
      width="600px"
    >
      <el-form :model="deviceGroupForm" :rules="rules" ref="deviceGroupFormRef" label-width="100px">
        <el-form-item label="分组名称" prop="name">
          <el-input v-model="deviceGroupForm.name" placeholder="请输入分组名称" />
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input
            v-model="deviceGroupForm.description"
            type="textarea"
            :rows="3"
            placeholder="请输入分组描述"
          />
        </el-form-item>
        <el-form-item label="分组类型" prop="type">
          <el-select v-model="deviceGroupForm.type" placeholder="请选择分组类型">
            <el-option label="区域分组" value="area" />
            <el-option label="功能分组" value="function" />
            <el-option label="设备类型分组" value="device_type" />
          </el-select>
        </el-form-item>
        <el-form-item label="父分组" prop="parent_group">
          <el-select v-model="deviceGroupForm.parent_group" placeholder="请选择父分组（可选）" clearable>
            <el-option
              v-for="group in availableParentGroups"
              :key="group.id"
              :label="group.name"
              :value="group.name"
            />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="showAddDialog = false">取消</el-button>
          <el-button type="primary" @click="saveDeviceGroup">确定</el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 查看设备对话框 -->
    <el-dialog v-model="showDevicesDialog" title="分组设备列表" width="800px">
      <el-table :data="groupDevices" style="width: 100%">
        <el-table-column prop="id" label="设备ID" width="80" />
        <el-table-column prop="name" label="设备名称" />
        <el-table-column prop="type" label="设备类型" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="scope">
            <el-tag :type="scope.row.status === 'online' ? 'success' : 'danger'">
              {{ scope.row.status === 'online' ? '在线' : '离线' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="location" label="位置" />
      </el-table>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Search } from '@element-plus/icons-vue'

// 响应式数据
const loading = ref(false)
const searchQuery = ref('')
const typeFilter = ref('')
const currentPage = ref(1)
const pageSize = ref(20)
const total = ref(0)
const showAddDialog = ref(false)
const showDevicesDialog = ref(false)
const editingDeviceGroup = ref(null)
const deviceGroupFormRef = ref()

// 设备分组列表
const deviceGroups = ref([
  {
    id: 1,
    name: '一楼办公区',
    description: '一楼办公区域的所有设备',
    type: 'area',
    device_count: 15,
    parent_group: null,
    created_at: '2024-01-15T10:30:00Z'
  },
  {
    id: 2,
    name: '温度监控设备',
    description: '所有温度监控相关设备',
    type: 'function',
    device_count: 8,
    parent_group: null,
    created_at: '2024-01-12T14:20:00Z'
  },
  {
    id: 3,
    name: '会议室A',
    description: '会议室A的设备分组',
    type: 'area',
    device_count: 5,
    parent_group: '一楼办公区',
    created_at: '2024-01-10T09:15:00Z'
  },
  {
    id: 4,
    name: '安防设备',
    description: '安全防护相关设备',
    type: 'function',
    device_count: 12,
    parent_group: null,
    created_at: '2024-01-08T16:45:00Z'
  }
])

// 分组设备列表（示例数据）
const groupDevices = ref([])

// 表单数据
const deviceGroupForm = reactive({
  name: '',
  description: '',
  type: '',
  parent_group: ''
})

// 表单验证规则
const rules = {
  name: [
    { required: true, message: '请输入分组名称', trigger: 'blur' }
  ],
  type: [
    { required: true, message: '请选择分组类型', trigger: 'change' }
  ]
}

// 计算属性
const filteredDeviceGroups = computed(() => {
  let filtered = deviceGroups.value

  if (searchQuery.value) {
    filtered = filtered.filter(item =>
      item.name.toLowerCase().includes(searchQuery.value.toLowerCase())
    )
  }

  if (typeFilter.value) {
    filtered = filtered.filter(item => item.type === typeFilter.value)
  }

  total.value = filtered.length
  const start = (currentPage.value - 1) * pageSize.value
  const end = start + pageSize.value
  return filtered.slice(start, end)
})

const availableParentGroups = computed(() => {
  return deviceGroups.value.filter(group => 
    !editingDeviceGroup.value || group.id !== editingDeviceGroup.value.id
  )
})

// 方法
const getTypeLabel = (type) => {
  const labels = {
    area: '区域分组',
    function: '功能分组',
    device_type: '设备类型分组'
  }
  return labels[type] || type
}

const getTypeTagType = (type) => {
  const types = {
    area: 'primary',
    function: 'success',
    device_type: 'warning'
  }
  return types[type] || ''
}

const handleSearch = () => {
  currentPage.value = 1
}

const handleSizeChange = (val) => {
  pageSize.value = val
  currentPage.value = 1
}

const handleCurrentChange = (val) => {
  currentPage.value = val
}

const viewDevices = (deviceGroup) => {
  // 模拟获取分组设备数据
  groupDevices.value = [
    {
      id: 1,
      name: `${deviceGroup.name}-设备001`,
      type: '温湿度传感器',
      status: 'online',
      location: deviceGroup.name
    },
    {
      id: 2,
      name: `${deviceGroup.name}-设备002`,
      type: '智能摄像头',
      status: 'offline',
      location: deviceGroup.name
    }
  ]
  showDevicesDialog.value = true
}

const editDeviceGroup = (deviceGroup) => {
  editingDeviceGroup.value = deviceGroup
  Object.assign(deviceGroupForm, deviceGroup)
  showAddDialog.value = true
}

const saveDeviceGroup = async () => {
  if (!deviceGroupFormRef.value) return
  
  await deviceGroupFormRef.value.validate((valid) => {
    if (valid) {
      if (editingDeviceGroup.value) {
        // 编辑设备分组
        const index = deviceGroups.value.findIndex(item => item.id === editingDeviceGroup.value.id)
        if (index !== -1) {
          deviceGroups.value[index] = { ...deviceGroups.value[index], ...deviceGroupForm }
        }
        ElMessage.success('设备分组更新成功')
      } else {
        // 添加设备分组
        const newDeviceGroup = {
          id: Date.now(),
          ...deviceGroupForm,
          device_count: 0,
          created_at: new Date().toISOString()
        }
        deviceGroups.value.unshift(newDeviceGroup)
        ElMessage.success('设备分组创建成功')
      }
      
      resetForm()
      showAddDialog.value = false
    }
  })
}

const deleteDeviceGroup = async (deviceGroup) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除设备分组"${deviceGroup.name}"吗？此操作不可恢复。`,
      '确认删除',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    const index = deviceGroups.value.findIndex(item => item.id === deviceGroup.id)
    if (index !== -1) {
      deviceGroups.value.splice(index, 1)
    }
    ElMessage.success('设备分组删除成功')
  } catch {
    // 用户取消操作
  }
}

const resetForm = () => {
  Object.assign(deviceGroupForm, {
    name: '',
    description: '',
    type: '',
    parent_group: ''
  })
  editingDeviceGroup.value = null
  deviceGroupFormRef.value?.resetFields()
}

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleString('zh-CN')
}

onMounted(() => {
  total.value = deviceGroups.value.length
})
</script>

<style scoped>
.device-groups-container {
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

.search-bar {
  margin-bottom: 20px;
}

.pagination-container {
  margin-top: 20px;
  text-align: right;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}
</style>