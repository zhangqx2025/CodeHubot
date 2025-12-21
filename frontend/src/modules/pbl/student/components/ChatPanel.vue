<template>
  <div class="chat-panel">
    <div class="chat-container">
      <!-- 聊天消息区域 -->
      <div class="messages-area" ref="messagesAreaRef">
        <div class="welcome-message" v-if="messages.length === 0">
          <div class="welcome-animation">
            <div class="ai-avatar-large">
              <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M12 2C6.48 2 2 6.48 2 12C2 17.52 6.48 22 12 22C17.52 22 22 17.52 22 12C22 6.48 17.52 2 12 2Z" fill="currentColor"/>
                <circle cx="8.5" cy="10.5" r="1.5" fill="white"/>
                <circle cx="15.5" cy="10.5" r="1.5" fill="white"/>
                <path d="M12 17C14.2091 17 16 15.2091 16 13H8C8 15.2091 9.79086 17 12 17Z" fill="white"/>
              </svg>
              <div class="sparkles">
                <span class="sparkle" v-for="i in 6" :key="i"></span>
              </div>
            </div>
          </div>
          <div class="welcome-content">
            <h3>👋 你好！我是你的AI学习伙伴</h3>
            <p class="intro-text">很高兴能帮助你更好地学习！</p>
            <div class="feature-grid">
              <div class="feature-item">
                <span class="feature-icon">🔍</span>
                <span class="feature-text">解答疑问</span>
              </div>
              <div class="feature-item">
                <span class="feature-icon">💡</span>
                <span class="feature-text">学习建议</span>
              </div>
              <div class="feature-item">
                <span class="feature-icon">🐛</span>
                <span class="feature-text">代码调试</span>
              </div>
              <div class="feature-item">
                <span class="feature-icon">📚</span>
                <span class="feature-text">资源推荐</span>
              </div>
            </div>
            <p class="cta-text">有什么问题尽管问我吧！</p>
          </div>
        </div>

        <transition-group name="message-list" tag="div">
          <div 
            v-for="message in messages" 
            :key="message.id"
            :class="['message', message.type]"
          >
            <div class="message-avatar">
              <svg v-if="message.type === 'ai'" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M12 2C6.48 2 2 6.48 2 12C2 17.52 6.48 22 12 22C17.52 22 22 17.52 22 12C22 6.48 17.52 2 12 2Z" fill="currentColor"/>
                <circle cx="8.5" cy="10.5" r="1.5" fill="white"/>
                <circle cx="15.5" cy="10.5" r="1.5" fill="white"/>
                <path d="M12 17C14.2091 17 16 15.2091 16 13H8C8 15.2091 9.79086 17 12 17Z" fill="white"/>
              </svg>
              <svg v-else viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M12 12C14.21 12 16 10.21 16 8C16 5.79 14.21 4 12 4C9.79 4 8 5.79 8 8C8 10.21 9.79 12 12 12ZM12 14C9.33 14 4 15.34 4 18V20H20V18C20 15.34 14.67 14 12 14Z" fill="currentColor"/>
              </svg>
            </div>
            <div class="message-content">
              <div class="message-text" v-html="formatMessage(message.content)"></div>
              <div class="message-footer">
                <span class="message-time">{{ formatTime(message.timestamp) }}</span>
                <div class="message-actions" v-if="message.type === 'ai'">
                  <button @click="copyMessage(message.content)" class="action-icon" title="复制">
                    <el-icon><DocumentCopy /></el-icon>
                  </button>
                  <button @click="likeMessage(message.id)" class="action-icon" :class="{ liked: message.liked }" title="有帮助">
                    <el-icon><Star /></el-icon>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </transition-group>

        <!-- 正在输入指示器 -->
        <transition name="fade">
          <div v-if="isTyping" class="message ai typing-indicator">
            <div class="message-avatar">
              <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M12 2C6.48 2 2 6.48 2 12C2 17.52 6.48 22 12 22C17.52 22 22 17.52 22 12C22 6.48 17.52 2 12 2Z" fill="currentColor"/>
                <circle cx="8.5" cy="10.5" r="1.5" fill="white"/>
                <circle cx="15.5" cy="10.5" r="1.5" fill="white"/>
                <path d="M12 17C14.2091 17 16 15.2091 16 13H8C8 15.2091 9.79086 17 12 17Z" fill="white"/>
              </svg>
            </div>
            <div class="message-content">
              <div class="typing-text">AI正在思考</div>
              <div class="typing-dots">
                <span></span>
                <span></span>
                <span></span>
              </div>
            </div>
          </div>
        </transition>
      </div>

      <!-- 快捷问题 -->
      <transition name="slide-fade">
        <div class="quick-questions" v-if="messages.length === 0 && !quickQuestionsHidden">
          <div class="quick-header">
            <h4>💬 快速开始</h4>
            <button @click="hideQuickQuestions" class="close-quick-btn" title="关闭">
              <el-icon><Close /></el-icon>
            </button>
          </div>
          <div class="question-buttons">
            <button 
              v-for="question in quickQuestions" 
              :key="question.id"
              @click="askQuickQuestion(question.text)"
              class="question-btn"
            >
              <span class="question-icon">{{ question.icon }}</span>
              <span class="question-text">{{ question.text }}</span>
            </button>
          </div>
        </div>
      </transition>

      <!-- 输入区域 -->
      <div class="input-area">
        <div class="input-hint" v-if="showHint">
          <el-icon><InfoFilled /></el-icon>
          <span>按 Enter 发送，Shift+Enter 换行</span>
        </div>
        <div class="input-container">
          <textarea
            v-model="inputMessage"
            @keydown.enter.prevent="handleEnterKey"
            @focus="showHint = true"
            @blur="showHint = false"
            ref="messageInputRef"
            placeholder="输入你的问题，我会尽力帮助你..."
            class="message-input"
            rows="1"
            :disabled="isTyping"
          ></textarea>
          
          <div class="input-actions">
            <button 
              @click="sendMessage" 
              :disabled="!inputMessage.trim() || isTyping"
              class="action-btn send-btn"
              :class="{ active: inputMessage.trim() }"
            >
              <el-icon v-if="isTyping"><Loading /></el-icon>
              <el-icon v-else><Promotion /></el-icon>
            </button>
          </div>
        </div>
        <div class="input-footer">
          <span class="char-count" :class="{ warning: inputMessage.length > 450 }">
            {{ inputMessage.length }} / 500
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, nextTick, watch, onMounted, onBeforeUnmount } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { 
  DocumentCopy, 
  Star, 
  Promotion, 
  Loading,
  InfoFilled 
} from '@element-plus/icons-vue'
import {
  createChatSession,
  endChatSession,
  saveChatMessage,
  updateMessageFeedback,
  getDeviceType,
  getBrowserType
} from '../api/aiChat'

