<template>
  <div class="student-portfolio-container">
    <!-- 个人信息卡片 -->
    <el-card class="profile-card">
      <div class="profile-header">
        <el-avatar :size="80" :src="studentInfo.avatar">
          {{ studentInfo.name?.charAt(0) }}
        </el-avatar>
        <div class="profile-info">
          <h3>{{ studentInfo.name }}</h3>
          <p class="school-info">{{ studentInfo.school }} - {{ studentInfo.class }}</p>
          <div class="profile-stats">
            <div class="stat-item">
              <span class="stat-value">{{ statistics.totalCourses }}</span>
              <span class="stat-label">参与课程</span>
            </div>
            <div class="stat-item">
              <span class="stat-value">{{ statistics.totalOutputs }}</span>
              <span class="stat-label">提交作业任务</span>
            </div>
          </div>
        </div>
      </div>
    </el-card>

    <!-- 标签页内容 -->
    <el-card class="content-card">
      <el-tabs v-model="activeTab">
        <!-- 我的课程 -->
        <el-tab-pane label="我的课程" name="courses">
          <div v-if="courses.length > 0" class="courses-grid">
            <el-card
              v-for="course in courses"
              :key="course.id"
              class="course-card"
              shadow="hover"
              @click="handleCourseClick(course)"
            >
              <div class="course-cover">
                <img v-if="course.cover_image" :src="course.cover_image" alt="课程封面" />
                <div v-else class="placeholder-cover">
                  <el-icon :size="50"><Reading /></el-icon>
                </div>
              </div>
              <div class="course-info">
                <h4>{{ course.name }}</h4>
                <p class="course-desc">{{ course.description || '暂无描述' }}</p>
                <div class="course-meta">
                  <el-tag :type="course.status === 'published' ? 'success' : 'info'" size="small">
                    {{ getCourseStatusText(course.status) }}
                  </el-tag>
                </div>
              </div>
            </el-card>
          </div>
          
          <el-empty
            v-else
            description="还没有加入任何课程"
          >
            <el-button type="primary" @click="handleGoToCourses">浏览课程</el-button>
          </el-empty>
        </el-tab-pane>

        <!-- 我的作业任务 -->
        <el-tab-pane label="我的作业任务" name="works">
          <div v-if="portfolioWorks.length > 0" class="works-grid">
            <el-card
              v-for="work in portfolioWorks"
              :key="work.id"
              class="work-card"
              shadow="hover"
            >
              <div class="work-cover">
                <img v-if="work.thumbnail" :src="work.thumbnail" alt="作业任务封面" />
                <div v-else class="placeholder-cover">
                  <el-icon :size="50"><Document /></el-icon>
                </div>
              </div>
              <div class="work-info">
                <h4>{{ work.title }}</h4>
                <p class="work-desc">{{ work.description || '暂无描述' }}</p>
                <div class="work-meta">
                  <el-tag size="small">{{ work.course_name }}</el-tag>
                  <span class="work-date">{{ formatDate(work.created_at) }}</span>
                </div>
              </div>
            </el-card>
          </div>
          
          <el-empty
            v-else
            description="还没有提交作业任务"
          >
            <el-button type="primary" @click="handleGoToTasks">查看任务</el-button>
          </el-empty>
        </el-tab-pane>
      </el-tabs>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Document, Reading } from '@element-plus/icons-vue'
import { getMyCourses } from '@pbl/student/api/student'
import request from '@/utils/request'

const router = useRouter()
const activeTab = ref('courses')

const studentInfo = reactive({
  name: '学生用户',
  avatar: '',
  school: '示例学校',
  class: '示例班级'
})

const statistics = reactive({
  totalCourses: 0,
  totalOutputs: 0
})

const courses = ref([])
const portfolioWorks = ref([])

const getCourseStatusText = (status) => {
  const statusMap = {
    draft: '草稿',
    published: '进行中',
    archived: '已归档'
  }
  return statusMap[status] || status
}

