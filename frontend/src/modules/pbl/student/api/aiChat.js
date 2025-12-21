/**
 * AI对话记录API
 * 用于保存和同步学生与AI的对话记录到服务器
 */
import request from '@/utils/request'

/**
 * ===== 会话管理 =====
 */

/**
 * 创建AI对话会话
 * @param {Object} data - 会话数据
 * @param {string} data.unit_uuid - 单元UUID
 * @param {string} data.course_uuid - 课程UUID
 * @param {string} data.device_type - 设备类型
 * @param {string} data.browser_type - 浏览器类型
 * @returns {Promise}
 */
export function createChatSession(data) {
  return request({
    url: '/api/pbl/ai-chat/sessions',
    method: 'post',
    data
  })
}

/**
 * 获取会话详情
 * @param {string} sessionUuid - 会话UUID
 * @returns {Promise}
 */
export function getChatSession(sessionUuid) {
  return request({
    url: `/api/pbl/ai-chat/sessions/${sessionUuid}`,
    method: 'get'
  })
}

/**
 * 结束对话会话
 * @param {string} sessionUuid - 会话UUID
 * @returns {Promise}
 */
export function endChatSession(sessionUuid) {
  return request({
    url: `/api/pbl/ai-chat/sessions/${sessionUuid}/end`,
    method: 'put'
  })
}

/**
 * ===== 消息管理 =====
 */

/**
 * 保存单条对话消息
 * @param {Object} data - 消息数据
 * @param {string} data.session_uuid - 会话UUID
 * @param {string} data.message_type - 消息类型: user, ai, system
 * @param {string} data.content - 消息内容
 * @param {number} data.sequence_number - 消息序号
 * @param {string} data.ai_model - AI模型名称（可选）
 * @param {string} data.category - 问题分类（可选）
 * @returns {Promise}
 */
export function saveChatMessage(data) {
  return request({
    url: '/api/pbl/ai-chat/messages',
    method: 'post',
    data
  })
}

/**
 * 批量保存对话消息
 * @param {Object} data - 批量数据
 * @param {string} data.session_uuid - 会话UUID
 * @param {Array} data.messages - 消息列表
 * @returns {Promise}
 */
export function saveChatMessagesBatch(data) {
  return request({
    url: '/api/pbl/ai-chat/messages/batch',
    method: 'post',
    data
  })
}

/**
 * 更新消息反馈（点赞）
 * @param {string} messageUuid - 消息UUID
 * @param {Object} data - 更新数据
 * @param {boolean} data.is_helpful - 是否有帮助
 * @returns {Promise}
 */
export function updateMessageFeedback(messageUuid, data) {
  return request({
    url: `/api/pbl/ai-chat/messages/${messageUuid}/feedback`,
    method: 'put',
    data
  })
}

/**
 * 获取会话的所有消息
 * @param {string} sessionUuid - 会话UUID
 * @returns {Promise}
 */
export function getSessionMessages(sessionUuid) {
  return request({
    url: `/api/pbl/ai-chat/messages/session/${sessionUuid}`,
    method: 'get'
  })
}

/**
 * ===== 统计分析 =====
 */

/**
 * 获取学生对话统计
 * @param {number} userId - 用户ID
 * @returns {Promise}
 */
export function getStudentChatStats(userId) {
  return request({
    url: `/api/pbl/ai-chat/stats/student/${userId}`,
    method: 'get'
  })
}

/**
 * 获取单元热门问题
 * @param {string} unitUuid - 单元UUID
 * @param {number} limit - 返回数量限制
 * @returns {Promise}
 */
export function getUnitPopularQuestions(unitUuid, limit = 10) {
  return request({
    url: `/api/pbl/ai-chat/stats/unit/${unitUuid}/popular-questions`,
    method: 'get',
    params: { limit }
  })
}

/**
 * 获取对话分析总览
 * @param {Object} params - 查询参数
 * @param {string} params.start_date - 开始日期
 * @param {string} params.end_date - 结束日期
 * @param {string} params.unit_uuid - 单元UUID
 * @returns {Promise}
 */
export function getChatAnalytics(params) {
  return request({
    url: '/api/pbl/ai-chat/analytics/overview',
    method: 'get',
    params
  })
}

/**
 * ===== 工具函数 =====
 */

/**
 * 获取设备类型
 * @returns {string}
 */
export function getDeviceType() {
  const ua = navigator.userAgent
  if (/mobile/i.test(ua)) return 'mobile'
  if (/tablet|ipad/i.test(ua)) return 'tablet'
  return 'desktop'
}

/**
 * 获取浏览器类型
 * @returns {string}
 */
export function getBrowserType() {
  const ua = navigator.userAgent
  if (ua.indexOf('Chrome') > -1) return 'Chrome'
  if (ua.indexOf('Safari') > -1) return 'Safari'
  if (ua.indexOf('Firefox') > -1) return 'Firefox'
  if (ua.indexOf('Edge') > -1) return 'Edge'
  return 'Unknown'
}