// ===== 存储键名 =====
const STORAGE_KEY_PREFIX = 'ai_chat_history_'

const messagesAreaRef = ref(null)
const messageInputRef = ref(null)

const isOnline = ref(true)
const isTyping = ref(false)
const inputMessage = ref('')
const showHint = ref(false)
const quickQuestionsHidden = ref(false)

const messages = ref([])

// ===== 服务器会话相关 =====
const serverSessionUuid = ref(null) // 服务器会话UUID
const syncEnabled = ref(true) // 是否启用服务器同步
const messageUuidMap = ref(new Map()) // 本地消息ID到服务器UUID的映射

// ===== Props =====
const props = defineProps({
  unitId: {
    type: String,
    default: ''
  },
  courseId: {
    type: String,
    default: ''
  },
  storageMode: {
    type: String,
    default: 'session', // 'none', 'session', 'local'
    validator: (value) => ['none', 'session', 'local'].includes(value)
  },
  enableServerSync: {
    type: Boolean,
    default: true // 默认启用服务器同步
  }
})

const quickQuestions = ref([
  { id: 1, text: '这个单元的学习重点', icon: '🎯' },
  { id: 2, text: '如何完成当前任务', icon: '✅' },
  { id: 3, text: '推荐相关学习资源', icon: '📚' },
  { id: 4, text: '解释一个概念', icon: '💡' }
])

