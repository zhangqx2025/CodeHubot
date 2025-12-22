/**
 * 单元知识库API
 * 用于检索单元相关知识，支持RAG（检索增强生成）
 */
import request from '@/utils/request'

/**
 * 检索单元知识库
 * @param {string} unitUuid - 单元UUID
 * @param {string} query - 搜索关键词
 * @param {number} limit - 返回结果数量
 * @returns {Promise}
 */
export function searchUnitKnowledge(unitUuid, query, limit = 5) {
  return request({
    url: `/pbl/knowledge/units/${unitUuid}/search`,
    method: 'get',
    params: { query, limit }
  })
}

/**
 * 记录知识点使用
 * @param {Object} data - 使用数据
 * @param {string} data.knowledge_uuid - 知识点UUID
 * @param {string} data.message_uuid - 消息UUID
 * @param {number} data.session_id - 会话ID
 * @param {string} data.query_text - 查询文本
 * @param {number} data.relevance_score - 相关度评分
 * @returns {Promise}
 */
export function logKnowledgeUsage(data) {
  return request({
    url: '/pbl/knowledge/usage-log',
    method: 'post',
    data
  })
}

/**
 * 获取单元热门知识点
 * @param {string} unitUuid - 单元UUID
 * @param {number} limit - 返回数量
 * @returns {Promise}
 */
export function getPopularKnowledge(unitUuid, limit = 10) {
  return request({
    url: `/pbl/knowledge/units/${unitUuid}/popular`,
    method: 'get',
    params: { limit }
  })
}

/**
 * 获取单元知识库分类统计
 * @param {string} unitUuid - 单元UUID
 * @returns {Promise}
 */
export function getKnowledgeCategories(unitUuid) {
  return request({
    url: `/pbl/knowledge/units/${unitUuid}/categories`,
    method: 'get'
  })
}

/**
 * 获取知识点详情
 * @param {string} knowledgeUuid - 知识点UUID
 * @returns {Promise}
 */
export function getKnowledgeDetail(knowledgeUuid) {
  return request({
    url: `/pbl/knowledge/knowledge/${knowledgeUuid}`,
    method: 'get'
  })
}

/**
 * 创建知识点（管理员）
 * @param {Object} data - 知识点数据
 * @returns {Promise}
 */
export function createKnowledge(data) {
  return request({
    url: '/pbl/knowledge/knowledge',
    method: 'post',
    data
  })
}

/**
 * 更新知识点（管理员）
 * @param {string} knowledgeUuid - 知识点UUID
 * @param {Object} data - 更新数据
 * @returns {Promise}
 */
export function updateKnowledge(knowledgeUuid, data) {
  return request({
    url: `/pbl/knowledge/knowledge/${knowledgeUuid}`,
    method: 'put',
    data
  })
}

