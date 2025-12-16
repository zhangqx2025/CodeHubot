<template>
  <div class="portal-container">
    <div class="portal-header">
      <h1>CodeHubot 统一管理平台</h1>
      <p>欢迎，{{ authStore.userName }}！请选择您要进入的系统</p>
    </div>
    
    <div class="portal-cards">
      <!-- Device管理系统 -->
      <div v-if="canAccessDevice" class="portal-card device-card" @click="enterDevice">
        <div class="card-icon">
          <el-icon :size="50"><Setting /></el-icon>
        </div>
        <h2>设备管理系统</h2>
        <p class="card-description">管理物联网设备、查看实时数据、远程控制</p>
        <ul class="card-features">
          <li><el-icon><Check /></el-icon> 设备监控与管理</li>
          <li><el-icon><Check /></el-icon> 实时数据分析</li>
          <li><el-icon><Check /></el-icon> 远程控制</li>
          <li><el-icon><Check /></el-icon> 固件管理</li>
        </ul>
        <el-button type="primary" size="large" class="enter-btn">
          进入系统 <el-icon class="el-icon--right"><ArrowRight /></el-icon>
        </el-button>
      </div>
      
      <!-- AI智能系统 -->
      <div v-if="authStore.isAuthenticated" class="portal-card ai-card" @click="enterAI">
        <div class="card-icon">
          <el-icon :size="50"><MagicStick /></el-icon>
        </div>
        <h2>AI智能系统</h2>
        <p class="card-description">智能对话、工作流编排、知识库管理、插件开发</p>
        <ul class="card-features">
          <li><el-icon><Check /></el-icon> AI对话与智能体</li>
          <li><el-icon><Check /></el-icon> 工作流编排</li>
          <li><el-icon><Check /></el-icon> 知识库管理</li>
          <li><el-icon><Check /></el-icon> 插件开发</li>
        </ul>
        <el-button type="primary" size="large" class="enter-btn" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border: none;">
          进入系统 <el-icon class="el-icon--right"><ArrowRight /></el-icon>
        </el-button>
      </div>
      
      <!-- PBL学习平台 - 学生端 -->
      <div v-if="authStore.isStudent" class="portal-card student-card" @click="enterPBLStudent">
        <div class="card-icon">
          <el-icon :size="50"><Reading /></el-icon>
        </div>
        <h2>PBL学习平台</h2>
        <p class="card-description">项目式学习、课程作业、学习进度跟踪</p>
        <ul class="card-features">
          <li><el-icon><Check /></el-icon> 我的课程</li>
          <li><el-icon><Check /></el-icon> 项目学习</li>
          <li><el-icon><Check /></el-icon> 作业提交</li>
          <li><el-icon><Check /></el-icon> 学习档案</li>
        </ul>
        <el-button type="success" size="large" class="enter-btn">
          学生入口 <el-icon class="el-icon--right"><ArrowRight /></el-icon>
        </el-button>
      </div>
      
      <!-- PBL教学平台 - 教师端 -->
      <div v-if="authStore.isTeacher" class="portal-card teacher-card" @click="enterPBLTeacher">
        <div class="card-icon">
          <el-icon :size="50"><Notebook /></el-icon>
        </div>
        <h2>PBL教学平台</h2>
        <p class="card-description">课程管理、作业批改、学生进度监控</p>
        <ul class="card-features">
          <li><el-icon><Check /></el-icon> 课程管理</li>
          <li><el-icon><Check /></el-icon> 作业批改</li>
          <li><el-icon><Check /></el-icon> 数据分析</li>
          <li><el-icon><Check /></el-icon> 班级管理</li>
        </ul>
        <el-button type="warning" size="large" class="enter-btn">
          教师入口 <el-icon class="el-icon--right"><ArrowRight /></el-icon>
        </el-button>
      </div>
      
      <!-- PBL管理平台 - 管理员端 -->
      <div v-if="isAdmin" class="portal-card admin-card" @click="enterPBLAdmin">
        <div class="card-icon">
          <el-icon :size="50"><User /></el-icon>
        </div>
        <h2>PBL管理平台</h2>
        <p class="card-description">系统管理、用户管理、课程模板配置</p>
        <ul class="card-features">
          <li><el-icon><Check /></el-icon> 用户管理</li>
          <li><el-icon><Check /></el-icon> 课程模板</li>
          <li><el-icon><Check /></el-icon> 学校管理</li>
          <li><el-icon><Check /></el-icon> 数据统计</li>
        </ul>
        <el-button type="danger" size="large" class="enter-btn">
          管理员入口 <el-icon class="el-icon--right"><ArrowRight /></el-icon>
        </el-button>
      </div>
      
      <!-- 渠道商平台 -->
      <div v-if="authStore.isChannelPartner" class="portal-card channel-card" @click="enterChannel">
        <div class="card-icon">
          <el-icon :size="50"><Connection /></el-icon>
        </div>
        <h2>渠道商平台</h2>
        <p class="card-description">合作学校管理、课程监控、数据查看</p>
        <ul class="card-features">
          <li><el-icon><Check /></el-icon> 学校管理</li>
          <li><el-icon><Check /></el-icon> 课程监控</li>
          <li><el-icon><Check /></el-icon> 数据统计</li>
          <li><el-icon><Check /></el-icon> 进度跟踪</li>
        </ul>
        <el-button type="info" size="large" class="enter-btn">
          渠道商入口 <el-icon class="el-icon--right"><ArrowRight /></el-icon>
        </el-button>
      </div>
      
      <!-- 渠道管理平台 -->
      <div v-if="isChannelManagerOrAdmin" class="portal-card channel-mgmt-card" @click="enterChannelManagement">
        <div class="card-icon">
          <el-icon :size="50"><Histogram /></el-icon>
        </div>
        <h2>渠道管理平台</h2>
        <p class="card-description">渠道商管理、学校分配、业务统计</p>
        <ul class="card-features">
          <li><el-icon><Check /></el-icon> 渠道商管理</li>
          <li><el-icon><Check /></el-icon> 学校分配</li>
          <li><el-icon><Check /></el-icon> 业务统计</li>
          <li><el-icon><Check /></el-icon> 活动监控</li>
        </ul>
        <el-button type="success" size="large" class="enter-btn" style="background: linear-gradient(135deg, #56ab2f 0%, #a8e063 100%); border: none;">
          管理入口 <el-icon class="el-icon--right"><ArrowRight /></el-icon>
        </el-button>
      </div>
    </div>
    
    <div class="portal-footer">
      <div class="user-info">
        <el-avatar :size="40">{{ authStore.userName.charAt(0) }}</el-avatar>
        <div class="user-details">
          <span class="user-name">{{ authStore.userName }}</span>
          <span class="user-role">{{ getRoleText(authStore.userRole) }}</span>
        </div>
        <el-button type="text" @click="handleLogout" class="logout-btn">
          <el-icon><SwitchButton /></el-icon> 退出登录
        </el-button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, watch, ref, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { ElMessage, ElMessageBox } from 'element-plus'