// ===== 存储相关方法 =====
const getStorageKey = () => {
  return `${STORAGE_KEY_PREFIX}${props.unitId || 'default'}`
}

const getStorage = () => {
  if (props.storageMode === 'local') return localStorage
  if (props.storageMode === 'session') return sessionStorage
  return null
}

const saveMessages = () => {
  const storage = getStorage()
  if (!storage) return
  
  try {
    const data = {
      messages: messages.value,
      timestamp: Date.now(),
      unitId: props.unitId
    }
    storage.setItem(getStorageKey(), JSON.stringify(data))
  } catch (error) {
    console.error('保存聊天记录失败:', error)
  }
}

const loadMessages = () => {
  const storage = getStorage()
  if (!storage) return
  
  try {
    const data = storage.getItem(getStorageKey())
    if (data) {
      const parsed = JSON.parse(data)
      // 检查是否是同一个单元的记录
      if (parsed.unitId === props.unitId) {
        messages.value = parsed.messages || []
        
        // 如果有历史记录，显示恢复提示
        if (messages.value.length > 0) {
          ElMessage({
            message: `已恢复 ${messages.value.length} 条对话记录`,
            type: 'success',
            duration: 2000
          })
        }
      }
    }
  } catch (error) {
    console.error('加载聊天记录失败:', error)
  }
}

const clearStorage = () => {
  const storage = getStorage()
  if (!storage) return
  
  try {
    storage.removeItem(getStorageKey())
  } catch (error) {
    console.error('清除聊天记录失败:', error)
  }
}

// ===== 服务器同步相关 =====

/**
 * 创建服务器会话
 */
const createServerSession = async () => {
  if (!props.enableServerSync || !props.unitId) return
  
  try {
    const sessionData = await createChatSession({
      unit_uuid: props.unitId,
      course_uuid: props.courseId,
      device_type: getDeviceType(),
      browser_type: getBrowserType()
    })
    
    serverSessionUuid.value = sessionData.uuid
    syncEnabled.value = true
    
    console.log('AI会话已创建:', serverSessionUuid.value)
  } catch (error) {
    console.error('创建AI会话失败:', error)
    syncEnabled.value = false
  }
}

/**
 * 同步消息到服务器
 */
const syncMessageToServer = async (message) => {
  if (!syncEnabled.value || !serverSessionUuid.value) return
  
  try {
    const messageData = await saveChatMessage({
      session_uuid: serverSessionUuid.value,
      message_type: message.type,
      content: message.content,
      sequence_number: messages.value.indexOf(message) + 1,
      category: categorizeMessage(message.content)
    })
    
    // 保存服务器UUID映射
    messageUuidMap.value.set(message.id, messageData.uuid)
  } catch (error) {
    console.error('同步消息到服务器失败:', error)
    // 不影响用户体验，静默失败
  }
}

/**
 * 更新服务器消息反馈
 */
const syncFeedbackToServer = async (messageId, isHelpful) => {
  if (!syncEnabled.value) return
  
  const serverUuid = messageUuidMap.value.get(messageId)
  if (!serverUuid) return
  
  try {
    await updateMessageFeedback(serverUuid, {
      is_helpful: isHelpful
    })
  } catch (error) {
    console.error('同步反馈失败:', error)
  }
}

/**
 * 结束服务器会话
 */
const endServerSession = async () => {
  if (!syncEnabled.value || !serverSessionUuid.value) return
  
  try {
    await endChatSession(serverSessionUuid.value)
    console.log('AI会话已结束')
  } catch (error) {
    console.error('结束AI会话失败:', error)
  }
}

/**
 * 简单的消息分类
 */
