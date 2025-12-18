<template>
  <div class="login-container">
    <div class="login-card">
      <div class="login-header">
        <h1>CodeHubot</h1>
        <p>统一管理平台</p>
      </div>
      
      <el-form
        ref="generalFormRef"
        :model="generalForm"
        :rules="generalRules"
        @submit.prevent="handleGeneralLogin"
        class="login-form"
      >
        <el-form-item prop="username">
          <el-input
            v-model="generalForm.username"
            placeholder="用户名/邮箱"
            prefix-icon="User"
            size="large"
            clearable
          />
        </el-form-item>
        
        <el-form-item prop="password">
          <el-input
            v-model="generalForm.password"
            type="password"
            placeholder="密码"
            prefix-icon="Lock"
            size="large"
            show-password
            @keyup.enter="handleGeneralLogin"
          />
        </el-form-item>
        
        <el-form-item>
          <el-button
            type="primary"
            size="large"
            style="width: 100%"
            :loading="loading"
            @click="handleGeneralLogin"
          >
            登录
          </el-button>
        </el-form-item>
      </el-form>
      
      <div class="login-footer">
        <el-link type="primary" :underline="false">忘记密码？</el-link>
        <el-divider direction="vertical" />
        <el-link type="primary" :underline="false">没有账号？注册</el-link>
      </div>
    </div>
    
    <div class="login-bg">
      <div class="bg-shape shape-1"></div>
      <div class="bg-shape shape-2"></div>
      <div class="bg-shape shape-3"></div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { ElMessage } from 'element-plus'
import { login } from '@shared/api/auth'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

// 表单引用
const generalFormRef = ref()
const loading = ref(false)

// 通用登录表单
const generalForm = reactive({
  username: '',
  password: ''
})

const generalRules = {
  username: [
    { required: true, message: '请输入用户名或邮箱', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码至少6位', trigger: 'blur' }
  ]
}

// 通用登录
async function handleGeneralLogin() {
  if (!generalFormRef.value) return
  
  await generalFormRef.value.validate(async (valid) => {
    if (!valid) return
    
    loading.value = true
    try {
      const loginData = {
        email: generalForm.username,  // 支持用户名或邮箱
        password: generalForm.password
      }
      
      await authStore.login(login, loginData)
      
      ElMessage.success('登录成功')
      
      // 跳转到目标页面或门户页
      const redirect = route.query.redirect || '/'
      router.push(redirect)
    } catch (error) {
      ElMessage.error(error.response?.data?.detail || error.message || '登录失败')
    } finally {
      loading.value = false
    }
  })
}
</script>

<style scoped lang="scss">
.login-container {
  position: relative;
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  overflow: hidden;
}

.login-card {
  position: relative;
  z-index: 10;
  background: white;
  border-radius: 20px;
  padding: 50px 40px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  width: 450px;
  max-width: 90vw;
}

.login-header {
  text-align: center;
  margin-bottom: 40px;
  
  h1 {
    font-size: 36px;
    font-weight: bold;
    color: #2c3e50;
    margin-bottom: 10px;
  }
  
  p {
    font-size: 16px;
    color: #999;
  }
}

.login-form {
  margin-top: 30px;
  
  .el-form-item {
    margin-bottom: 24px;
  }
}

.login-footer {
  text-align: center;
  margin-top: 30px;
  padding-top: 20px;
  border-top: 1px solid #f0f0f0;
  
  .el-divider {
    margin: 0 15px;
  }
}

.login-bg {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 1;
  overflow: hidden;
}

.bg-shape {
  position: absolute;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  animation: float 20s infinite ease-in-out;
}

.shape-1 {
  width: 300px;
  height: 300px;
  top: 10%;
  left: 10%;
  animation-delay: 0s;
}

.shape-2 {
  width: 200px;
  height: 200px;
  bottom: 20%;
  right: 15%;
  animation-delay: 3s;
}

.shape-3 {
  width: 150px;
  height: 150px;
  top: 50%;
  right: 25%;
  animation-delay: 6s;
}

@keyframes float {
  0%, 100% {
    transform: translateY(0) rotate(0deg);
  }
  25% {
    transform: translateY(-30px) rotate(90deg);
  }
  50% {
    transform: translateY(0) rotate(180deg);
  }
  75% {
    transform: translateY(30px) rotate(270deg);
  }
}

@media (max-width: 768px) {
  .login-card {
    padding: 40px 30px;
  }
  
  .login-header h1 {
    font-size: 28px;
  }
}
</style>
