<template>
  <div class="system-backup-container">
    <div class="page-header">
      <h2>系统备份</h2>
      <div class="header-actions">
        <el-button type="primary" @click="createBackup">
          <el-icon><Plus /></el-icon>
          创建备份
        </el-button>
        <el-button @click="refreshBackups">
          <el-icon><Refresh /></el-icon>
          刷新
        </el-button>
      </div>
    </div>

    <!-- 备份配置 -->
    <el-row :gutter="20">
      <el-col :span="12">
        <el-card class="config-card">
          <template #header>
            <div class="card-header">
              <span>备份配置</span>
              <el-button size="small" @click="saveBackupConfig">保存配置</el-button>
            </div>
          </template>
          <el-form :model="backupConfig" label-width="120px">
            <el-form-item label="自动备份">
              <el-switch v-model="backupConfig.autoBackup" />
            </el-form-item>
            <el-form-item label="备份频率">
              <el-select v-model="backupConfig.frequency" :disabled="!backupConfig.autoBackup">
                <el-option label="每日" value="daily" />
                <el-option label="每周" value="weekly" />
                <el-option label="每月" value="monthly" />
              </el-select>
            </el-form-item>
            <el-form-item label="备份时间">
              <el-time-picker 
                v-model="backupConfig.backupTime" 
                format="HH:mm"
                :disabled="!backupConfig.autoBackup"
              />
            </el-form-item>
            <el-form-item label="保留天数">
              <el-input-number v-model="backupConfig.retentionDays" :min="1" :max="365" />
              <span class="unit">天</span>
            </el-form-item>
            <el-form-item label="备份内容">
              <el-checkbox-group v-model="backupConfig.backupItems">
                <el-checkbox label="database">数据库</el-checkbox>
                <el-checkbox label="files">文件系统</el-checkbox>
                <el-checkbox label="config">配置文件</el-checkbox>
                <el-checkbox label="logs">日志文件</el-checkbox>
              </el-checkbox-group>
            </el-form-item>
            <el-form-item label="压缩备份">
              <el-switch v-model="backupConfig.compress" />
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>

      <el-col :span="12">
        <el-card class="status-card">
          <template #header>
            <span>备份状态</span>
          </template>
          <div class="status-content">
            <div class="status-item">
              <div class="status-label">最后备份时间</div>
              <div class="status-value">{{ lastBackupTime }}</div>
            </div>
            <div class="status-item">
              <div class="status-label">下次备份时间</div>
              <div class="status-value">{{ nextBackupTime }}</div>
            </div>
            <div class="status-item">
              <div class="status-label">备份总数</div>
              <div class="status-value">{{ backupStats.total }}</div>
            </div>
            <div class="status-item">
              <div class="status-label">总备份大小</div>
              <div class="status-value">{{ backupStats.totalSize }}</div>
            </div>
            <div class="status-item">
              <div class="status-label">可用空间</div>
              <div class="status-value">{{ backupStats.availableSpace }}</div>
            </div>
            <div class="status-item">
              <div class="status-label">备份状态</div>
              <div class="status-value">
                <el-tag :type="backupStatus.type" size="small">
                  {{ backupStatus.text }}
                </el-tag>
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 备份列表 -->
    <el-card class="table-card">
      <template #header>
        <div class="card-header">
          <span>备份列表</span>
          <div class="header-actions">
            <el-input
              v-model="searchKeyword"
              placeholder="搜索备份文件"
              style="width: 200px; margin-right: 10px;"
              clearable
            >
              <template #prefix>
                <el-icon><Search /></el-icon>
              </template>
            </el-input>
            <el-select v-model="filterType" placeholder="备份类型" style="width: 120px;">
              <el-option label="全部" value="" />
              <el-option label="手动" value="manual" />
              <el-option label="自动" value="auto" />
            </el-select>
          </div>
        </div>
      </template>

      <el-table :data="filteredBackups" v-loading="loading" stripe>
        <el-table-column prop="name" label="备份名称" min-width="200">
          <template #default="{ row }">
            <div class="backup-name">
              <el-icon><FolderOpened /></el-icon>
              <span>{{ row.name }}</span>
            </div>
          </template>
        </el-table-column>
        <el-table-column prop="type" label="备份类型" width="100">
          <template #default="{ row }">
            <el-tag :type="row.type === 'auto' ? 'success' : 'primary'" size="small">
              {{ row.type === 'auto' ? '自动' : '手动' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="size" label="文件大小" width="120" />
        <el-table-column prop="createTime" label="创建时间" width="180" sortable />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)" size="small">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="description" label="备份描述" min-width="200" />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button size="small" @click="downloadBackup(row)">
              <el-icon><Download /></el-icon>
              下载
            </el-button>
            <el-button size="small" @click="restoreBackup(row)" :disabled="row.status !== 'completed'">
              <el-icon><RefreshRight /></el-icon>
              恢复
            </el-button>
            <el-button size="small" type="danger" @click="deleteBackup(row)">
              <el-icon><Delete /></el-icon>
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-container">
        <el-pagination
          v-model:current-page="pagination.currentPage"
          v-model:page-size="pagination.pageSize"
          :page-sizes="[10, 20, 50, 100]"
          :total="pagination.total"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 创建备份对话框 -->
    <el-dialog v-model="createDialogVisible" title="创建备份" width="50%">
      <el-form :model="newBackup" label-width="100px">
        <el-form-item label="备份名称" required>
          <el-input v-model="newBackup.name" placeholder="请输入备份名称" />
        </el-form-item>
        <el-form-item label="备份描述">
          <el-input v-model="newBackup.description" type="textarea" :rows="3" placeholder="请输入备份描述" />
        </el-form-item>
        <el-form-item label="备份内容" required>
          <el-checkbox-group v-model="newBackup.items">
            <el-checkbox label="database">数据库</el-checkbox>
            <el-checkbox label="files">文件系统</el-checkbox>
            <el-checkbox label="config">配置文件</el-checkbox>
            <el-checkbox label="logs">日志文件</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="压缩备份">
          <el-switch v-model="newBackup.compress" />
        </el-form-item>
      </el-form>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="createDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="confirmCreateBackup">确定</el-button>
        </span>
      </template>
    </el-dialog>

    <!-- 恢复备份对话框 -->
    <el-dialog v-model="restoreDialogVisible" title="恢复备份" width="50%">
      <div class="restore-warning">
        <el-alert
          title="警告"
          type="warning"
          description="恢复备份将覆盖当前系统数据，请确保已做好数据备份。此操作不可逆，请谨慎操作。"
          show-icon
          :closable="false"
        />
      </div>
      <div v-if="selectedBackup" class="restore-info">
        <h4>备份信息</h4>
        <el-descriptions :column="2" border>
          <el-descriptions-item label="备份名称">{{ selectedBackup.name }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ selectedBackup.createTime }}</el-descriptions-item>
          <el-descriptions-item label="文件大小">{{ selectedBackup.size }}</el-descriptions-item>
          <el-descriptions-item label="备份描述">{{ selectedBackup.description }}</el-descriptions-item>
        </el-descriptions>
      </div>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="restoreDialogVisible = false">取消</el-button>
          <el-button type="danger" @click="confirmRestoreBackup">确认恢复</el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { 
  Plus, 
  Refresh, 
  Search, 
  Download, 
  Delete, 
  RefreshRight, 
  FolderOpened 
} from '@element-plus/icons-vue'

