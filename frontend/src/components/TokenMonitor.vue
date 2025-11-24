<template>
  <!-- 这是一个无界面的监控组件 -->
</template>

<script setup>
import { onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useUserStore } from '../store/user'
import { ElMessage } from 'element-plus'
import logger from '@/utils/logger'

const router = useRouter()
const userStore = useUserStore()
let checkInterval = null

// 定期检查token状态
const startTokenMonitoring = () => {
  logger.debug('TokenMonitor: 开始token监控')
  // 每分钟检查一次token状态
  checkInterval = setInterval(() => {
    logger.debug('TokenMonitor: 执行定期token检查', {
      hasToken: !!userStore.token,
      isExpired: userStore.isTokenExpired,
      isExpiringSoon: userStore.isTokenExpiringSoon
    })
    
    if (userStore.token) {
      // 检查token是否过期
      if (userStore.isTokenExpired) {
        logger.warn('TokenMonitor: 检测到token过期，执行登出')
        ElMessage.warning('登录已过期，请重新登录')
        userStore.logout('TokenMonitor检测到token过期')
        if (router.currentRoute.value.path !== '/login') {
          logger.info('TokenMonitor: 重定向到登录页')
          router.push('/login')
        }
        return
      }
      
      // 检查token是否即将过期（提前5分钟提醒）
      if (userStore.isTokenExpiringSoon) {
        logger.warn('TokenMonitor: 检测到token即将过期，显示警告')
        ElMessage({
          message: '您的登录即将在5分钟内过期，请注意保存工作',
          type: 'warning',
          duration: 10000,
          showClose: true
        })
      }
    } else {
      logger.debug('TokenMonitor: 无token，跳过检查')
    }
  }, 60000) // 每分钟检查一次
}

const stopTokenMonitoring = () => {
  logger.debug('TokenMonitor: 停止token监控')
  if (checkInterval) {
    clearInterval(checkInterval)
    checkInterval = null
  }
}

onMounted(() => {
  startTokenMonitoring()
})

onUnmounted(() => {
  stopTokenMonitoring()
})
</script>