import { 
  Setting, Reading, Notebook, User, Check, ArrowRight, SwitchButton, MagicStick, Connection, Histogram
} from '@element-plus/icons-vue'

const router = useRouter()
const authStore = useAuthStore()

// 强制刷新标记
const forceUpdate = ref(0)

// 使用响应式计算属性判断是否可以访问设备系统
const canAccessDevice = computed(() => {
  forceUpdate.value // 依赖forceUpdate触发重新计算
  return authStore.isAuthenticated
})

// 直接使用store的计算属性（已修复响应式问题）
const isAdmin = computed(() => {
  forceUpdate.value // 依赖forceUpdate触发重新计算
  return authStore.isAdmin
})

const isChannelManagerOrAdmin = computed(() => {
  forceUpdate.value // 依赖forceUpdate触发重新计算
  return authStore.isChannelManager || authStore.isAdmin
})

// 监听userInfo变化，强制刷新
watch(() => authStore.userInfo, (newVal) => {
  if (newVal) {
    nextTick(() => {
      forceUpdate.value++
    })
  }
}, { immediate: true, deep: true })

// 进入不同系统
function enterDevice() {
  router.push('/device/dashboard')
}

function enterAI() {
  router.push('/ai/dashboard')
}

function enterPBLStudent() {
  router.push('/pbl/student/courses')
}

function enterPBLTeacher() {
  router.push('/pbl/teacher/dashboard')
}

function enterPBLAdmin() {
  router.push('/pbl/admin/dashboard')
}