const formatDate = (date) => {
  if (!date) return ''
  const d = new Date(date)
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

const handleCourseClick = (course) => {
  router.push(`/pbl/student/courses/${course.uuid}`)
}

const handleGoToCourses = () => {
  router.push('/pbl/student/courses')
}

const handleGoToTasks = () => {
  router.push('/pbl/student/tasks')
}

const loadStudentInfo = async () => {
  try {
    // 从后端API获取当前用户完整信息
    const response = await request.get('/pbl/student/auth/me')
    const user = response.data
    
    if (user) {
      // 优先显示真实姓名(real_name)，其次是昵称(nickname)，最后才是用户名(username)
      // 如果都没有，提示未设置姓名
      studentInfo.name = user.real_name || user.nickname || user.username || '未设置姓名'
      studentInfo.avatar = user.avatar || ''
      studentInfo.school = user.school_name || '未设置学校'
      
      // 获取学生所在的班级信息（可能有多个班级，取第一个）
      try {
        const classResponse = await request.get('/pbl/student/club/my-classes')
        const classes = classResponse.data || []
        if (classes.length > 0) {
          // 如果学生加入了多个班级，显示第一个班级名称
          studentInfo.class = classes[0].name
        } else {
          studentInfo.class = '未加入班级'
        }
      } catch (classError) {
        console.warn('获取班级信息失败:', classError)
        studentInfo.class = '未加入班级'
      }
    }
  } catch (error) {
    console.error('加载学生信息失败:', error)
    // 降级到从 localStorage 读取
    const userStr = localStorage.getItem('user')
    if (userStr) {
      const user = JSON.parse(userStr)
      studentInfo.name = user.real_name || user.nickname || user.username || '未设置姓名'
      studentInfo.school = user.school_name || '未设置学校'
      studentInfo.class = '未加入班级'
    }
  }
}

const loadCourses = async () => {
  try {
    const data = await getMyCourses()
    courses.value = data.items || data || []
    statistics.totalCourses = data.total || courses.value.length
  } catch (error) {
    console.error('加载课程列表失败:', error)
  }
}

const loadPortfolioWorks = async () => {
  try {
    const response = await request.get('/pbl/student/my-tasks')
    const tasks = response.data || []
    // 转换任务数据为作业任务展示格式
    portfolioWorks.value = tasks.map(task => ({
      id: task.task_uuid,
      title: task.task_title,
      description: task.unit_title || '',
      course_name: task.course_title,
      created_at: task.submitted_at,
      thumbnail: null
    }))
    statistics.totalOutputs = portfolioWorks.value.length
  } catch (error) {
    console.error('加载作业任务失败:', error)
  }
}

onMounted(() => {
  loadStudentInfo()
  loadCourses()
  loadPortfolioWorks()
})
</script>

<style scoped>
.student-portfolio-container {
  padding: 20px;
  max-width: 1200px;
  margin: 0 auto;
}

.profile-card {
  margin-bottom: 20px;
}

.profile-header {
  display: flex;
  gap: 24px;
  align-items: center;
}

.profile-info {
  flex: 1;
}

.profile-info h3 {
  margin: 0 0 8px 0;
  font-size: 24px;
  font-weight: 600;
  color: #1e293b;
}

.school-info {
  margin: 0 0 16px 0;
  color: #64748b;
  font-size: 14px;
}

.profile-stats {
  display: flex;
  gap: 40px;
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.stat-value {
  font-size: 32px;
  font-weight: 600;
  color: #3b82f6;
}

.stat-label {
  font-size: 14px;
  color: #64748b;
}

.content-card {
  margin-bottom: 20px;
}

/* 课程网格 */
.courses-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
  padding: 20px 0;
}

.course-card {
  cursor: pointer;
  transition: all 0.3s;
  border-radius: 12px;
}

.course-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.1);
}

.course-cover {
  width: 100%;
  height: 180px;
  overflow: hidden;
  border-radius: 8px;
  margin-bottom: 16px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.course-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.placeholder-cover {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.course-info h4 {
  margin: 0 0 8px 0;
  font-size: 18px;
  font-weight: 600;
  color: #1e293b;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.course-desc {
  margin: 0 0 12px 0;
  font-size: 14px;
  color: #64748b;
  line-height: 1.5;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  min-height: 42px;
}

.course-meta {
  display: flex;
  align-items: center;
  gap: 12px;
}

/* 作业任务网格 */
.works-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 20px;
  padding: 20px 0;
}

.work-card {
  transition: all 0.3s;
  border-radius: 12px;
}

.work-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.1);
}

.work-cover {
  width: 100%;
  height: 160px;
  overflow: hidden;
  border-radius: 8px;
  margin-bottom: 12px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.work-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.work-info h4 {
  margin: 0 0 8px 0;
  font-size: 16px;
  font-weight: 600;
  color: #1e293b;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.work-desc {
  margin: 0 0 12px 0;
  font-size: 14px;
  color: #64748b;
  line-height: 1.5;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  min-height: 42px;
}

.work-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.work-date {
  font-size: 12px;
  color: #94a3b8;
}

/* 空状态优化 */
:deep(.el-empty) {
  padding: 60px 0;
}

:deep(.el-empty__description) {
  margin-top: 16px;
  color: #94a3b8;
}

/* 响应式 */
@media (max-width: 768px) {
  .student-portfolio-container {
    padding: 12px;
  }

  .profile-header {
    flex-direction: column;
    text-align: center;
  }

  .profile-stats {
    justify-content: center;
    gap: 24px;
  }

  .courses-grid,
  .works-grid {
    grid-template-columns: 1fr;
  }
}
</style>
