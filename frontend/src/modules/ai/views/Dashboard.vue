<template>
  <div class="ai-dashboard">
    <el-row :gutter="20">
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-content">
            <div class="stat-icon agent">
              <el-icon :size="32"><Avatar /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stats.agents }}</div>
              <div class="stat-label">智能体</div>
            </div>
          </div>
        </el-card>
      </el-col>
      
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-content">
            <div class="stat-icon workflow">
              <el-icon :size="32"><Connection /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stats.workflows }}</div>
              <div class="stat-label">工作流</div>
            </div>
          </div>
        </el-card>
      </el-col>
      
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-content">
            <div class="stat-icon knowledge">
              <el-icon :size="32"><Collection /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stats.knowledgeBases }}</div>
              <div class="stat-label">知识库</div>
            </div>
          </div>
        </el-card>
      </el-col>
      
      <el-col :span="6">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-content">
            <div class="stat-icon plugin">
              <el-icon :size="32"><Grid /></el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stats.plugins }}</div>
              <div class="stat-label">插件</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
    
    <el-row :gutter="20" style="margin-top: 20px;">
      <el-col :span="12">
        <el-card shadow="hover">
          <template #header>
            <span>快速访问</span>
          </template>
          <div class="quick-actions">
            <el-button type="primary" @click="$router.push('/ai/chat')">
              <el-icon><ChatDotRound /></el-icon> 开始对话
            </el-button>
            <el-button @click="$router.push('/ai/agents/create')">
              <el-icon><Plus /></el-icon> 创建智能体
            </el-button>
            <el-button @click="$router.push('/ai/workflows/create')">
              <el-icon><Plus /></el-icon> 创建工作流
            </el-button>
            <el-button @click="$router.push('/ai/knowledge-bases')">
              <el-icon><Collection /></el-icon> 管理知识库
            </el-button>
          </div>
        </el-card>
      </el-col>
      
      <el-col :span="12">
        <el-card shadow="hover">
          <template #header>
            <span>系统状态</span>
          </template>
          <div class="system-status">
            <el-row :gutter="10">
              <el-col :span="12">
                <div class="status-item">
                  <el-tag type="success">LLM服务</el-tag>
                  <span class="status-value">正常</span>
                </div>
              </el-col>
              <el-col :span="12">
                <div class="status-item">
                  <el-tag type="success">向量数据库</el-tag>
                  <span class="status-value">正常</span>
                </div>
              </el-col>
              <el-col :span="12">
                <div class="status-item">
                  <el-tag type="info">队列服务</el-tag>
                  <span class="status-value">运行中</span>
                </div>
              </el-col>
              <el-col :span="12">
                <div class="status-item">
                  <el-tag type="warning">API调用</el-tag>
                  <span class="status-value">{{ stats.apiCalls }} 次/小时</span>
                </div>
              </el-col>
            </el-row>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { Avatar, Connection, Collection, Grid, ChatDotRound, Plus } from '@element-plus/icons-vue'

const stats = ref({
  agents: 0,
  workflows: 0,
  knowledgeBases: 0,
  plugins: 0,
  apiCalls: 0
})

onMounted(() => {
  loadStats()
})

async function loadStats() {
  // TODO: 从API加载统计数据
  stats.value = {
    agents: 12,
    workflows: 8,
    knowledgeBases: 5,
    plugins: 15,
    apiCalls: 1248
  }
}
</script>

<style scoped lang="scss">
.ai-dashboard {
  .stat-card {
    .stat-content {
      display: flex;
      align-items: center;
      gap: 20px;
      
      .stat-icon {
        width: 60px;
        height: 60px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        
        &.agent {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        
        &.workflow {
          background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
        }
        
        &.knowledge {
          background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        }
        
        &.plugin {
          background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
        }
      }
      
      .stat-info {
        flex: 1;
        
        .stat-value {
          font-size: 32px;
          font-weight: bold;
          color: #2c3e50;
          line-height: 1;
        }
        
        .stat-label {
          font-size: 14px;
          color: #909399;
          margin-top: 8px;
        }
      }
    }
  }
  
  .quick-actions {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
  }
  
  .system-status {
    .status-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 10px 0;
      
      .status-value {
        font-weight: 500;
        color: #2c3e50;
      }
    }
  }
}
</style>
