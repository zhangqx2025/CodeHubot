<template>
  <div class="teacher-tasks">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>任务管理</span>
          <el-button type="primary" @click="handleCreate">创建任务</el-button>
        </div>
      </template>
      <div class="tasks-content">
        <el-empty description="暂无任务数据"></el-empty>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'

// 页面数据
const loading = ref(false)
const tasks = ref([])

// 创建任务
const handleCreate = () => {
  ElMessage.info('创建任务功能开发中...')
}

onMounted(() => {
  // 加载任务列表
})
</script>

<style scoped>
.teacher-tasks {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.tasks-content {
  min-height: 400px;
  display: flex;
  align-items: center;
  justify-content: center;
}
</style>