const categorizeMessage = (content) => {
  const lowerContent = content.toLowerCase()
  
  if (lowerContent.includes('重点') || lowerContent.includes('核心') || lowerContent.includes('概念')) {
    return 'concept'
  }
  if (lowerContent.includes('任务') || lowerContent.includes('作业') || lowerContent.includes('完成')) {
    return 'task'
  }
  if (lowerContent.includes('资源') || lowerContent.includes('资料') || lowerContent.includes('推荐')) {
    return 'resource'
  }
  if (lowerContent.includes('错误') || lowerContent.includes('bug') || lowerContent.includes('调试')) {
    return 'debug'
  }
  
  return 'other'
}

const formatMessage = (content) => {
  // 简单的Markdown格式化
  return content
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.*?)\*/g, '<em>$1</em>')
    .replace(/\n/g, '<br>')
}

const formatTime = (timestamp) => {
  const date = new Date(timestamp)
  return date.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })
}

const scrollToBottom = () => {
  nextTick(() => {
    if (messagesAreaRef.value) {
      messagesAreaRef.value.scrollTop = messagesAreaRef.value.scrollHeight
    }
  })
}

const sendMessage = async () => {
  if (!inputMessage.value.trim() || isTyping.value) return
  
  // 检查字符限制
  if (inputMessage.value.length > 500) {
    ElMessage.warning('消息长度不能超过500个字符')
    return
  }

  const userMessage = {
    id: Date.now(),
    type: 'user',
    content: inputMessage.value,
    timestamp: Date.now()
  }

  messages.value.push(userMessage)
  const message = inputMessage.value
  inputMessage.value = ''
  scrollToBottom()
  
  // 同步用户消息到服务器
  syncMessageToServer(userMessage)

  // 模拟AI回复
  isTyping.value = true
  const startTime = Date.now()
  
  // 随机延迟1-2秒，模拟真实思考时间
  const delay = 1000 + Math.random() * 1000
  await new Promise(resolve => setTimeout(resolve, delay))

  // 智能回复模拟
  const aiMessage = {
    id: Date.now() + 1,
    type: 'ai',
    content: generateAIResponse(message),
    timestamp: Date.now(),
    responseTime: Date.now() - startTime,
    liked: false
  }

  messages.value.push(aiMessage)
  isTyping.value = false
  scrollToBottom()
  
  // 同步AI回复到服务器
  syncMessageToServer(aiMessage)
}

const generateAIResponse = (question) => {
  // 简单的关键词匹配回复
  const lowerQuestion = question.toLowerCase()
  
  if (lowerQuestion.includes('重点') || lowerQuestion.includes('学习')) {
    return `关于"${question}"，让我为你详细解答：\n\n**本单元的学习重点包括：**\n1. 理解核心概念和原理\n2. 掌握实践操作技能\n3. 完成相关练习任务\n\n建议你按照单元规划的顺序，先学习理论知识，再进行实践操作。如果遇到困难，随时可以问我！`
  }
  
  if (lowerQuestion.includes('任务') || lowerQuestion.includes('作业')) {
    return `**关于任务完成建议：**\n\n✅ 仔细阅读任务要求\n✅ 理解评分标准\n✅ 分步骤完成任务\n✅ 及时保存进度\n\n需要我帮你解释具体的任务内容吗？`
  }
  
  if (lowerQuestion.includes('资源') || lowerQuestion.includes('推荐')) {
    return `**为你推荐以下学习资源：**\n\n📚 单元内的视频教程\n📝 配套的学习文档\n💻 实践项目案例\n🔗 扩展阅读链接\n\n你可以从单元目录中找到这些资源哦！`
  }
  
  // 默认回复
  return `关于"${question}"，这是一个很好的问题！\n\n我会尽力帮助你理解这个内容。**你可以：**\n\n• 查看单元中的相关资料\n• 完成配套的练习任务\n• 参考示例代码\n\n还有什么具体问题吗？我随时为你解答！`
}

const handleEnterKey = (event) => {
  if (event.shiftKey) {
    return // Shift+Enter 换行
  }
  sendMessage()
}

const askQuickQuestion = (question) => {
  inputMessage.value = question
  sendMessage()
}

