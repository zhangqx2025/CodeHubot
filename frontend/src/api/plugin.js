import request from './request'

// 插件管理API

// 创建新插件
export const createPlugin = (data) => {
  return request({
    url: '/plugins',
    method: 'post',
    data
  })
}

// 获取插件列表
export const getPlugins = (params) => {
  return request({
    url: '/plugins',
    method: 'get',
    params
  })
}

// 获取单个插件详情
export const getPlugin = (id) => {
  return request({
    url: `/plugins/${id}`,
    method: 'get'
  })
}

// 更新插件信息
export const updatePlugin = (id, data) => {
  return request({
    url: `/plugins/${id}`,
    method: 'put',
    data
  })
}

// 删除插件
export const deletePlugin = (id) => {
  return request({
    url: `/plugins/${id}`,
    method: 'delete'
  })
}

