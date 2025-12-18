import axios from 'axios'
import { ElMessage } from 'element-plus'
import { getToken, getRefreshToken, clearAuth } from '@shared/utils/auth'
import logger from '../utils/logger'

// 创建axios实例
// 使用环境变量配置 API 地址，如果没有配置则使用默认值
const baseURL = import.meta.env.VITE_API_BASE_URL || '/api'
const timeout = import.meta.env.VITE_API_TIMEOUT ? parseInt(import.meta.env.VITE_API_TIMEOUT) : 30000 // 默认30秒

const request = axios.create({
  baseURL,
  timeout
})

// 验证token格式
const isValidTokenFormat = (token) => {
  if (!token) return false
  const parts = token.split('.')
  return parts.length === 3
}

// 解析JWT token获取过期时间
const getTokenExpiry = (token) => {
  try {
    const payload = JSON.parse(atob(token.split('.')[1]))
    return payload.exp * 1000 // 转换为毫秒
  } catch (error) {
    return null
  }
}

// 检查token是否即将过期（5分钟内）
const isTokenExpiringSoon = (token) => {
  const expiry = getTokenExpiry(token)
  if (!expiry) return false
  return Date.now() > expiry - 5 * 60 * 1000
}

// 检查token是否已过期
const isTokenExpired = (token) => {
  const expiry = getTokenExpiry(token)
  if (!expiry) return false
  return Date.now() > expiry
}

// 存储正在等待的请求队列（当token正在刷新时）
let isRefreshing = false
let failedQueue = []

const processQueue = (error, token = null) => {
  failedQueue.forEach(item => {
    if (error) {
      item.reject(error)
    } else {
      // 更新等待请求的Authorization头
      if (item.config) {
        item.config.headers.Authorization = `Bearer ${token}`
      }
      item.resolve(token)
    }
  })
  failedQueue = []
}

// 刷新token的函数（在请求拦截器中使用）
const refreshTokenInInterceptor = async (refreshToken) => {
  try {
    logger.info('🔄 [请求拦截器] 检测到token已过期，主动刷新token')
    const response = await axios.post(`${baseURL}/auth/refresh`, {
      refresh_token: refreshToken
    })
    
    const newToken = response.data?.access_token || response.data?.data?.access_token
    if (newToken) {
      // 保存新token
      localStorage.setItem('access_token', newToken)
      if (response.data?.refresh_token || response.data?.data?.refresh_token) {
        localStorage.setItem('refresh_token', response.data?.refresh_token || response.data?.data?.refresh_token)
      }
      logger.info('✅ [请求拦截器] Token刷新成功')
      return newToken
    } else {
      throw new Error('Token刷新失败：未返回新token')
    }
  } catch (err) {
    logger.error('❌ [请求拦截器] Token刷新失败:', err.message)
    throw err
  }
}

// 请求拦截器
request.interceptors.request.use(
  async config => {
    const token = getToken()
    
    // 如果是 FormData，删除手动设置的 Content-Type，让浏览器自动设置（包括 boundary）
    if (config.data instanceof FormData) {
      delete config.headers['Content-Type']
    }
    
    logger.api(config.method, config.url, config.data)
    
    if (token) {
      // 先检查token格式
      if (!isValidTokenFormat(token)) {
        logger.error('Token格式无效，清除并登出')
        clearAuth()
        ElMessage.error('登录信息无效，请重新登录')
        
        if (window.location.pathname !== '/login') {
          window.location.href = '/login'
        }
        return Promise.reject(new Error('Token format invalid'))
      }
      
      // 检查token是否已过期
      if (isTokenExpired(token)) {
        logger.warn('⚠️ Access Token已过期')
        const refreshToken = getRefreshToken()
        
        // 如果 refresh token 也过期了或不存在，直接登出
        if (!refreshToken) {
          logger.error('❌ Refresh Token不存在，执行登出')
          clearAuth()
          ElMessage.error('登录已过期，请重新登录')
          if (window.location.pathname !== '/login') {
            window.location.href = '/login'
          }
          return Promise.reject(new Error('Refresh token not found'))
        }
        
        if (isTokenExpired(refreshToken)) {
          logger.error('❌ Refresh Token也已过期，执行登出')
          clearAuth()
          ElMessage.error('登录已过期，请重新登录')
          if (window.location.pathname !== '/login') {
            window.location.href = '/login'
          }
          return Promise.reject(new Error('Refresh token expired'))
        }
        
        // refresh token 还有效，主动刷新token
        logger.warn('🔄 Access Token已过期，Refresh Token有效，主动刷新token')
        
        // 如果正在刷新，将请求加入队列
        if (isRefreshing) {
          logger.debug('Token刷新中，请求加入队列等待')
          return new Promise((resolve, reject) => {
            failedQueue.push({ 
              resolve, 
              reject,
              config
            })
          }).then(newToken => {
            config.headers.Authorization = `Bearer ${newToken}`
            return config
          }).catch(err => {
            return Promise.reject(err)
          })
        }
        
        // 开始刷新token
        isRefreshing = true
        
        try {
          const newToken = await refreshTokenInInterceptor(refreshToken)
          
          // 处理等待队列中的所有请求
          processQueue(null, newToken)
          
          // 更新当前请求的token
          config.headers.Authorization = `Bearer ${newToken}`
        } catch (err) {
          // 刷新失败，处理等待队列并登出
          processQueue(err, null)
          clearAuth()
          ElMessage.error('登录已过期，请重新登录')
          
          if (window.location.pathname !== '/login') {
            window.location.href = '/login'
          }
          return Promise.reject(err)
        } finally {
          isRefreshing = false
        }
      } else if (isTokenExpiringSoon(token)) {
        logger.warn('⚠️ Token即将过期（5分钟内），建议尽快刷新')
      }
      
      // 添加 Authorization header
      config.headers.Authorization = `Bearer ${token}`
      logger.debug('已添加Authorization头')
    } else {
      logger.debug('未找到token，匿名请求')
    }
    return config
  },
  error => {
    logger.error('API请求拦截器错误:', error)
    return Promise.reject(error)
  }
)

