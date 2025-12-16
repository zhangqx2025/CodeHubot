<template>
  <div class="plugin-viewer">
    <el-page-header @back="goBack" :content="pageTitle">
      <template #extra>
        <el-button type="primary" @click="editPlugin">
          <el-icon><Edit /></el-icon>
          编辑
        </el-button>
      </template>
    </el-page-header>

    <div class="viewer-content" v-loading="loading">
      <!-- 基本信息卡片 -->
      <el-card class="section-card">
        <template #header>
          <div class="card-header">
            <span class="card-title">基本信息</span>
          </div>
        </template>
        <el-descriptions :column="2" border>
          <el-descriptions-item label="插件名称">{{ plugin.name }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag :type="plugin.is_active === 1 ? 'success' : 'info'">
              {{ plugin.is_active === 1 ? '激活' : '禁用' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="类型">
            <el-tag :type="plugin.is_system === 1 ? 'warning' : 'info'">
              {{ plugin.is_system === 1 ? '系统内置' : '用户创建' }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ formatDate(plugin.created_at) }}</el-descriptions-item>
          <el-descriptions-item label="更新时间">{{ formatDate(plugin.updated_at) }}</el-descriptions-item>
          <el-descriptions-item label="描述" :span="2">
            {{ plugin.description || '暂无描述' }}
          </el-descriptions-item>
        </el-descriptions>
      </el-card>

      <!-- OpenAPI规范信息 -->
      <el-card class="section-card">
        <template #header>
          <div class="card-header">
            <span class="card-title">OpenAPI 规范</span>
            <el-button text @click="copySpec">
              <el-icon><DocumentCopy /></el-icon>
              复制规范
            </el-button>
          </div>
        </template>
        
        <el-descriptions :column="2" border v-if="plugin.openapi_spec">
          <el-descriptions-item label="OpenAPI版本">
            {{ plugin.openapi_spec.openapi }}
          </el-descriptions-item>
          <el-descriptions-item label="API标题">
            {{ plugin.openapi_spec.info?.title }}
          </el-descriptions-item>
          <el-descriptions-item label="API版本">
            {{ plugin.openapi_spec.info?.version }}
          </el-descriptions-item>
          <el-descriptions-item label="API数量">
            {{ Object.keys(plugin.openapi_spec.paths || {}).length }}
          </el-descriptions-item>
          <el-descriptions-item label="服务器地址" :span="2">
            {{ plugin.openapi_spec.servers?.[0]?.url || '未配置' }}
          </el-descriptions-item>
          <el-descriptions-item label="描述" :span="2">
            {{ plugin.openapi_spec.info?.description || '暂无描述' }}
          </el-descriptions-item>
        </el-descriptions>

        <div class="spec-content">
          <div class="spec-header">
            <h4>完整规范</h4>
            <el-button size="small" @click="toggleSpecView">
              {{ showFullSpec ? '收起' : '展开' }}
            </el-button>
          </div>
          <div v-show="showFullSpec" class="spec-json">
            <pre><code>{{ formatJson(plugin.openapi_spec) }}</code></pre>
          </div>
        </div>
      </el-card>

      <!-- API端点列表 -->
      <el-card class="section-card" v-if="apiPaths.length > 0">
        <template #header>
          <div class="card-header">
            <span class="card-title">API 端点 ({{ apiPaths.length }})</span>
          </div>
        </template>
        
        <el-table :data="apiPaths" stripe>
          <el-table-column label="方法" width="100">
            <template #default="scope">
              <el-tag :type="getMethodType(scope.row.method)">
                {{ scope.row.method.toUpperCase() }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="path" label="路径" min-width="200" />
          <el-table-column prop="summary" label="描述" min-width="200" show-overflow-tooltip />
          <el-table-column prop="operationId" label="操作ID" width="150" />
        </el-table>
      </el-card>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Edit, DocumentCopy } from '@element-plus/icons-vue'
import { getPlugin } from '../api/plugin'
import { useClipboard } from '@vueuse/core'

const route = useRoute()
const router = useRouter()

const loading = ref(false)
const showFullSpec = ref(false)
const plugin = ref({
  name: '',
  description: '',
  openapi_spec: {},
  is_active: 0,
  is_system: 0,
  created_at: '',
  updated_at: ''
})

const pluginUuid = computed(() => route.params.uuid)
const pageTitle = computed(() => plugin.value.name || '插件详情')

// 解析API路径
const apiPaths = computed(() => {
  const paths = plugin.value.openapi_spec?.paths || {}
  const result = []
  
  for (const [path, methods] of Object.entries(paths)) {
    for (const [method, details] of Object.entries(methods)) {
      if (typeof details === 'object') {
        result.push({
          path,
          method,
          summary: details.summary || details.description || '',
          operationId: details.operationId || ''
        })
      }
    }
  }
  
  return result
})

// 获取HTTP方法的标签类型
const getMethodType = (method) => {
  const types = {
    'get': 'success',
    'post': 'primary',
    'put': 'warning',
    'delete': 'danger',
    'patch': 'info'
  }
  return types[method.toLowerCase()] || ''
}

// 返回
const goBack = () => {
  router.push('/plugins')
}

// 编辑
const editPlugin = () => {
  router.push(`/plugins/${pluginUuid.value}/edit`)
}

// 加载插件详情
const loadPlugin = async () => {
  if (!pluginUuid.value) return
  
  loading.value = true
  try {
    const response = await getPlugin(pluginUuid.value)
    plugin.value = response.data || response
  } catch (error) {
    ElMessage.error('加载插件信息失败')
    console.error(error)
  } finally {
    loading.value = false
  }
}

// 格式化JSON
const formatJson = (obj) => {
  try {
    return JSON.stringify(obj, null, 2)
  } catch {
    return ''
  }
}

// 格式化日期
const formatDate = (date) => {
  if (!date) return ''
  return new Date(date).toLocaleString('zh-CN')
}

// 切换规范视图
const toggleSpecView = () => {
  showFullSpec.value = !showFullSpec.value
}

// 复制规范
const { copy } = useClipboard()
const copySpec = () => {
  try {
    const text = formatJson(plugin.value.openapi_spec)
    copy(text)
    ElMessage.success('已复制到剪贴板')
  } catch (error) {
    ElMessage.error('复制失败')
  }
}

onMounted(() => {
  loadPlugin()
})
</script>

<style scoped>
.plugin-viewer {
  padding: 20px;
}

.viewer-content {
  margin-top: 20px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.section-card {
  transition: box-shadow 0.3s;
}

.section-card:hover {
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.card-title {
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}

.spec-content {
  margin-top: 20px;
}

.spec-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
  padding-bottom: 8px;
  border-bottom: 1px solid #e4e7ed;
}

.spec-header h4 {
  margin: 0;
  font-size: 14px;
  font-weight: 600;
  color: #606266;
}

.spec-json {
  background: #f5f7fa;
  border: 1px solid #e4e7ed;
  border-radius: 4px;
  padding: 16px;
  max-height: 600px;
  overflow: auto;
}

.spec-json pre {
  margin: 0;
}

.spec-json code {
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', 'Consolas', monospace;
  font-size: 13px;
  line-height: 1.6;
  color: #303133;
}
</style>

