<template>
  <div class="teacher-courses">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>课程管理</span>
          <el-button type="primary" @click="handleCreate">创建课程</el-button>
        </div>
      </template>
      <div class="courses-content">
        <el-empty description="暂无课程数据"></el-empty>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'

// 页面数据
const loading = ref(false)
const courses = ref([])

// 创建课程
const handleCreate = () => {
  ElMessage.info('创建课程功能开发中...')
}

onMounted(() => {
  // 加载课程列表
})
</script>

<style scoped>
.teacher-courses {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.courses-content {
  min-height: 400px;
  display: flex;
  align-items: center;
  justify-content: center;
}
</style>
