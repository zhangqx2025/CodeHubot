<template>
  <div class="channel-course-detail">
    <el-page-header @back="goBack" class="page-header">
      <template #content>
        <span class="page-title">{{ courseInfo.course_name }}</span>
      </template>
    </el-page-header>

    <el-row :gutter="20" v-loading="loading">
      <!-- 课程基本信息 -->
      <el-col :span="24">
        <el-card class="info-card" shadow="never">
          <template #header>
            <span class="card-title">课程信息</span>
          </template>
          
          <el-descriptions :column="2" border>
            <el-descriptions-item label="课程名称">
              {{ courseInfo.course_name }}
            </el-descriptions-item>
            <el-descriptions-item label="所属班级">
              <el-tag>{{ courseInfo.class_name }}</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="授课教师">
              {{ courseInfo.teacher_name }}
            </el-descriptions-item>
            <el-descriptions-item label="学生数量">
              <el-tag type="success">{{ courseInfo.student_count || 0 }}人</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="开始时间">
              {{ formatDate(courseInfo.start_date) }}
            </el-descriptions-item>
            <el-descriptions-item label="结束时间">
              {{ formatDate(courseInfo.end_date) }}
            </el-descriptions-item>
            <el-descriptions-item label="课程状态">
              <el-tag :type="getStatusType(courseInfo.status)">
                {{ getStatusText(courseInfo.status) }}
              </el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="所属学校">
              {{ courseInfo.school_name }}
            </el-descriptions-item>
          </el-descriptions>
        </el-card>
      </el-col>

      <!-- 课程进度 -->
      <el-col :span="24" style="margin-top: 20px">
        <el-card class="progress-card" shadow="never">
          <template #header>
            <span class="card-title">学习进度统计</span>
          </template>
          
          <div v-if="progressData" class="progress-content">
            <el-row :gutter="20">
              <el-col :span="6">
                <el-statistic
                  title="总单元数"
                  :value="progressData.total_units || 0"
                  suffix="个"
                />
              </el-col>
              <el-col :span="6">
                <el-statistic
                  title="已完成单元"
                  :value="progressData.completed_units || 0"
                  suffix="个"
                />
              </el-col>
              <el-col :span="6">
                <el-statistic
                  title="平均完成度"
                  :value="progressData.avg_progress || 0"
                  suffix="%"
                  :precision="1"
                />
              </el-col>
              <el-col :span="6">
                <el-statistic
                  title="活跃学生数"
                  :value="progressData.active_students || 0"
                  suffix="人"
                />
              </el-col>
            </el-row>
          </div>
        </el-card>
      </el-col>

      <!-- 作业列表 -->
      <el-col :span="24" style="margin-top: 20px">
        <el-card class="assignment-card" shadow="never">
          <template #header>
            <span class="card-title">课程作业</span>
          </template>
          
          <el-table :data="assignments" style="width: 100%">
            <el-table-column prop="unit_name" label="所属单元" width="150" />
            <el-table-column prop="output_name" label="作业名称" min-width="200" />
            <el-table-column prop="submission_count" label="提交数" width="100" align="center">
              <template #default="{ row }">
                <el-tag>{{ row.submission_count || 0 }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="graded_count" label="已批改" width="100" align="center">
              <template #default="{ row }">
                <el-tag type="success">{{ row.graded_count || 0 }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="due_date" label="截止时间" width="120">
              <template #default="{ row }">
                {{ formatDate(row.due_date) }}
              </template>
            </el-table-column>
          </el-table>

          <div v-if="assignments.length === 0" class="empty-state">
            <el-empty description="暂无作业数据" />
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { getCourseDetail, getCourseProgress, getCourseAssignments } from '../api'

const router = useRouter()
const route = useRoute()

const loading = ref(false)
const courseInfo = ref({})
const progressData = ref(null)
const assignments = ref([])

function goBack() {
  router.back()
}

async function fetchData() {
  loading.value = true
  try {
    const courseUuid = route.params.courseUuid
    
    // 获取课程详情
    const courseResponse = await getCourseDetail(courseUuid)
    courseInfo.value = courseResponse.data || {}
    
    // 获取课程进度
    const progressResponse = await getCourseProgress(courseUuid)
    progressData.value = progressResponse.data || null
    
    // 获取作业列表
    const assignmentsResponse = await getCourseAssignments(courseUuid)
    assignments.value = assignmentsResponse.data || []
    
  } catch (error) {
    console.error('获取课程数据失败:', error)
    ElMessage.error(error.message || '获取课程数据失败')
  } finally {
    loading.value = false
  }
}

function formatDate(dateStr) {
  if (!dateStr) return '-'
  return dateStr.split('T')[0]
}

function getStatusType(status) {
  const typeMap = {
    'not_started': 'info',
    'in_progress': 'success',
    'completed': 'warning',
    'archived': 'info'
  }
  return typeMap[status] || 'info'
}

function getStatusText(status) {
  const textMap = {
    'not_started': '未开始',
    'in_progress': '进行中',
    'completed': '已完成',
    'archived': '已归档'
  }
  return textMap[status] || status
}

onMounted(() => {
  fetchData()
})
</script>

<style scoped lang="scss">
.channel-course-detail {
  .page-header {
    margin-bottom: 20px;
    background: white;
    padding: 16px 20px;
    border-radius: 4px;
    
    .page-title {
      font-size: 18px;
      font-weight: 600;
      color: #2c3e50;
    }
  }
  
  .card-title {
    font-size: 16px;
    font-weight: 600;
    color: #2c3e50;
  }
  
  .info-card {
    :deep(.el-descriptions__label) {
      font-weight: 500;
      color: #606266;
    }
  }
  
  .progress-content {
    padding: 20px 0;
  }
  
  .empty-state {
    padding: 40px 0;
  }
}
</style>
