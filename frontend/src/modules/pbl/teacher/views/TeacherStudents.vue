<template>
  <div class="teacher-students">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>学生管理</span>
        </div>
      </template>
      <div class="students-content">
        <el-empty description="暂无学生数据"></el-empty>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

// 页面数据
const loading = ref(false)
const students = ref([])

onMounted(() => {
  // 加载学生列表
})
</script>

<style scoped>
.teacher-students {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.students-content {
  min-height: 400px;
  display: flex;
  align-items: center;
  justify-content: center;
}
</style>
