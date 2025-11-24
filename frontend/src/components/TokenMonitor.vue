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
      // 检查 refresh token 是否过期
      if (userStore.isRefreshTokenExpired) {
        logger.warn('TokenMonitor: Refresh token已过期，执行登出')
        ElMessage.warning('登录已过期，请重新登录')
        userStore.logout('Refresh token已过期')
        if (router.currentRoute.value.path !== '/login') {
          logger.info('TokenMonitor: 重定向到登录页')
          router.push('/login')
        }
        return
      }
      
      // 检查token是否过期
      if (userStore.isTokenExpired) {
        logger.warn('TokenMonitor: 检测到token过期，尝试刷新')
        // 尝试刷新 token
        userStore.refreshAccessToken().then(success => {
          if (!success) {
            ElMessage.warning('登录已过期，请重新登录')
            if (router.currentRoute.value.path !== '/login') {
              router.push('/login')
            }
          }
        })
        return
      }
      
      // 检查token是否即将过期（提前3分钟），主动刷新
      if (userStore.isTokenExpiringSoon && !userStore.isRefreshing) {
        logger.info('TokenMonitor: 检测到token即将过期，主动刷新')
        userStore.proactiveRefreshToken().then(success => {
          if (success) {
            logger.info('TokenMonitor: Token主动刷新成功')
          } else {
            logger.warn('TokenMonitor: Token主动刷新失败')
          }
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