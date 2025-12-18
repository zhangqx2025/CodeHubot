<template>
  <div class="course-detail">
    <!-- 加载状态 -->
    <el-skeleton v-if="loading" :rows="5" animated />
    
    <!-- 课程详情 -->
    <template v-else-if="course">
      <!-- 课程头部 -->
      <el-card class="course-header" shadow="never">
        <div class="header-content">
          <div class="course-cover">
            <img 
              :src="course.cover_image || '/default-course-cover.jpg'" 
              :alt="course.title"
              @error="handleImageError"
            />
          </div>
          <div class="course-info">
            <div class="course-difficulty" :class="`difficulty-${course.difficulty}`">
              {{ getDifficultyText(course.difficulty) }}
            </div>
            <h1 class="course-title">{{ course.title }}</h1>
            <p class="course-description">{{ course.description }}</p>
            
            <div class="course-meta">
              <div class="meta-item">
                <el-icon><Clock /></el-icon>
                <span>{{ course.duration || '8周' }}</span>
              </div>
              <div class="meta-item">
                <el-icon><Reading /></el-icon>
                <span>{{ course.total_units }}个单元</span>
              </div>
              <div class="meta-item">
                <el-icon><TrophyBase /></el-icon>
                <span>学习进度: {{ course.progress || 0 }}%</span>
              </div>
            </div>

            <div class="action-buttons">
              <el-button type="primary" size="large" @click="startLearning">
                {{ course.progress > 0 ? '继续学习' : '开始学习' }}
              </el-button>
              <el-button size="large" @click="goBack">返回课程列表</el-button>
            </div>
          </div>
        </div>
      </el-card>

      <!-- 课程内容 -->
      <el-card class="course-content" shadow="never">
        <el-tabs v-model="activeTab">
          <el-tab-pane label="课程简介" name="intro">
            <div class="content-section">
              <h3>课程目标</h3>
              <p>{{ course.learning_objectives || '通过本课程，你将掌握项目式学习的核心方法和实践技能。' }}</p>
              
              <h3>课程特点</h3>
              <div class="course-features">
                <el-tag type="info" effect="plain">项目式学习</el-tag>
                <el-tag type="success" effect="plain">实战项目</el-tag>
                <el-tag type="warning" effect="plain">边做边学</el-tag>
                <el-tag type="danger" effect="plain">作品导向</el-tag>
              </div>
            </div>
          </el-tab-pane>

          <el-tab-pane label="课程章节" name="chapters">
            <div class="chapters-list">
              <el-empty 
                v-if="!course.units || course.units.length === 0"
                description="暂无课程章节"
              />
              <div v-else>
                <div 
                  v-for="(unit, index) in course.units" 
                  :key="unit.id"
                  class="chapter-item"
                >
                  <div class="chapter-header">
                    <div class="chapter-number">{{ index + 1 }}</div>
                    <div class="chapter-info">
                      <h4>{{ unit.title }}</h4>
                      <p>{{ unit.description }}</p>
                    </div>
                    <el-button type="primary" link>开始学习</el-button>
                  </div>
                </div>
              </div>
            </div>
          </el-tab-pane>

          <el-tab-pane label="我的进度" name="progress">
            <div class="progress-section">
              <el-progress 
                :percentage="course.progress || 0" 
                :stroke-width="20"
                :text-inside="true"
              />
              <div class="progress-stats">
                <div class="stat-item">
                  <span class="stat-label">已完成</span>
                  <span class="stat-value">{{ course.completed_units || 0 }}</span>
                </div>
                <div class="stat-item">
                  <span class="stat-label">总单元数</span>
                  <span class="stat-value">{{ course.total_units || 0 }}</span>
                </div>
              </div>
            </div>
          </el-tab-pane>
        </el-tabs>
      </el-card>
    </template>

    <!-- 错误状态 -->
    <el-empty 
      v-else
      description="课程不存在或已被删除"
      :image-size="200"
    >
      <el-button type="primary" @click="goBack">返回课程列表</el-button>
    </el-empty>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Clock, Reading, TrophyBase } from '@element-plus/icons-vue'
import { getCourseDetail } from '@pbl/student/api/student'

const router = useRouter()
const route = useRoute()

// 状态管理
const loading = ref(false)
const course = ref(null)
const activeTab = ref('intro')

