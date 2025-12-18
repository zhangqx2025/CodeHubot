<template>
  <div class="forgot-password-container">
    <div class="forgot-password-box">
      <div class="forgot-password-header">
        <h2>重置密码</h2>
        <p>通过手机验证码重置您的密码</p>
      </div>
      
      <el-form
        ref="forgotFormRef"
        :model="forgotForm"
        :rules="forgotRules"
        class="forgot-form"
        @submit.prevent="handleReset"
      >
        <el-form-item prop="phone">
          <el-input
            v-model="forgotForm.phone"
            placeholder="请输入手机号"
            prefix-icon="Phone"
            maxlength="11"
          />
        </el-form-item>
        
        <el-form-item prop="code">
          <div class="code-input">
            <el-input
              v-model="forgotForm.code"
              placeholder="请输入验证码"
              prefix-icon="Message"
              maxlength="6"
            />
            <el-button
              :disabled="codeDisabled"
              @click="sendCode"
            >
              {{ codeText }}
            </el-button>
          </div>
        </el-form-item>
        
        <el-form-item prop="password">
          <el-input
            v-model="forgotForm.password"
            type="password"
            placeholder="请输入新密码"
            prefix-icon="Lock"
            show-password
          />
        </el-form-item>
        
        <el-form-item prop="confirmPassword">
          <el-input
            v-model="forgotForm.confirmPassword"
            type="password"
            placeholder="请确认新密码"
            prefix-icon="Lock"
            show-password
          />
        </el-form-item>
        
        <el-form-item>
          <el-button
            type="primary"
            class="reset-btn"
            :loading="loading"
            @click="handleReset"
          >
            重置密码
          </el-button>
        </el-form-item>
      </el-form>
      
      <div class="forgot-footer">
        <el-link @click="$router.push('/login')">返回登录</el-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '../store/user'
import { ElMessage } from 'element-plus'

const router = useRouter()
const userStore = useUserStore()

const forgotFormRef = ref()
const loading = ref(false)
const codeDisabled = ref(false)
const codeText = ref('发送验证码')
const countdown = ref(0)

const forgotForm = reactive({
  phone: '',
  code: '',
  password: '',
  confirmPassword: ''
})

const forgotRules = {
  phone: [
    { required: true, message: '请输入手机号', trigger: 'blur' },
    { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的手机号', trigger: 'blur' }
  ],
  code: [
    { required: true, message: '请输入验证码', trigger: 'blur' },
    { pattern: /^\d{6}$/, message: '请输入6位数字验证码', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, message: '密码长度不能少于6位', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认新密码', trigger: 'blur' },
    {
      validator: (rule, value, callback) => {
        if (value !== forgotForm.password) {
          callback(new Error('两次输入的密码不一致'))
        } else {
          callback()
        }
      },
      trigger: 'blur'
    }
  ]
}

const sendCode = async () => {
  if (!forgotForm.phone) {
    ElMessage.warning('请先输入手机号')
    return
  }
  
  try {
    await userStore.sendCode(forgotForm.phone, 'reset_password')
    startCountdown()
  } catch (error) {
    console.error('发送验证码失败:', error)
  }
}

const startCountdown = () => {
  codeDisabled.value = true
  countdown.value = 60
  codeText.value = `${countdown.value}秒后重发`
  
  const timer = setInterval(() => {
    countdown.value--
    codeText.value = `${countdown.value}秒后重发`
    
    if (countdown.value <= 0) {
      clearInterval(timer)
      codeDisabled.value = false
      codeText.value = '发送验证码'
    }
  }, 1000)
}

const handleReset = async () => {
  if (!forgotFormRef.value) return
  
  await forgotFormRef.value.validate(async (valid) => {
    if (valid) {
      loading.value = true
      try {
        await userStore.resetUserPassword(forgotForm.phone, forgotForm.password, forgotForm.code)
        router.push('/login')
      } catch (error) {
        console.error('密码重置失败:', error)
      } finally {
        loading.value = false
      }
    }
  })
}
</script>

<style scoped>
.forgot-password-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.forgot-password-box {
  width: 400px;
  padding: 40px;
  background: white;
  border-radius: 10px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
}

.forgot-password-header {
  text-align: center;
  margin-bottom: 30px;
}

.forgot-password-header h2 {
  color: #333;
  margin-bottom: 10px;
}

.forgot-password-header p {
  color: #666;
  font-size: 14px;
}

.forgot-form {
  margin-bottom: 20px;
}

.code-input {
  display: flex;
  gap: 10px;
}

.code-input .el-input {
  flex: 1;
}

.reset-btn {
  width: 100%;
  height: 45px;
  font-size: 16px;
}

.forgot-footer {
  text-align: center;
}
</style>