// 响应拦截器
request.interceptors.response.use(
  response => {
    logger.apiResponse(response.status, response.config.url, response.data)
    
    // 统一响应格式处理：如果响应包含 code 字段，提取 data 字段
    if (response.data && typeof response.data === 'object' && 'code' in response.data) {
      // 标准响应格式：{ code, message, data }
      if (response.data.code === 200) {
        // 成功响应，将 data 字段提升到顶层，保持向后兼容
        response.data = response.data.data
      } else {
        // 非 200 的 code，可能是业务错误，保持原格式
        // 这种情况通常不应该发生（HTTP 200 但 code 非 200），但为了兼容性保留
      }
    }
    
    return response
  },
  async error => {
    const originalRequest = error.config
    const status = error.response?.status
    const url = originalRequest?.url
    
    logger.error('API响应错误:', {
      url,
      status,
      message: error.message
    })
    
    // 处理401错误 - token失效，需要重新登录
    if (status === 401) {
      // 如果是refresh端点失败或已经重试过，直接登出
      if (url?.includes('/auth/refresh') || originalRequest._retry) {
        logger.error('认证失败，执行登出')
        clearAuth()
        ElMessage.error('登录已过期，请重新登录')
        
        if (window.location.pathname !== '/login') {
          window.location.href = '/login'
        }
        return Promise.reject(error)
      }
      
      // 标记此请求已重试过
      originalRequest._retry = true
      
      // 尝试使用refresh token刷新
      const refreshToken = getRefreshToken()
      if (!refreshToken) {
        logger.error('没有refresh token，执行登出')
        clearAuth()
        ElMessage.error('登录已过期，请重新登录')
        
        if (window.location.pathname !== '/login') {
          window.location.href = '/login'
        }
        return Promise.reject(error)
      }
      
      // 如果正在刷新token，将请求加入队列
      if (isRefreshing) {
        logger.debug('Token刷新中，请求加入队列等待')
        return new Promise((resolve, reject) => {
          failedQueue.push({ 
            resolve, 
            reject,
            config: originalRequest
          })
        }).then(token => {
          originalRequest.headers.Authorization = `Bearer ${token}`
          return request(originalRequest)
        }).catch(err => {
          return Promise.reject(err)
        })
      }
      
      // 开始刷新token
      isRefreshing = true
      
      try {
        logger.info('🔄 检测到401错误，尝试刷新token')
        const response = await axios.post(`${baseURL}/auth/refresh`, {
          refresh_token: refreshToken
        })
        
        const newToken = response.data?.access_token || response.data?.data?.access_token
        if (newToken) {
          // 保存新token
          localStorage.setItem('access_token', newToken)
          if (response.data?.refresh_token || response.data?.data?.refresh_token) {
            localStorage.setItem('refresh_token', response.data?.refresh_token || response.data?.data?.refresh_token)
          }
          
          // 刷新成功，更新请求头并处理队列
          logger.info('✅ Token刷新成功，重试原请求')
          originalRequest.headers.Authorization = `Bearer ${newToken}`
          
          // 处理等待队列中的所有请求
          processQueue(null, newToken)
          
          // 重试原请求
          return request(originalRequest)
        } else {
          throw new Error('Token刷新失败')
        }
      } catch (err) {
        logger.error('Token刷新失败，执行登出')
        // 处理等待队列，通知所有等待的请求刷新失败
        processQueue(err, null)
        
        // 执行登出
        clearAuth()
        ElMessage.error('登录已过期，请重新登录')
        
        if (window.location.pathname !== '/login') {
          window.location.href = '/login'
        }
        return Promise.reject(err)
      } finally {
        isRefreshing = false
      }
    } else if (error.message === 'Token expired') {
      logger.warn('Token过期错误')
      // 不在这里登出，让响应拦截器的401处理逻辑来处理
      return Promise.reject(error)
    } else if (status >= 500) {
      ElMessage.error('服务器错误，请稍后重试')
    } else if (status >= 400) {
      // 统一错误响应格式处理
      const errorData = error.response?.data
      let errorMessage = '请求失败'
      
      if (errorData) {
        // 标准错误格式：{ code, message, detail }
        if (typeof errorData === 'object' && 'message' in errorData) {
          errorMessage = errorData.message || errorData.detail || '请求失败'
        } else if (typeof errorData === 'string') {
          errorMessage = errorData
        } else if (errorData.detail) {
          errorMessage = errorData.detail
        }
      }
      
      // 对于注册接口，不在这里显示错误，让 store 中的错误处理来处理
      // 这样可以避免注册成功但显示错误的问题
      if (!url?.includes('/auth/register')) {
        ElMessage.error(errorMessage)
      }
    }
    
    return Promise.reject(error)
  }
)

export default request
