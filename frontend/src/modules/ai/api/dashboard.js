/**
 * AI模块Dashboard统计API
 */
import request from '@/utils/request'

/**
 * 获取AI模块统计数据
 */
export function getAIStats() {
  return request({
    url: '/ai/dashboard/stats',
    method: 'get'
  })
}