const loading = ref(false)
const createDialogVisible = ref(false)
const restoreDialogVisible = ref(false)
const selectedBackup = ref(null)
const searchKeyword = ref('')
const filterType = ref('')

const backupConfig = reactive({
  autoBackup: true,
  frequency: 'daily',
  backupTime: new Date(2024, 0, 1, 2, 0),
  retentionDays: 30,
  backupItems: ['database', 'config'],
  compress: true
})

const newBackup = reactive({
  name: '',
  description: '',
  items: ['database'],
  compress: true
})

const backupStats = reactive({
  total: 15,
  totalSize: '2.5 GB',
  availableSpace: '45.2 GB'
})

const backupStatus = reactive({
  type: 'success',
  text: '正常'
})

const lastBackupTime = ref('2024-01-15 02:00:00')
const nextBackupTime = ref('2024-01-16 02:00:00')

const pagination = reactive({
  currentPage: 1,
  pageSize: 10,
  total: 15
})

const backups = ref([
  {
    id: 1,
    name: 'backup_2024-01-15_02-00-00',
    type: 'auto',
    size: '156.8 MB',
    createTime: '2024-01-15 02:00:00',
    status: 'completed',
    description: '自动备份 - 数据库和配置文件'
  },
  {
    id: 2,
    name: 'backup_manual_2024-01-14_15-30-00',
    type: 'manual',
    size: '234.5 MB',
    createTime: '2024-01-14 15:30:00',
    status: 'completed',
    description: '手动备份 - 完整系统备份'
  },
  {
    id: 3,
    name: 'backup_2024-01-14_02-00-00',
    type: 'auto',
    size: '145.2 MB',
    createTime: '2024-01-14 02:00:00',
    status: 'completed',
    description: '自动备份 - 数据库和配置文件'
  },
  {
    id: 4,
    name: 'backup_2024-01-13_02-00-00',
    type: 'auto',
    size: '142.1 MB',
    createTime: '2024-01-13 02:00:00',
    status: 'completed',
    description: '自动备份 - 数据库和配置文件'
  },
  {
    id: 5,
    name: 'backup_2024-01-12_02-00-00',
    type: 'auto',
    size: '138.9 MB',
    createTime: '2024-01-12 02:00:00',
    status: 'failed',
    description: '自动备份 - 备份失败'
  }
])

