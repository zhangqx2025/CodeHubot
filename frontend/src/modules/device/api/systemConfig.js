/**
 * 系统配置 API
 */
import request from '@/utils/request'

/**
 * 获取平台配置（公开接口）
 */
export function getPlatformConfig() {
  return request({
    url: '/system-config/platform',
    method: 'get'
  })
}

/**
 * 更新平台配置（仅平台管理员）
 */
export function updatePlatformConfig(data) {
  return request({
    url: '/system-config/platform',
    method: 'put',
    data
  })
}

/**
 * 获取模块配置（公开接口）
 */
export function getModuleConfig() {
  return request({
    url: '/system-config/modules',
    method: 'get'
  })
}

/**
 * 更新模块配置（仅平台管理员）
 */
export function updateModuleConfig(data) {
  return request({
    url: '/system-config/modules',
    method: 'put',
    data
  })
}

/**
 * 初始化系统配置（仅平台管理员）
 */
export function initSystemConfig() {
  return request({
    url: '/system-config/modules/init',
    method: 'post'
  })
}

/**
 * 获取所有系统配置（仅平台管理员）
 */
export function getAllConfigs(params) {
  return request({
    url: '/system-config/configs',
    method: 'get',
    params
  })
}

/**
 * 获取公开的系统配置
 */
export function getPublicConfigs() {
  return request({
    url: '/system-config/configs/public',
    method: 'get'
  })
}

/**
 * 获取协议配置（用户协议和隐私政策）- 公开接口
 */
export function getPoliciesConfig() {
  return request({
    url: '/system-config/policies',
    method: 'get'
  })
}

/**
 * 更新协议配置（用户协议和隐私政策）- 仅平台管理员
 */
export function updatePoliciesConfig(data) {
  return request({
    url: '/system-config/policies',
    method: 'put',
    data
  })
}
