/**
 * 认证状态管理
 * 使用Pinia管理全局的认证状态
 */
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { 
  getToken, setToken, removeToken,
  getUserInfo as getStoredUserInfo,
  setUserInfo as storeUserInfo,
  clearAuth
} from '@shared/utils/auth'
import { getUserInfo as fetchUserInfo } from '@shared/api/auth'

export const useAuthStore = defineStore('auth', () => {
  // 状态 - 先不从localStorage读取，等init()时再读
  const token = ref(null)
  const userInfo = ref(null)
  const loading = ref(false)
  const isInitialized = ref(false)

  // 计算属性
  const isAuthenticated = computed(() => !!token.value)
  const userRole = computed(() => {
    const role = userInfo.value?.role || ''
    return role
  })
  const userName = computed(() => userInfo.value?.username || userInfo.value?.name || '')
  const userEmail = computed(() => userInfo.value?.email || '')
  
  // 角色判断 - 直接从userInfo读取，不依赖userRole computed
  const isStudent = computed(() => {
    const role = userInfo.value?.role
    return role === 'student'
  })
  const isTeacher = computed(() => {
    const role = userInfo.value?.role
    return role === 'teacher'
  })
  const isChannelPartner = computed(() => {
    const role = userInfo.value?.role
    return role === 'channel_partner'
  })
  const isChannelManager = computed(() => {
    const role = userInfo.value?.role
    return role === 'channel_manager'
  })
  const isAdmin = computed(() => {
    const role = userInfo.value?.role
    return role === 'admin' || role === 'super_admin' || role === 'school_admin' || role === 'platform_admin'
  })

  /**
   * 设置登录信息
   */
  function setAuth(authData) {
    // 处理可能的多层嵌套结构 (response.data.data 或 response.data)
    let data = authData
    
    // 如果响应包含 code 和 data 字段（统一响应格式），提取 data
    if (data.code !== undefined && data.data && typeof data.data === 'object') {
      data = data.data
    }
    // 如果还有嵌套的data字段
    else if (data.data && typeof data.data === 'object' && data.data.access_token) {
      data = data.data
    }
    
    // 保存access token
    const accessToken = data.access_token || data.token
    if (accessToken) {
      token.value = accessToken
      setToken(accessToken)
    }
    
    // 保存refresh token
    const refreshToken = data.refresh_token
    if (refreshToken) {
      localStorage.setItem('refresh_token', refreshToken)
    }
    
    // 保存用户信息 (支持多种字段名: user, userInfo, admin, student, teacher)
    const user = data.user || data.userInfo || data.admin || data.student || data.teacher
    if (user) {
      userInfo.value = user
      storeUserInfo(user)
    }
  }

  /**
   * 登录
   */
  async function login(loginFunc, loginData) {
    loading.value = true
    try {
      const response = await loginFunc(loginData)
      setAuth(response)
      return response
    } catch (error) {
      throw error
    } finally {
      loading.value = false
    }
  }

  /**
   * 退出登录
   */
  function logout() {
    token.value = null
    userInfo.value = null
    clearAuth()
  }

  /**
   * 刷新用户信息
   */
  async function refreshUserInfo() {
    if (!token.value) return null
    
    try {
      const response = await fetchUserInfo()
      userInfo.value = response.user || response
      storeUserInfo(userInfo.value)
      return userInfo.value
    } catch (error) {
      return null
    }
  }

  /**
   * 初始化（从localStorage恢复状态）
   */
  function init() {
    // 恢复token
    const storedToken = getToken()
    
    // 恢复用户信息
    let storedInfo = getStoredUserInfo()
    
    // 修复错误的数据格式：如果userInfo包含code和data字段，提取真实的用户数据
    if (storedInfo && storedInfo.code !== undefined && storedInfo.data) {
      storedInfo = storedInfo.data.user || storedInfo.data
      storeUserInfo(storedInfo)  // 重新保存正确的格式
    }
    
    // 设置状态
    token.value = storedToken
    userInfo.value = storedInfo
    isInitialized.value = true
  }

  return {
    // 状态
    token,
    userInfo,
    loading,
    isInitialized,
    // 计算属性
    isAuthenticated,
    userRole,
    userName,
    userEmail,
    isStudent,
    isTeacher,
    isChannelPartner,
    isChannelManager,
    isAdmin,
    // 方法
    setAuth,
    login,
    logout,
    refreshUserInfo,
    init
  }
})
