<template>
  <div class="portal-container">
    <div class="portal-header">
      <h1>CodeHubot 系统门户</h1>
      <p>请选择您要进入的系统</p>
    </div>
    
    <div class="portal-cards">
      <!-- Device管理系统 -->
      <div class="portal-card" @click="enterDevice">
        <div class="card-icon device-icon">
          <i class="el-icon-setting"></i>
        </div>
        <h2>设备管理系统</h2>
        <p>管理物联网设备、查看实时数据、远程控制</p>
        <ul class="card-features">
          <li>设备监控</li>
          <li>数据分析</li>
          <li>远程控制</li>
          <li>固件管理</li>
        </ul>
        <el-button type="primary" size="large">
          进入系统
        </el-button>
      </div>
      
      <!-- PBL学习系统 - 学生端 -->
      <div class="portal-card" @click="enterPBLStudent" v-if="isStudent">
        <div class="card-icon student-icon">
          <i class="el-icon-reading"></i>
        </div>
        <h2>PBL学习平台</h2>
        <p>项目式学习、课程作业、学习进度跟踪</p>
        <ul class="card-features">
          <li>我的课程</li>
          <li>项目学习</li>
          <li>作业提交</li>
          <li>学习档案</li>
        </ul>
        <el-button type="success" size="large">
          学生入口
        </el-button>
      </div>
      
      <!-- PBL学习系统 - 教师端 -->
      <div class="portal-card" @click="enterPBLTeacher" v-if="isTeacher">
        <div class="card-icon teacher-icon">
          <i class="el-icon-notebook-2"></i>
        </div>
        <h2>PBL教学平台</h2>
        <p>课程管理、作业批改、学生进度监控</p>
        <ul class="card-features">
          <li>课程管理</li>
          <li>作业批改</li>
          <li>数据分析</li>
          <li>班级管理</li>
        </ul>
        <el-button type="warning" size="large">
          教师入口
        </el-button>
      </div>
      
      <!-- PBL学习系统 - 管理端 -->
      <div class="portal-card" @click="enterPBLAdmin" v-if="isAdmin">
        <div class="card-icon admin-icon">
          <i class="el-icon-user"></i>
        </div>
        <h2>PBL管理平台</h2>
        <p>系统管理、用户管理、课程模板配置</p>
        <ul class="card-features">
          <li>用户管理</li>
          <li>课程模板</li>
          <li>学校管理</li>
          <li>数据统计</li>
        </ul>
        <el-button type="danger" size="large">
          管理员入口
        </el-button>
      </div>
    </div>
    
    <div class="portal-footer">
      <div class="user-info">
        <el-avatar :src="userAvatar"></el-avatar>
        <span>{{ userName }}</span>
        <el-button type="text" @click="logout">退出登录</el-button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'

const router = useRouter()

// 用户信息（从localStorage或Vuex获取）
const userInfo = ref(JSON.parse(localStorage.getItem('userInfo') || '{}'))
const userName = computed(() => userInfo.value.username || '未登录')
const userAvatar = computed(() => userInfo.value.avatar || '')
const userRole = computed(() => userInfo.value.role || '')

// 角色判断
const isStudent = computed(() => userRole.value === 'student')
const isTeacher = computed(() => userRole.value === 'teacher')
const isAdmin = computed(() => ['admin', 'super_admin'].includes(userRole.value))

// 跳转到不同系统
function enterDevice() {
  const deviceUrl = import.meta.env.VITE_DEVICE_FRONTEND_URL || '/device'
  
  // 方案1：单前端多路由（直接跳转）
  router.push('/device/dashboard')
  
  // 方案2：独立前端（跳转到不同域名）
  // window.location.href = deviceUrl
}

function enterPBLStudent() {
  const pblUrl = import.meta.env.VITE_PBL_FRONTEND_URL || '/pbl/student'
  router.push('/pbl/student/courses')
  // window.location.href = `${pblUrl}/student`
}

function enterPBLTeacher() {
  router.push('/pbl/teacher/dashboard')
  // window.location.href = `${pblUrl}/teacher`
}

function enterPBLAdmin() {
  router.push('/pbl/admin/dashboard')
  // window.location.href = `${pblUrl}/admin`
}

function logout() {
  localStorage.clear()
  router.push('/login')
  ElMessage.success('已退出登录')
}
</script>

<style scoped>
.portal-container {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 40px 20px;
}

.portal-header {
  text-align: center;
  color: white;
  margin-bottom: 60px;
}

.portal-header h1 {
  font-size: 48px;
  margin-bottom: 10px;
  font-weight: bold;
}

.portal-header p {
  font-size: 20px;
  opacity: 0.9;
}

.portal-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 30px;
  max-width: 1400px;
  margin: 0 auto;
  padding: 0 20px;
}

.portal-card {
  background: white;
  border-radius: 16px;
  padding: 40px 30px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
}

.portal-card:hover {
  transform: translateY(-10px);
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.2);
}

.card-icon {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  margin: 0 auto 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 40px;
  color: white;
}

.device-icon {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.student-icon {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
}

.teacher-icon {
  background: linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%);
}

.admin-icon {
  background: linear-gradient(135deg, #ff9a9e 0%, #fecfef 100%);
}

.portal-card h2 {
  font-size: 24px;
  margin-bottom: 10px;
  color: #333;
}

.portal-card p {
  color: #666;
  margin-bottom: 20px;
  line-height: 1.6;
}

.card-features {
  list-style: none;
  padding: 0;
  margin: 20px 0;
  text-align: left;
}

.card-features li {
  padding: 8px 0;
  color: #888;
  position: relative;
  padding-left: 20px;
}

.card-features li:before {
  content: '✓';
  position: absolute;
  left: 0;
  color: #67c23a;
  font-weight: bold;
}

.portal-card .el-button {
  margin-top: 20px;
  width: 100%;
}

.portal-footer {
  text-align: center;
  margin-top: 60px;
}

.user-info {
  display: inline-flex;
  align-items: center;
  gap: 15px;
  background: white;
  padding: 15px 30px;
  border-radius: 50px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.user-info span {
  color: #333;
  font-weight: 500;
}
</style>
