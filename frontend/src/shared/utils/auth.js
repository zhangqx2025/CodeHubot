/**
 * 统一的认证工具
 * 处理token存储、用户信息管理、权限判断等
 */

/**
 * 获取访问令牌
 */
export function getToken() {
  return localStorage.getItem('access_token')
}

/**
 * 设置访问令牌
 */
export function setToken(token) {
  localStorage.setItem('access_token', token)
}

/**
 * 移除访问令牌
 */
export function removeToken() {
  localStorage.removeItem('access_token')
}

/**
 * 获取刷新令牌
 */
export function getRefreshToken() {
  return localStorage.getItem('refresh_token')
}

/**
 * 设置刷新令牌
 */
export function setRefreshToken(token) {
  localStorage.setItem('refresh_token', token)
}

/**
 * 获取用户信息
 */
export function getUserInfo() {
  const userInfoStr = localStorage.getItem('userInfo')
  return userInfoStr ? JSON.parse(userInfoStr) : null
}

/**
 * 设置用户信息
 */
export function setUserInfo(userInfo) {
  localStorage.setItem('userInfo', JSON.stringify(userInfo))
}

/**
 * 移除用户信息
 */
export function removeUserInfo() {
  localStorage.removeItem('userInfo')
}

/**
 * 清除所有认证信息
 */
export function clearAuth() {
  removeToken()
  localStorage.removeItem('refresh_token')
  removeUserInfo()
  // 清除PBL管理端相关token
  localStorage.removeItem('admin_access_token')
  localStorage.removeItem('admin_refresh_token')
  localStorage.removeItem('admin_info')
}

/**
 * 检查是否已登录
 */
export function isAuthenticated() {
  return !!getToken()
}

/**
 * 获取用户角色
 */
export function getUserRole() {
  const userInfo = getUserInfo()
  return userInfo?.role || ''
}

/**
 * 检查用户是否有指定角色
 * @param {string|string[]} roles - 角色或角色数组
 */
export function hasRole(roles) {
  const userRole = getUserRole()
  if (!userRole) return false
  
  if (Array.isArray(roles)) {
    return roles.includes(userRole)
  }
  return userRole === roles
}

/**
 * 检查是否是学生
 */
export function isStudent() {
  return getUserRole() === 'student'
}

/**
 * 检查是否是教师
 */
export function isTeacher() {
  return getUserRole() === 'teacher'
}

/**
 * 检查是否是管理员
 */
export function isAdmin() {
  const role = getUserRole()
  return role === 'admin' || role === 'super_admin' || role === 'school_admin'
}

/**
 * 检查是否可以访问Device系统
 */
export function canAccessDevice() {
  // Device系统对所有登录用户开放
  return isAuthenticated()
}

/**
 * 检查是否可以访问PBL学生端
 */
export function canAccessPBLStudent() {
  return isStudent()
}

/**
 * 检查是否可以访问PBL教师端
 */
export function canAccessPBLTeacher() {
  return isTeacher()
}

/**
 * 检查是否可以访问PBL管理端
 */
export function canAccessPBLAdmin() {
  return isAdmin()
}