const hideQuickQuestions = () => {
  quickQuestionsHidden.value = true
  // 保存到localStorage，下次不再显示
  try {
    localStorage.setItem('ai_chat_quick_questions_hidden', 'true')
    ElMessage.success('已隐藏快速开始区域')
  } catch (error) {
    console.error('保存设置失败:', error)
  }
}

const showClearConfirm = () => {
  ElMessageBox.confirm(
    '确定要清空所有对话记录吗？',
    '提示',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    }
  ).then(() => {
    messages.value = []
    ElMessage.success('对话已清空')
  }).catch(() => {
    // 用户取消
  })
}

const copyMessage = (content) => {
  // 移除HTML标签
  const text = content.replace(/<[^>]*>/g, '')
  navigator.clipboard.writeText(text).then(() => {
    ElMessage.success('已复制到剪贴板')
  }).catch(() => {
    ElMessage.error('复制失败')
  })
}

const likeMessage = (messageId) => {
  const message = messages.value.find(m => m.id === messageId)
  if (message) {
    message.liked = !message.liked
    ElMessage.success(message.liked ? '感谢你的反馈！' : '已取消')
    
    // 同步反馈到服务器
    syncFeedbackToServer(messageId, message.liked)
  }
}

watch(messages, () => {
  scrollToBottom()
  // 自动保存聊天记录
  if (props.storageMode !== 'none') {
    saveMessages()
  }
}, { deep: true })

// ===== 生命周期 =====
onMounted(async () => {
  // 加载历史记录
  loadMessages()
  
  // 加载快速问题隐藏状态
  try {
    const hidden = localStorage.getItem('ai_chat_quick_questions_hidden')
    quickQuestionsHidden.value = hidden === 'true'
  } catch (error) {
    console.error('加载设置失败:', error)
  }
  
  // 创建服务器会话
  if (props.enableServerSync && props.unitId) {
    await createServerSession()
  }
})

onBeforeUnmount(async () => {
  // 组件卸载前保存
  if (props.storageMode !== 'none' && messages.value.length > 0) {
    saveMessages()
  }
  
  // 结束服务器会话
  if (props.enableServerSync && serverSessionUuid.value) {
    await endServerSession()
  }
})

// ===== 暴露方法给父组件调用 =====
defineExpose({
  clearChat: () => {
    messages.value = []
    clearStorage()
    // 清空对话时，重新显示快速开始区域
    quickQuestionsHidden.value = false
    try {
      localStorage.removeItem('ai_chat_quick_questions_hidden')
    } catch (error) {
      console.error('清除设置失败:', error)
    }
  },
  saveChat: saveMessages,
  loadChat: loadMessages,
  getMessageCount: () => messages.value.length,
  getServerSessionUuid: () => serverSessionUuid.value,
  endSession: endServerSession
})
</script>

<style scoped lang="scss">
@use 'sass:math';

.chat-panel {
  display: flex;
  flex-direction: column;
  height: 100%;
  background: transparent;
  overflow: hidden;
}