// 方法
const loadCourseDetail = async () => {
  loading.value = true
  try {
    const courseUuid = route.params.uuid
    const data = await getCourseDetail(courseUuid)
    course.value = data
  } catch (error) {
    ElMessage.error('加载课程详情失败: ' + error.message)
    console.error('Load course detail error:', error)
  } finally {
    loading.value = false
  }
}

const getDifficultyText = (difficulty) => {
  const map = {
    'beginner': '入门',
    'intermediate': '中级',
    'advanced': '高级'
  }
  return map[difficulty] || '入门'
}

const handleImageError = (e) => {
  e.target.src = 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800'
}

const startLearning = () => {
  // TODO: 跳转到第一个未完成的单元或章节
  ElMessage.info('开始学习功能开发中...')
}

const goBack = () => {
  router.push('/pbl/student/courses')
}

onMounted(() => {
  loadCourseDetail()
})
</script>

<style scoped>
.course-detail {
  padding: 0;
}

.course-header {
  margin-bottom: 20px;
  border-radius: 12px;
  border: none;
}

.header-content {
  display: flex;
  gap: 30px;
}

.course-cover {
  width: 400px;
  height: 300px;
  border-radius: 12px;
  overflow: hidden;
  flex-shrink: 0;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.course-cover img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.course-info {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.course-difficulty {
  display: inline-block;
  padding: 6px 16px;
  border-radius: 20px;
  font-size: 13px;
  font-weight: 500;
  margin-bottom: 16px;
  align-self: flex-start;
}

.difficulty-beginner {
  background: rgba(16, 185, 129, 0.1);
  color: #10b981;
  border: 1px solid #10b981;
}

.difficulty-intermediate {
  background: rgba(245, 158, 11, 0.1);
  color: #f59e0b;
  border: 1px solid #f59e0b;
}

.difficulty-advanced {
  background: rgba(239, 68, 68, 0.1);
  color: #ef4444;
  border: 1px solid #ef4444;
}

.course-title {
  font-size: 32px;
  font-weight: 600;
  color: #1e293b;
  margin: 0 0 16px 0;
}

.course-description {
  font-size: 16px;
  color: #64748b;
  line-height: 1.6;
  margin: 0 0 24px 0;
}

.course-meta {
  display: flex;
  gap: 24px;
  margin-bottom: 32px;
  flex-wrap: wrap;
}

.meta-item {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 15px;
  color: #64748b;
}

.meta-item .el-icon {
  font-size: 20px;
  color: #667eea;
}

.action-buttons {
  display: flex;
  gap: 16px;
  margin-top: auto;
}

.course-content {
  border-radius: 12px;
  border: none;
}

.content-section h3 {
  font-size: 20px;
  font-weight: 600;
  color: #1e293b;
  margin: 0 0 16px 0;
}

.content-section p {
  font-size: 15px;
  color: #64748b;
  line-height: 1.6;
  margin-bottom: 24px;
}

.course-features {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}

.chapters-list {
  padding: 8px 0;
}

.chapter-item {
  margin-bottom: 16px;
  padding: 20px;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  transition: all 0.3s;
}

.chapter-item:hover {
  border-color: #667eea;
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.1);
}

.chapter-header {
  display: flex;
  align-items: center;
  gap: 20px;
}

.chapter-number {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  font-weight: 600;
  flex-shrink: 0;
}

.chapter-info {
  flex: 1;
}

.chapter-info h4 {
  font-size: 18px;
  font-weight: 600;
  color: #1e293b;
  margin: 0 0 8px 0;
}

.chapter-info p {
  font-size: 14px;
  color: #64748b;
  margin: 0;
  line-height: 1.5;
}

.progress-section {
  padding: 20px 0;
}

.progress-stats {
  display: flex;
  gap: 48px;
  margin-top: 32px;
}

.stat-item {
  text-align: center;
}

.stat-label {
  display: block;
  font-size: 14px;
  color: #64748b;
  margin-bottom: 8px;
}

.stat-value {
  display: block;
  font-size: 32px;
  font-weight: 600;
  color: #667eea;
}

@media (max-width: 768px) {
  .header-content {
    flex-direction: column;
  }

  .course-cover {
    width: 100%;
    height: 250px;
  }

  .course-title {
    font-size: 24px;
  }

  .action-buttons {
    flex-direction: column;
  }

  .action-buttons .el-button {
    width: 100%;
  }
}
</style>