const filteredBackups = computed(() => {
  let filtered = backups.value
  
  if (searchKeyword.value) {
    filtered = filtered.filter(backup => 
      backup.name.toLowerCase().includes(searchKeyword.value.toLowerCase()) ||
      backup.description.toLowerCase().includes(searchKeyword.value.toLowerCase())
    )
  }
  
  if (filterType.value) {
    filtered = filtered.filter(backup => backup.type === filterType.value)
  }
  
  return filtered
})

const getStatusType = (status) => {
  const types = {
    'completed': 'success',
    'failed': 'danger',
    'running': 'warning'
  }
  return types[status] || ''
}

const getStatusText = (status) => {
  const texts = {
    'completed': '完成',
    'failed': '失败',
    'running': '进行中'
  }
  return texts[status] || status
}

const saveBackupConfig = () => {
  ElMessage.success('备份配置保存成功')
}

const createBackup = () => {
  newBackup.name = `backup_manual_${new Date().toISOString().slice(0, 19).replace(/[:-]/g, '-').replace('T', '_')}`
  newBackup.description = ''
  newBackup.items = ['database']
  createDialogVisible.value = true
}

const confirmCreateBackup = () => {
  if (!newBackup.name || newBackup.items.length === 0) {
    ElMessage.error('请填写备份名称并选择备份内容')
    return
  }
  
  createDialogVisible.value = false
  ElMessage.info('正在创建备份...')
  
  setTimeout(() => {
    ElMessage.success('备份创建成功')
    refreshBackups()
  }, 3000)
}

const downloadBackup = (backup) => {
  ElMessage.info(`正在下载备份文件: ${backup.name}`)
  setTimeout(() => {
    ElMessage.success('备份文件下载成功')
  }, 2000)
}

const restoreBackup = (backup) => {
  selectedBackup.value = backup
  restoreDialogVisible.value = true
}

const confirmRestoreBackup = () => {
  restoreDialogVisible.value = false
  ElMessage.info('正在恢复备份...')
  
  setTimeout(() => {
    ElMessage.success('备份恢复成功')
  }, 5000)
}

const deleteBackup = (backup) => {
  ElMessageBox.confirm(
    `确定要删除备份文件 "${backup.name}" 吗？此操作不可恢复。`,
    '确认删除',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    }
  ).then(() => {
    ElMessage.success('备份文件删除成功')
    refreshBackups()
  })
}

const refreshBackups = () => {
  loading.value = true
  setTimeout(() => {
    loading.value = false
    ElMessage.success('备份列表已刷新')
  }, 1000)
}

const handleSizeChange = (size) => {
  pagination.pageSize = size
}

const handleCurrentChange = (page) => {
  pagination.currentPage = page
}

onMounted(() => {
  refreshBackups()
})
</script>

<style scoped>
.system-backup-container {
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

.config-card,
.status-card,
.table-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.unit {
  margin-left: 10px;
  color: #909399;
  font-size: 14px;
}

.status-content {
  padding: 10px 0;
}

.status-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 0;
  border-bottom: 1px solid #f0f0f0;
}

.status-item:last-child {
  border-bottom: none;
}

.status-label {
  color: #909399;
  font-size: 14px;
}

.status-value {
  font-weight: 500;
  color: #303133;
}

.backup-name {
  display: flex;
  align-items: center;
  gap: 8px;
}

.pagination-container {
  display: flex;
  justify-content: center;
  margin-top: 20px;
}

.restore-warning {
  margin-bottom: 20px;
}

.restore-info {
  margin-top: 20px;
}

.restore-info h4 {
  margin-bottom: 10px;
  color: #303133;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}
</style>