.chat-container {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.messages-area {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
  background: linear-gradient(to bottom, #f8fafc 0%, #f1f5f9 100%);
  
  &::-webkit-scrollbar {
    width: 6px;
  }
  
  &::-webkit-scrollbar-track {
    background: transparent;
  }
  
  &::-webkit-scrollbar-thumb {
    background: rgba(148, 163, 184, 0.3);
    border-radius: 3px;
    
    &:hover {
      background: rgba(102, 126, 234, 0.5);
    }
  }
}

// ===== 欢迎消息 =====
.welcome-message {
  text-align: center;
  padding: 20px 0;
  animation: fade-in 0.6s ease;
}

.welcome-animation {
  position: relative;
  display: inline-block;
  margin-bottom: 24px;
}

.ai-avatar-large {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 8px 24px rgba(102, 126, 234, 0.3);
  animation: bounce-gentle 2s ease-in-out infinite;
  position: relative;
  z-index: 1;
  
  svg {
    width: 40px;
    height: 40px;
    color: white;
  }
}

.sparkles {
  position: absolute;
  width: 100%;
  height: 100%;
  
  .sparkle {
    position: absolute;
    width: 4px;
    height: 4px;
    background: linear-gradient(135deg, #fbbf24, #f59e0b);
    border-radius: 50%;
    animation: sparkle-float 3s ease-in-out infinite;
    
    @for $i from 1 through 6 {
      &:nth-child(#{$i}) {
        top: math.random() * 100%;
        left: math.random() * 100%;
        animation-delay: #{$i * 0.3}s;
      }
    }
  }
}

@keyframes sparkle-float {
  0%, 100% {
    transform: translateY(0) scale(0);
    opacity: 0;
  }
  50% {
    transform: translateY(-20px) scale(1);
    opacity: 1;
  }
}

@keyframes bounce-gentle {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-10px);
  }
}

.welcome-content {
  background: white;
  padding: 24px;
  border-radius: 16px;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
  
  h3 {
    margin: 0 0 8px 0;
    font-size: 18px;
    color: #1e293b;
    font-weight: 600;
  }
  
  .intro-text {
    color: #64748b;
    margin: 0 0 20px 0;
    font-size: 14px;
  }
  
  .cta-text {
    margin: 20px 0 0 0;
    color: #667eea;
    font-size: 14px;
    font-weight: 500;
  }
}

.feature-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
  margin: 16px 0;
}

.feature-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px;
  background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
  border-radius: 12px;
  transition: all 0.3s;
  
  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.15);
  }
  
  .feature-icon {
    font-size: 20px;
  }
  
  .feature-text {
    font-size: 13px;
    color: #475569;
    font-weight: 500;
  }
}

// ===== 消息样式 =====
.message {
  display: flex;
  gap: 12px;
  margin-bottom: 20px;
  animation: message-slide-in 0.3s ease;
  
  &.user {
    flex-direction: row-reverse;
  }
}

@keyframes message-slide-in {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.message-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  
  svg {
    width: 20px;
    height: 20px;
  }
}

.message.user .message-avatar {
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  color: white;
}

.message.ai .message-avatar {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.message-content {
  max-width: 75%;
  background: white;
  padding: 12px 16px;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  transition: all 0.2s;
  
  &:hover {
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.12);
  }
}

.message.user .message-content {
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  color: white;
  border-bottom-right-radius: 4px;
}

.message.ai .message-content {
  border-bottom-left-radius: 4px;
}

.message-text {
  color: #1e293b;
  line-height: 1.6;
  word-wrap: break-word;
  font-size: 14px;
  
  :deep(strong) {
    color: #667eea;
    font-weight: 600;
  }
  
  :deep(em) {
    color: #8b5cf6;
  }
}

.message.user .message-text {
  color: white;
  
  :deep(strong),
  :deep(em) {
    color: white;
  }
}

.message-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 8px;
  gap: 8px;
}

.message-time {
  font-size: 11px;
  color: #94a3b8;
}

.message.user .message-time {
  color: rgba(255, 255, 255, 0.8);
}

.message-actions {
  display: flex;
  gap: 4px;
  opacity: 0;
  transition: opacity 0.2s;
}

.message-content:hover .message-actions {
  opacity: 1;
}

.action-icon {
  width: 24px;
  height: 24px;
  border: none;
  background: transparent;
  color: #94a3b8;
  cursor: pointer;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
  padding: 0;
  
  &:hover {
    background: #f1f5f9;
    color: #667eea;
  }
  
  &.liked {
    color: #fbbf24;
  }
}

// ===== 输入中指示器 =====
.typing-indicator {
  opacity: 1;
}

.typing-text {
  font-size: 12px;
  color: #64748b;
  margin-bottom: 4px;
}

