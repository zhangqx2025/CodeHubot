<template>
  <div class="plugin-editor">
    <el-page-header @back="goBack" :content="pageTitle">
      <template #extra>
        <el-button type="primary" @click="savePlugin" :loading="saving">
          <el-icon><Document /></el-icon>
          保存
        </el-button>
      </template>
    </el-page-header>

    <div class="editor-content" v-loading="loading">
      <!-- 基本信息卡片 -->
      <el-card class="section-card">
        <template #header>
          <div class="card-header">
            <span class="card-title">基本信息</span>
          </div>
        </template>
        <el-form :model="pluginForm" :rules="rules" ref="formRef" label-width="120px">
          <el-form-item label="插件名称" prop="name">
            <el-input v-model="pluginForm.name" placeholder="请输入插件名称" style="max-width: 500px;" />
          </el-form-item>
          <el-form-item label="描述" prop="description">
            <el-input
              v-model="pluginForm.description"
              type="textarea"
              :rows="3"
              placeholder="请输入插件描述"
              style="max-width: 800px;"
            />
          </el-form-item>
          <el-form-item label="状态" prop="is_active">
            <el-radio-group v-model="pluginForm.is_active">
              <el-radio :label="1">激活</el-radio>
              <el-radio :label="0">禁用</el-radio>
            </el-radio-group>
          </el-form-item>
        </el-form>
      </el-card>

      <!-- OpenAPI规范配置卡片 -->
      <el-card class="section-card">
        <template #header>
          <div class="card-header">
            <span class="card-title">OpenAPI 规范配置</span>
            <el-button text @click="showTemplates">
              <el-icon><Document /></el-icon>
              使用模板
            </el-button>
          </div>
        </template>
        <div class="openapi-editor">
          <div style="border: 1px solid #dcdfe6; border-radius: 4px;">
            <el-input
              v-model="jsonString"
              type="textarea"
              :rows="25"
              placeholder="请输入 OpenAPI 3.0.0 规范的 JSON"
              @blur="validateJson"
              class="json-textarea"
            />
          </div>
          <div class="editor-tips">
            <el-alert
              title="OpenAPI 规范要求"
              type="info"
              :closable="false"
              show-icon
            >
              <ul>
                <li>必须符合 OpenAPI 3.0.0 格式</li>
                <li>必须包含 openapi、info、paths 字段</li>
                <li>info 中必须包含 title 字段</li>
                <li>支持标准的 OpenAI 插件格式</li>
              </ul>
            </el-alert>
            <div v-if="jsonError" class="form-error">
              <el-alert :title="jsonError" type="error" :closable="false" show-icon />
            </div>
          </div>
        </div>
      </el-card>
    </div>

    <!-- 模板选择对话框 -->
    <el-dialog
      v-model="templateDialogVisible"
      title="选择模板"
      width="700px"
    >
      <div class="templates-grid">
        <el-card
          v-for="template in templates"
          :key="template.id"
          class="template-card"
          shadow="hover"
          @click="useTemplate(template)"
        >
          <div class="template-name">{{ template.name }}</div>
          <div class="template-desc">{{ template.description }}</div>
        </el-card>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Document } from '@element-plus/icons-vue'
import { getPlugin, updatePlugin } from '../api/plugin'

const route = useRoute()
const router = useRouter()

const loading = ref(false)
const saving = ref(false)
const formRef = ref(null)
const templateDialogVisible = ref(false)
const jsonError = ref('')

const pluginUuid = computed(() => route.params.uuid)
const pageTitle = computed(() => pluginForm.name || '插件编辑')

const pluginForm = reactive({
  id: null,
  uuid: null,
  name: '',
  description: '',
  openapi_spec: {},
  is_active: 1
})

const jsonString = computed({
  get: () => {
    try {
      return JSON.stringify(pluginForm.openapi_spec, null, 2)
    } catch {
      return ''
    }
  },
  set: (value) => {
    try {
      pluginForm.openapi_spec = JSON.parse(value)
      jsonError.value = ''
    } catch (e) {
      jsonError.value = 'JSON 格式错误：' + e.message
    }
  }
})

const rules = {
  name: [
    { required: true, message: '请输入插件名称', trigger: 'blur' },
    { min: 1, max: 100, message: '长度在 1 到 100 个字符', trigger: 'blur' }
  ]
}

