/**
 * 学校用户管理API
 */
import request from '@/utils/request'
import { handleApiError } from './config'

/**
 * 获取用户列表
 */
export const getUserList = async (params = {}) => {
  try {
    const response = await request.get('/pbl/admin/users/list', { params })
    return response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 创建用户
 */
export const createUser = async (userData) => {
  try {
    const response = await request.post('/pbl/admin/users', userData)
    return response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 更新用户
 */
export const updateUser = async (userId, userData) => {
  try {
    const response = await request.put(`/pbl/admin/users/${userId}`, userData)
    return response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 重置用户密码
 */
export const resetUserPassword = async (userId, newPassword) => {
  try {
    const response = await request.post(`/pbl/admin/users/${userId}/reset-password`, {
      new_password: newPassword
    })
    return response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 获取学校统计数据
 */
export const getSchoolStatistics = async (schoolId) => {
  try {
    const response = await request.get(`/pbl/admin/schools/${schoolId}/statistics`)
    return response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 获取班级列表（用于用户关联）
 */
export const getClassesForUser = async () => {
  try {
    const response = await request.get('/pbl/admin/classes-groups/classes')
    return response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 批量导入学生
 */
export const batchImportStudents = async (formData) => {
  try {
    const response = await request.post('/pbl/admin/users/batch-import/students', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })
    return response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

/**
 * 批量导入教师
 */
export const batchImportTeachers = async (formData) => {
  try {
    const response = await request.post('/pbl/admin/users/batch-import/teachers', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })
    return response.data
  } catch (error) {
    throw new Error(handleApiError(error))
  }
}