.typing-dots {
  display: flex;
  gap: 6px;
  padding: 4px 0;
  
  span {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: linear-gradient(135deg, #667eea, #764ba2);
    animation: typing-bounce 1.4s infinite ease-in-out;
    
    &:nth-child(1) {
      animation-delay: 0s;
    }
    
    &:nth-child(2) {
      animation-delay: 0.2s;
    }
    
    &:nth-child(3) {
      animation-delay: 0.4s;
    }
  }
}

@keyframes typing-bounce {
  0%, 60%, 100% {
    transform: translateY(0);
    opacity: 0.7;
  }
  30% {
    transform: translateY(-10px);
    opacity: 1;
  }
}

// ===== 快捷问题 =====
.quick-questions {
  padding: 16px 20px;
  background: white;
  border-top: 1px solid #e5e7eb;
}

.quick-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
  
  h4 {
    margin: 0;
    font-size: 13px;
    color: #64748b;
    font-weight: 500;
  }
}

.close-quick-btn {
  width: 20px;
  height: 20px;
  border: none;
  background: transparent;
  color: #94a3b8;
  cursor: pointer;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
  padding: 0;
  
  &:hover {
    background: #f1f5f9;
    color: #64748b;
  }
  
  &:active {
    transform: scale(0.9);
  }
}

.question-buttons {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 8px;
}

.question-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 12px;
  background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  font-size: 13px;
  color: #475569;
  cursor: pointer;
  transition: all 0.3s;
  text-align: left;
  
  &:hover {
    background: linear-gradient(135deg, #e0f2fe 0%, #dbeafe 100%);
    border-color: #93c5fd;
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(59, 130, 246, 0.15);
  }
  
  .question-icon {
    font-size: 16px;
  }
  
  .question-text {
    font-weight: 500;
    flex: 1;
  }
}

// ===== 输入区域 =====
.input-area {
  background: white;
  border-top: 1px solid #e5e7eb;
  padding: 16px 20px;
}

.input-hint {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #94a3b8;
  margin-bottom: 8px;
  animation: fade-in 0.3s ease;
}

.input-container {
  display: flex;
  gap: 8px;
  align-items: flex-end;
  background: #f8fafc;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  padding: 8px;
  transition: all 0.3s;
  
  &:focus-within {
    border-color: #667eea;
    background: white;
    box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
  }
}

.message-input {
  flex: 1;
  padding: 8px;
  border: none;
  background: transparent;
  font-size: 14px;
  resize: none;
  font-family: inherit;
  min-height: 36px;
  max-height: 120px;
  line-height: 1.5;
  color: #1e293b;
  
  &:focus {
    outline: none;
  }
  
  &::placeholder {
    color: #94a3b8;
  }
  
  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
}

.input-actions {
  display: flex;
  gap: 6px;
  align-items: center;
}

.action-btn {
  width: 36px;
  height: 36px;
  border: none;
  border-radius: 8px;
  background: #f1f5f9;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
  color: #64748b;
  
  &:hover:not(:disabled) {
    background: #e2e8f0;
    transform: scale(1.05);
  }
  
  &:active:not(:disabled) {
    transform: scale(0.95);
  }
  
  &:disabled {
    opacity: 0.4;
    cursor: not-allowed;
  }
}

.send-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  
  &:hover:not(:disabled) {
    background: linear-gradient(135deg, #5568d3 0%, #6a4291 100%);
    box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
  }
  
  &.active {
    animation: pulse-send 1.5s ease-in-out infinite;
  }
}

@keyframes pulse-send {
  0%, 100% {
    box-shadow: 0 0 0 0 rgba(102, 126, 234, 0.7);
  }
  50% {
    box-shadow: 0 0 0 8px rgba(102, 126, 234, 0);
  }
}

.input-footer {
  display: flex;
  justify-content: flex-end;
  margin-top: 8px;
}

.char-count {
  font-size: 11px;
  color: #94a3b8;
  
  &.warning {
    color: #f59e0b;
    font-weight: 500;
  }
}

// ===== 过渡动画 =====
.message-list-enter-active {
  animation: message-slide-in 0.3s ease;
}

.slide-fade-enter-active {
  transition: all 0.3s ease;
}

.slide-fade-leave-active {
  transition: all 0.2s ease;
}

.slide-fade-enter-from {
  transform: translateY(-10px);
  opacity: 0;
}

.slide-fade-leave-to {
  transform: translateY(10px);
  opacity: 0;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

@keyframes fade-in {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}
</style>

