<template>
  <div class="class-detail-container">
    <!-- 返回按钮 -->
    <div class="page-header">
      <el-button @click="goBack" text>
        <el-icon><ArrowLeft /></el-icon>
        返回班级列表
      </el-button>
    </div>

    <!-- 加载中 -->
    <div v-if="loading" class="loading-container">
      <el-skeleton :rows="8" animated />
    </div>

    <!-- 数据为空提示 -->
    <div v-else-if="!loading && !classInfo" class="empty-container">
      <el-empty description="班级不存在或已被删除">
        <el-button type="primary" @click="goBack">返回列表</el-button>
      </el-empty>
    </div>

    <!-- 班级详情 -->
    <div v-else-if="classInfo?.name" class="detail-content">
      <!-- 班级头部卡片 -->
      <el-card class="header-card" shadow="never">
        <div class="header-content" :class="`type-${classInfo?.class_type}`">
          <div class="header-left">
            <el-tag :type="getClassTypeTagType(classInfo?.class_type)" size="large" effect="dark">
              {{ getClassTypeName(classInfo?.class_type) }}
            </el-tag>
            <h1 class="class-name">{{ classInfo?.name }}</h1>
            <p class="class-description">{{ classInfo?.description || '暂无描述' }}</p>
          </div>
          <div class="header-right">
            <el-button type="primary" size="large" @click="editClass">
              <el-icon><Edit /></el-icon>
              编辑信息
            </el-button>
          </div>
        </div>
      </el-card>

      <!-- 统计卡片 -->
      <div class="stats-grid">
        <el-card shadow="hover" class="stat-card">
          <el-statistic title="成员人数" :value="classInfo?.current_members || 0" />
        </el-card>

        <el-card shadow="hover" class="stat-card">
          <el-statistic title="小组数量" :value="groupCount" />
          <el-button type="primary" link style="margin-top: 16px" @click="viewGroups">
            查看小组 <el-icon><ArrowRight /></el-icon>
          </el-button>
        </el-card>

        <el-card shadow="hover" class="stat-card">
          <div class="stat-status">
            <span class="stat-label">创建时间</span>
            <div class="stat-time">
              <el-icon><Clock /></el-icon>
              {{ formatDate(classInfo?.created_at) }}
            </div>
          </div>
        </el-card>
      </div>

      <!-- 快捷操作 -->
      <el-card shadow="never" class="actions-card">
        <template #header>
          <div class="card-header">
            <span>快捷操作</span>
          </div>
        </template>
        <div class="actions-container">
          <!-- 第一行 -->
          <div class="actions-grid">
            <el-button size="large" @click="viewMembers">
              <el-icon><UserFilled /></el-icon>
              成员管理
            </el-button>
            <el-button size="large" @click="viewGroups">
              <el-icon><Grid /></el-icon>
              分组管理
            </el-button>
            <el-button size="large" @click="viewTeachers">
              <el-icon><User /></el-icon>
              教师管理
            </el-button>
          </div>
          <!-- 第二行 -->
          <div class="actions-grid">
            <el-button size="large" @click="viewCourses">
              <el-icon><Reading /></el-icon>
              课程管理
            </el-button>
            <el-button size="large" @click="viewProgress">
              <el-icon><TrendCharts /></el-icon>
              学习进度
            </el-button>
            <el-button size="large" @click="viewHomework">
              <el-icon><Document /></el-icon>
              作业管理
            </el-button>
          </div>
        </div>
      </el-card>

      <!-- 基本信息 -->
      <el-card shadow="never" class="info-card">
        <template #header>
          <div class="card-header">
            <span>基本信息</span>
          </div>
        </template>
        <el-descriptions :column="2" border>
          <el-descriptions-item label="班级名称">{{ classInfo?.name }}</el-descriptions-item>
          <el-descriptions-item label="班级类型">
            <el-tag :type="getClassTypeTagType(classInfo?.class_type)">
              {{ getClassTypeName(classInfo?.class_type) }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="当前人数">{{ classInfo?.current_members }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ formatDateTime(classInfo?.created_at) }}</el-descriptions-item>
          <el-descriptions-item label="更新时间">{{ formatDateTime(classInfo?.updated_at) }}</el-descriptions-item>
          <el-descriptions-item label="班级描述" :span="2">
            {{ classInfo?.description || '暂无描述' }}
          </el-descriptions-item>
        </el-descriptions>
      </el-card>
    </div>

    <!-- 错误提示 -->
    <el-empty v-else description="加载失败" />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import {
  ArrowLeft, ArrowRight, Edit, UserFilled, Reading, Grid, Clock, User, TrendCharts, Document
} from '@element-plus/icons-vue'
import { getClubClassDetail, getGroups } from '@/api/club'
import dayjs from 'dayjs'

const route = useRoute()
const router = useRouter()

const loading = ref(true)
const classInfo = ref(null)
const groupCount = ref(0)