function enterChannel() {
  router.push('/pbl/channel/schools')
}

function enterChannelManagement() {
  router.push('/pbl/channel-mgmt/partners')
}

// 退出登录
function handleLogout() {
  ElMessageBox.confirm('确定要退出登录吗？', '提示', {
    confirmButtonText: '确定',
    cancelButtonText: '取消',
    type: 'warning'
  }).then(() => {
    authStore.logout()
    router.push('/login')
    ElMessage.success('已退出登录')
  }).catch(() => {
    // 取消退出
  })
}

// 获取角色显示文本
function getRoleText(role) {
  const roleMap = {
    student: '学生',
    teacher: '教师',
    admin: '管理员',
    super_admin: '超级管理员',
    school_admin: '学校管理员',
    platform_admin: '平台管理员',
    channel_manager: '渠道管理员',
    channel_partner: '渠道商',
    individual: '个人用户'
  }
  return roleMap[role] || role
}
</script>

<style scoped lang="scss">
.portal-container {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 60px 20px 40px;
}

.portal-header {
  text-align: center;
  color: white;
  margin-bottom: 60px;
  
  h1 {
    font-size: 48px;
    font-weight: bold;
    margin-bottom: 15px;
    text-shadow: 0 2px 10px rgba(0, 0, 0, 0.2);
  }
  
  p {
    font-size: 20px;
    opacity: 0.95;
  }
}

.portal-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 30px;
  max-width: 1400px;
  margin: 0 auto;
  padding: 0 20px;
}

.portal-card {
  background: white;
  border-radius: 20px;
  padding: 40px 30px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15);
  
  &:hover {
    transform: translateY(-10px);
    box-shadow: 0 20px 50px rgba(0, 0, 0, 0.25);
  }
  
  .card-icon {
    width: 100px;
    height: 100px;
    border-radius: 50%;
    margin: 0 auto 25px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
  }
  
  h2 {
    font-size: 26px;
    margin-bottom: 12px;
    color: #2c3e50;
    font-weight: 600;
  }
  
  .card-description {
    color: #666;
    margin-bottom: 25px;
    line-height: 1.6;
    font-size: 15px;
  }
  
  .card-features {
    list-style: none;
    padding: 0;
    margin: 25px 0;
    text-align: left;
    
    li {
      padding: 10px 0;
      color: #555;
      font-size: 14px;
      display: flex;
      align-items: center;
      gap: 10px;
      
      .el-icon {
        color: #67c23a;
        font-size: 16px;
      }
    }
  }
  
  .enter-btn {
    margin-top: 20px;
    width: 100%;
    font-size: 16px;
    height: 48px;
  }
}

.device-card .card-icon {
  background: linear-gradient(135deg, #409eff 0%, #1e88e5 100%);
}

.ai-card .card-icon {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.student-card .card-icon {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
}

.teacher-card .card-icon {
  background: linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%);
  color: #d35400 !important;
}

.admin-card .card-icon {
  background: linear-gradient(135deg, #ff9a9e 0%, #fecfef 100%);
}

.channel-card .card-icon {
  background: linear-gradient(135deg, #89f7fe 0%, #66a6ff 100%);
}

.channel-mgmt-card .card-icon {
  background: linear-gradient(135deg, #56ab2f 0%, #a8e063 100%);
}

.portal-footer {
  text-align: center;
  margin-top: 60px;
  
  .user-info {
    display: inline-flex;
    align-items: center;
    gap: 15px;
    background: white;
    padding: 15px 30px;
    border-radius: 50px;
    box-shadow: 0 5px 20px rgba(0, 0, 0, 0.15);
    
    .user-details {
      display: flex;
      flex-direction: column;
      align-items: flex-start;
      
      .user-name {
        color: #2c3e50;
        font-weight: 600;
        font-size: 16px;
      }
      
      .user-role {
        color: #999;
        font-size: 13px;
        margin-top: 2px;
      }
    }
    
    .logout-btn {
      margin-left: 15px;
      color: #f56c6c;
      
      &:hover {
        color: #f56c6c;
        background: rgba(245, 108, 108, 0.1);
      }
    }
  }
}

@media (max-width: 768px) {
  .portal-header h1 {
    font-size: 32px;
  }
  
  .portal-cards {
    grid-template-columns: 1fr;
  }
}
</style>
