// 教师端API
import axios from 'axios'

// 在生产模式下使用空字符串（相对路径），通过 nginx proxy 转发
// 在开发模式下使用 localhost，方便本地开发
const API_BASE = import.meta.env.VITE_API_BASE || (import.meta.env.MODE === 'production' ? '' : 'http://localhost:8000')

// 创建axios实例（教师端）
const teacherClient = axios.create({
  baseURL: API_BASE,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// 请求拦截器
teacherClient.interceptors.request.use(
  (config) => {
    // 从localStorage获取教师token
    const token = localStorage.getItem('teacher_access_token')
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
teacherClient.interceptors.response.use(
  (response) => {
    return response
  },
  async (error) => {
    const originalRequest = error.config
    
    // 如果是401错误且不是刷新token的请求，尝试刷新token
    if (error.response?.status === 401 && !originalRequest._retry && !originalRequest.url.includes('/auth/refresh')) {
      originalRequest._retry = true
      
      try {
        const refreshToken = localStorage.getItem('teacher_refresh_token')
        if (refreshToken) {
          const response = await teacherClient.post('/api/v1/teacher/auth/refresh', {
            refresh_token: refreshToken
          })
          
          const { access_token, refresh_token: newRefreshToken } = response.data.data || response.data
          
          // 更新token
          localStorage.setItem('teacher_access_token', access_token)
          if (newRefreshToken) {
            localStorage.setItem('teacher_refresh_token', newRefreshToken)
          }
          
          // 重新发送原请求
          originalRequest.headers.Authorization = `Bearer ${access_token}`
          return teacherClient(originalRequest)
        }
      } catch (refreshError) {
        // 刷新token失败，清除本地存储并跳转到登录页
        localStorage.removeItem('teacher_access_token')
        localStorage.removeItem('teacher_refresh_token')
        localStorage.removeItem('teacher_info')
        window.location.href = '/teacher/login'
        return Promise.reject(refreshError)
      }
    }
    
    return Promise.reject(error)
  }
)

// ===== 认证相关 =====

/**
 * 教师登录
 * @param {Object} loginData - 登录数据
 * @param {string} loginData.school_code - 学校代码
 * @param {string} loginData.number - 教师工号
 * @param {string} loginData.password - 密码
 */
export const teacherLogin = (loginData) => {
  return teacherClient.post('/api/v1/teacher/auth/login', loginData)
}

/**
 * 获取当前教师信息
 */
export const getTeacherInfo = () => {
  return teacherClient.get('/api/v1/teacher/auth/me')
}

/**
 * 刷新token
 * @param {string} refreshToken - 刷新令牌
 */
export const refreshTeacherToken = (refreshToken) => {
  return teacherClient.post('/api/v1/teacher/auth/refresh', {
    refresh_token: refreshToken
  })
}

/**
 * 修改密码
 * @param {Object} passwordData - 密码数据
 * @param {string} passwordData.old_password - 旧密码
 * @param {string} passwordData.new_password - 新密码
 */
export const changePassword = (passwordData) => {
  return teacherClient.post('/api/v1/teacher/auth/change-password', passwordData)
}

/**
 * 更新个人信息
 * @param {Object} profileData - 个人信息数据
 * @param {string} profileData.name - 姓名
 * @param {string} profileData.phone - 电话
 * @param {string} profileData.subject - 科目
 */
export const updateProfile = (profileData) => {
  return teacherClient.put('/api/v1/teacher/auth/profile', profileData)
}

// ===== 课程管理 =====

/**
 * 获取教师负责的课程列表
 */
export const getTeacherCourses = () => {
  return teacherClient.get('/api/v1/teacher/courses')
}

/**
 * 获取课程详情
 * @param {string} courseUuid - 课程UUID
 */
export const getTeacherCourseDetail = (courseUuid) => {
  return teacherClient.get(`/api/v1/teacher/courses/${courseUuid}`)
}

// ===== 分组管理 =====

/**
 * 获取课程的所有小组
 * @param {string} courseUuid - 课程UUID
 */
export const getCourseGroups = (courseUuid) => {
  return teacherClient.get(`/api/v1/teacher/courses/${courseUuid}/groups`)
}

/**
 * 创建小组
 * @param {string} courseUuid - 课程UUID
 * @param {Object} groupData - 小组数据
 * @param {string} groupData.name - 小组名称
 * @param {string} groupData.description - 小组描述
 * @param {number} groupData.max_members - 最大成员数
 */
export const createGroup = (courseUuid, groupData) => {
  return teacherClient.post(`/api/v1/teacher/courses/${courseUuid}/groups`, groupData)
}

/**
 * 更新小组信息
 * @param {string} courseUuid - 课程UUID
 * @param {number} groupId - 小组ID
 * @param {Object} groupData - 小组数据
 */
export const updateGroup = (courseUuid, groupId, groupData) => {
  return teacherClient.put(`/api/v1/teacher/courses/${courseUuid}/groups/${groupId}`, groupData)
}

/**
 * 删除小组
 * @param {string} courseUuid - 课程UUID
 * @param {number} groupId - 小组ID
 */
export const deleteGroup = (courseUuid, groupId) => {
  return teacherClient.delete(`/api/v1/teacher/courses/${courseUuid}/groups/${groupId}`)
}

/**
 * 添加小组成员
 * @param {string} courseUuid - 课程UUID
 * @param {number} groupId - 小组ID
 * @param {Array<number>} userIds - 用户ID列表
 */
export const addGroupMembers = (courseUuid, groupId, userIds) => {
  return teacherClient.post(`/api/v1/teacher/courses/${courseUuid}/groups/${groupId}/members`, {
    user_ids: userIds
  })
}

/**
 * 移除小组成员
 * @param {string} courseUuid - 课程UUID
 * @param {number} groupId - 小组ID
 * @param {number} userId - 用户ID
 */
export const removeGroupMember = (courseUuid, groupId, userId) => {
  return teacherClient.delete(`/api/v1/teacher/courses/${courseUuid}/groups/${groupId}/members/${userId}`)
}

// ===== 班级成员 =====

/**
 * 获取班级成员列表
 * @param {string} courseUuid - 课程UUID
 */
export const getClassMembers = (courseUuid) => {
  return teacherClient.get(`/api/v1/teacher/courses/${courseUuid}/members`)
}

// ===== 单元管理 =====

/**
 * 获取课程的所有单元列表
 * @param {string} courseUuid - 课程UUID
 */
export const getCourseUnits = (courseUuid) => {
  return teacherClient.get(`/api/v1/teacher/courses/${courseUuid}/units`)
}

// ===== 学习进度 =====

/**
 * 获取单元的学习进度
 * @param {string} courseUuid - 课程UUID
 * @param {number} unitId - 单元ID
 */
export const getUnitProgress = (courseUuid, unitId) => {
  return teacherClient.get(`/api/v1/teacher/courses/${courseUuid}/units/${unitId}/progress`)
}

/**
 * 获取课程学习进度（已废弃）
 * @param {string} courseUuid - 课程UUID
 */
export const getCourseProgress = (courseUuid) => {
  return teacherClient.get(`/api/v1/teacher/courses/${courseUuid}/progress`)
}

// ===== 作业管理 =====

/**
 * 获取单元的作业提交情况
 * @param {string} courseUuid - 课程UUID
 * @param {number} unitId - 单元ID
 */
export const getUnitHomework = (courseUuid, unitId) => {
  return teacherClient.get(`/api/v1/teacher/courses/${courseUuid}/units/${unitId}/homework`)
}

/**
 * 获取课程作业列表
 * @param {string} courseUuid - 课程UUID
 * @param {Object} params - 查询参数
 * @param {number} params.unit_id - 单元ID（可选）
 * @param {string} params.status - 状态（可选）
 */
export const getCourseHomework = (courseUuid, params = {}) => {
  return teacherClient.get(`/api/v1/teacher/courses/${courseUuid}/homework`, { params })
}

/**
 * 获取作业提交列表
 * @param {number} taskId - 任务ID
 */
export const getHomeworkSubmissions = (taskId) => {
  return teacherClient.get(`/api/v1/teacher/homework/${taskId}/submissions`)
}

/**
 * 批改作业
 * @param {number} progressId - 提交记录ID
 * @param {Object} gradeData - 批改数据
 * @param {number} gradeData.score - 分数
 * @param {string} gradeData.feedback - 反馈
 */
export const gradeHomework = (progressId, gradeData) => {
  return teacherClient.put(`/api/v1/teacher/homework/${progressId}/grade`, gradeData)
}

export default {
  teacherLogin,
  getTeacherInfo,
  refreshTeacherToken,
  changePassword,
  updateProfile,
  getTeacherCourses,
  getTeacherCourseDetail,
  getCourseGroups,
  createGroup,
  updateGroup,
  deleteGroup,
  addGroupMembers,
  removeGroupMember,
  getCourseProgress,
  getCourseHomework,
  getHomeworkSubmissions,
  gradeHomework
}