// 加载班级详情
const loadClassDetail = async () => {
  loading.value = true
  try {
    const uuid = route.params.uuid
    const res = await getClubClassDetail(uuid)
    
    // 检查数据是否有效
    if (res && res.data) {
      classInfo.value = res.data
      console.log('班级详情数据:', classInfo.value)
      
      // 加载小组数量
      if (classInfo.value?.id) {
        const groupRes = await getGroups({ class_id: classInfo.value.id })
        groupCount.value = groupRes.data?.length || 0
      }
    } else {
      ElMessage.error('班级数据格式错误')
    }
  } catch (error) {
    console.error('加载班级详情失败:', error)
    ElMessage.error(error.message || '加载班级详情失败')
    // 确保即使出错也设置为 null 而不是 undefined
    classInfo.value = null
  } finally {
    loading.value = false
  }
}

// 工具方法
const getClassTypeName = (type) => {
  const map = {
    club: '社团班',
    project: '项目班',
    interest: '兴趣班',
    competition: '竞赛班',
    regular: '普通班'
  }
  return map[type] || type
}

const getClassTypeTagType = (type) => {
  const map = {
    club: 'primary',
    project: 'success',
    interest: 'warning',
    competition: 'danger',
    regular: 'info'
  }
  return map[type] || 'info'
}

const formatDate = (dateStr) => {
  if (!dateStr) return '-'
  return dayjs(dateStr).format('YYYY-MM-DD')
}

const formatDateTime = (dateStr) => {
  if (!dateStr) return '-'
  return dayjs(dateStr).format('YYYY-MM-DD HH:mm:ss')
}

// 操作方法
const goBack = () => {
  router.push('/pbl/school/classes')
}

const editClass = () => {
  router.push(`/pbl/school/classes/${route.params.uuid}/edit`)
}

const viewMembers = () => {
  router.push(`/pbl/school/classes/${route.params.uuid}/members`)
}

const viewCourses = () => {
  // 跳转到班级课程管理页面
  router.push(`/pbl/school/classes/${route.params.uuid}/courses`)
}

const viewGroups = () => {
  router.push(`/pbl/school/classes/${route.params.uuid}/groups`)
}

const viewTeachers = () => {
  router.push(`/pbl/school/classes/${route.params.uuid}/teachers`)
}

const viewProgress = () => {
  router.push(`/pbl/school/classes/${route.params.uuid}/progress`)
}

const viewHomework = () => {
  router.push(`/pbl/school/classes/${route.params.uuid}/homework`)
}

onMounted(() => {
  loadClassDetail()
})
</script>

<style scoped lang="scss">
.class-detail-container {
  padding: 24px;
  background: #f5f7fa;
  min-height: calc(100vh - 60px);
}

.page-header {
  margin-bottom: 24px;
}

.loading-container {
  background: white;
  padding: 24px;
  border-radius: 12px;
}

.detail-content {
  .header-card {
    margin-bottom: 24px;
    border-radius: 12px;
    border: none;
    
    :deep(.el-card__body) {
      padding: 0;
    }
  }
  
  .header-content {
    padding: 32px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border-radius: 12px;
    color: white;
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    
    &.type-club {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    }
    
    &.type-project {
      background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
    }
    
    &.type-interest {
      background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
    }
    
    &.type-competition {
      background: linear-gradient(135deg, #fa709a 0%, #fee140 100%);
    }
    
    .header-left {
      flex: 1;
      
      .el-tag {
        margin-bottom: 16px;
      }
      
      .class-name {
        margin: 0 0 16px 0;
        font-size: 32px;
        font-weight: 600;
      }
      
      .class-description {
        margin: 0;
        font-size: 16px;
        opacity: 0.9;
        line-height: 1.6;
      }
    }
  }
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 24px;
  margin-bottom: 24px;
  
  .stat-card {
    border-radius: 12px;
    
    :deep(.el-statistic) {
      .el-statistic__head {
        font-size: 14px;
        color: #909399;
        margin-bottom: 8px;
      }
      
      .el-statistic__content {
        font-size: 32px;
        font-weight: 600;
        color: #303133;
      }
    }
    
    .stat-status {
      display: flex;
      flex-direction: column;
      gap: 12px;
      
      .stat-label {
        font-size: 14px;
        color: #909399;
      }
    }
    
    .stat-time {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-top: 16px;
      padding-top: 16px;
      border-top: 1px solid #f0f0f0;
      font-size: 14px;
      color: #606266;
    }
  }
}

.actions-card {
  margin-bottom: 24px;
  border-radius: 12px;
  
  .card-header {
    font-size: 16px;
    font-weight: 600;
  }
  
  .actions-container {
    display: flex;
    flex-direction: column;
    gap: 16px;
  }
  
  .actions-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
    
    .el-button {
      height: 56px;
      font-size: 16px;
      
      .el-icon {
        font-size: 20px;
      }
    }
  }
}

.info-card {
  border-radius: 12px;
  
  .card-header {
    font-size: 16px;
    font-weight: 600;
  }
}
</style>