// OpenAPI 模板
const templates = [
  {
    id: 1,
    name: '基础RESTful API模板',
    description: '标准的RESTful API插件模板',
    spec: {
      "openapi": "3.0.0",
      "info": {
        "title": "示例API",
        "description": "这是一个示例API插件",
        "version": "1.0.0"
      },
      "servers": [
        {
          "url": "https://api.example.com"
        }
      ],
      "paths": {
        "/example": {
          "get": {
            "summary": "获取示例数据",
            "operationId": "getExample",
            "responses": {
              "200": {
                "description": "成功",
                "content": {
                  "application/json": {
                    "schema": {
                      "type": "object",
                      "properties": {
                        "data": {
                          "type": "string"
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  },
  {
    id: 2,
    name: '设备控制API模板',
    description: '物联网设备控制API模板',
    spec: {
      "openapi": "3.0.0",
      "info": {
        "title": "设备控制API",
        "description": "用于控制物联网设备的API插件",
        "version": "1.0.0"
      },
      "servers": [
        {
          "url": "http://localhost:8000/api"
        }
      ],
      "paths": {
        "/devices/{device_uuid}/control": {
          "post": {
            "summary": "控制设备",
            "operationId": "controlDevice",
            "parameters": [
              {
                "name": "device_uuid",
                "in": "path",
                "required": true,
                "schema": {
                  "type": "string"
                },
                "description": "设备UUID"
              }
            ],
            "requestBody": {
              "required": true,
              "content": {
                "application/json": {
                  "schema": {
                    "type": "object",
                    "properties": {
                      "action": {
                        "type": "string",
                        "description": "控制动作"
                      },
                      "value": {
                        "type": "string",
                        "description": "控制值"
                      }
                    }
                  }
                }
              }
            },
            "responses": {
              "200": {
                "description": "控制成功"
              }
            }
          }
        }
      }
    }
  }
]

// 返回
const goBack = () => {
  router.push('/plugins')
}

// 加载插件详情
const loadPlugin = async () => {
  if (!pluginUuid.value) return
  
  loading.value = true
  try {
    const response = await getPlugin(pluginUuid.value)
    const plugin = response.data || response
    Object.assign(pluginForm, {
      id: plugin.id,
      uuid: plugin.uuid,
      name: plugin.name,
      description: plugin.description || '',
      openapi_spec: plugin.openapi_spec || {},
      is_active: plugin.is_active
    })
  } catch (error) {
    ElMessage.error('加载插件信息失败')
    console.error(error)
  } finally {
    loading.value = false
  }
}

// 验证JSON
const validateJson = () => {
  try {
    const spec = pluginForm.openapi_spec
    if (!spec.openapi || !spec.info || !spec.paths) {
      jsonError.value = '必须包含 openapi、info、paths 字段'
      return false
    }
    if (!spec.info.title) {
      jsonError.value = 'info 中必须包含 title 字段'
      return false
    }
    jsonError.value = ''
    return true
  } catch (e) {
    jsonError.value = 'JSON 格式错误：' + e.message
    return false
  }
}

// 保存插件
const savePlugin = async () => {
  if (!formRef.value) return
  
  try {
    await formRef.value.validate()
  } catch {
    ElMessage.warning('请检查基本信息是否填写正确')
    return
  }
  
  if (!validateJson()) {
    ElMessage.warning('请修正 OpenAPI 规范错误')
    return
  }
  
  saving.value = true
  try {
    await updatePlugin(pluginUuid.value, pluginForm)
    ElMessage.success('保存成功')
  } catch (error) {
    ElMessage.error(error.response?.data?.message || '保存失败')
    console.error(error)
  } finally {
    saving.value = false
  }
}

// 显示模板
const showTemplates = () => {
  templateDialogVisible.value = true
}

// 使用模板
const useTemplate = (template) => {
  ElMessageBox.confirm(
    '使用模板将覆盖当前的 OpenAPI 规范，是否继续？',
    '确认使用模板',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    }
  ).then(() => {
    pluginForm.openapi_spec = JSON.parse(JSON.stringify(template.spec))
    templateDialogVisible.value = false
    ElMessage.success('模板已应用')
  }).catch(() => {})
}

onMounted(() => {
  loadPlugin()
})
</script>

<style scoped>
.plugin-editor {
  padding: 20px;
}

.editor-content {
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

.openapi-editor {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.json-textarea :deep(textarea) {
  font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', 'Consolas', monospace;
  font-size: 13px;
  line-height: 1.6;
}

.editor-tips {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.editor-tips ul {
  margin: 8px 0 0 0;
  padding-left: 20px;
}

.editor-tips li {
  margin: 4px 0;
}

.form-error {
  margin-top: 8px;
}

.templates-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}

.template-card {
  cursor: pointer;
  transition: all 0.3s;
}

.template-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.template-name {
  font-size: 16px;
  font-weight: 600;
  color: #303133;
  margin-bottom: 8px;
}

.template-desc {
  font-size: 14px;
  color: #606266;
}
</style>

