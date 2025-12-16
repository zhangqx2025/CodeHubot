<template>
  <div class="channel-statistics">
    <el-card shadow="never">
      <template #header>
        <h2 class="page-title">渠道业务统计</h2>
      </template>

      <el-row :gutter="20" v-loading="loading">
        <el-col :span="6">
          <el-card class="stat-card">
            <el-statistic title="渠道商总数" :value="statistics.total_partners" />
          </el-card>
        </el-col>
        <el-col :span="6">
          <el-card class="stat-card">
            <el-statistic title="活跃渠道商" :value="statistics.active_partners" />
          </el-card>
        </el-col>
        <el-col :span="6">
          <el-card class="stat-card">
            <el-statistic title="学校关联数" :value="statistics.total_relations" />
          </el-card>
        </el-col>
        <el-col :span="6">
          <el-card class="stat-card">
            <el-statistic title="有渠道商的学校" :value="statistics.schools_with_partner" />
          </el-card>
        </el-col>
      </el-row>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { getChannelStatistics } from '../api'

const loading = ref(false)
const statistics = ref({
  total_partners: 0,
  active_partners: 0,
  total_relations: 0,
  schools_with_partner: 0
})

async function fetchStatistics() {
  loading.value = true
  try {
    const response = await getChannelStatistics()
    statistics.value = response.data || statistics.value
  } catch (error) {
    ElMessage.error('获取统计数据失败')
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  fetchStatistics()
})
</script>

<style scoped lang="scss">
.channel-statistics {
  .page-title {
    font-size: 20px;
    font-weight: 600;
    color: #2c3e50;
    margin: 0;
  }

  .stat-card {
    text-align: center;
  }
}
</style>
