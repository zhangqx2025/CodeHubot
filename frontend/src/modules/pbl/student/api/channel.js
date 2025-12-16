// 渠道商端API
import axios from 'axios'

// 在生产模式下使用空字符串（相对路径），通过 nginx proxy 转发
// 在开发模式下使用 localhost，方便本地开发
const API_BASE = import.meta.env.VITE_API_BASE || (import.meta.env.MODE === 'production' ? '' : 'http://localhost:8000')

// 创建axios实例（渠道商端）
const channelClient = axios.create({
  baseURL: API_BASE,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// 请求拦截器
channelClient.interceptors.request.use(
  (config) => {
    // 从localStorage获取渠道商token
    const token = localStorage.getItem('channel_access_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// 响应拦截器
channelClient.interceptors.response.use(
  (response) => {
    return response
  },
  async (error) => {
    const originalRequest = error.config
    
    // 如果是401错误且不是刷新token的请求，尝试刷新token
    if (error.response?.status === 401 && !originalRequest._retry && !originalRequest.url.includes('/auth/refresh')) {
      originalRequest._retry = true
      
      try {
        const refreshToken = localStorage.getItem('channel_refresh_token')
        if (refreshToken) {
          const response = await channelClient.post('/api/v1/channel/auth/refresh', {
            refresh_token: refreshToken
          })
          
          const { access_token, refresh_token: newRefreshToken } = response.data.data || response.data
          
          // 更新token
          localStorage.setItem('channel_access_token', access_token)
          if (newRefreshToken) {
            localStorage.setItem('channel_refresh_token', newRefreshToken)
          }
          
          // 重新发送原请求
          originalRequest.headers.Authorization = `Bearer ${access_token}`
          return channelClient(originalRequest)
        }
      } catch (refreshError) {
        // 刷新token失败，清除本地存储并跳转到登录页
        localStorage.removeItem('channel_access_token')
        localStorage.removeItem('channel_refresh_token')
        localStorage.removeItem('channel_info')
        window.location.href = '/channel/login'
        return Promise.reject(refreshError)
      }
    }
    
    return Promise.reject(error)
  }
)

// ===== 认证相关 =====

/**
 * 渠道商登录
 * @param {Object} loginData - 登录数据
 * @param {string} loginData.username - 用户名
 * @param {string} loginData.password - 密码
 */
export const channelLogin = (loginData) => {
  return channelClient.post('/api/v1/channel/auth/login', loginData)
}

/**
 * 获取当前渠道商信息
 */
export const getChannelInfo = () => {
  return channelClient.get('/api/v1/channel/auth/me')
}

/**
 * 刷新token
 * @param {string} refreshToken - 刷新令牌
 */
export const refreshChannelToken = (refreshToken) => {
  return channelClient.post('/api/v1/channel/auth/refresh', {
    refresh_token: refreshToken
  })
}

// ===== 学校管理 =====

/**
 * 获取渠道商负责的学校列表
 */
export const getChannelSchools = () => {
  return channelClient.get('/api/v1/channel/schools')
}

/**
 * 获取学校详情
 * @param {number} schoolId - 学校ID
 */
export const getSchoolDetail = (schoolId) => {
  return channelClient.get(`/api/v1/channel/schools/${schoolId}`)
}

/**
 * 获取学校的课程列表
 * @param {number} schoolId - 学校ID
 */
export const getSchoolCourses = (schoolId) => {
  return channelClient.get(`/api/v1/channel/schools/${schoolId}/courses`)
}

// ===== 课程查看 =====

/**
 * 获取课程详情（只读）
 * @param {string} courseUuid - 课程UUID
 */
export const getCourseDetail = (courseUuid) => {
  return channelClient.get(`/api/v1/channel/courses/${courseUuid}`)
}

/**
 * 获取课程学习进度（只读）
 * @param {string} courseUuid - 课程UUID
 */
export const getCourseProgress = (courseUuid) => {
  return channelClient.get(`/api/v1/channel/courses/${courseUuid}/progress`)
}

/**
 * 获取课程作业统计（只读）
 * @param {string} courseUuid - 课程UUID
 */
export const getCourseHomework = (courseUuid) => {
  return channelClient.get(`/api/v1/channel/courses/${courseUuid}/homework`)
}

export default {
  channelLogin,
  getChannelInfo,
  refreshChannelToken,
  getChannelSchools,
  getSchoolDetail,
  getSchoolCourses,
  getCourseDetail,
  getCourseProgress,
  getCourseHomework
}
