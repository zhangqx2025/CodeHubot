<template>
  <div class="teacher-dashboard">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>教学仪表盘</span>
        </div>
      </template>
      <div class="dashboard-content">
        <el-empty description="教学仪表盘功能开发中..."></el-empty>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

// 页面数据
const loading = ref(false)

onMounted(() => {
  // 加载数据
})
</script>

<style scoped>
.teacher-dashboard {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.dashboard-content {
  min-height: 400px;
  display: flex;
  align-items: center;
  justify-content: center;
}
</style>
