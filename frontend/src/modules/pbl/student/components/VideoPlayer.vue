<template>
  <div class="video-player-container" :id="playerId" @click="handleVideoClick"></div>
</template>

<script setup>
import { onMounted, onBeforeUnmount, watch, nextTick, ref } from 'vue'
import { ElMessageBox } from 'element-plus'
import {
  createPlaySession,
  updatePlayProgress,
  recordSeekEvent,
  recordPauseEvent,
  recordEndEvent
} from '@pbl/student/api/video'

const props = defineProps({
  vid: {
    type: String,
    default: ''
  },
  playAuth: {
    type: String,
    default: ''
  },
  source: {
    type: String,
    default: ''
  },
  cover: {
    type: String,
    default: ''
  },
  width: {
    type: String,
    default: '100%'
  },
  height: {
    type: String,
    default: '500px'
  },
  autoplay: {
    type: Boolean,
    default: false
  },
  resourceUuid: {
    type: String,
    default: ''
  },
  enableTracking: {
    type: Boolean,
    default: true
  },
  autoPauseInterval: {
    type: Number,
    default: 180  // 默认3分钟（180秒）自动暂停，设为0则禁用
  }
})

const emit = defineEmits(['ready', 'play', 'pause', 'ended', 'error', 'session-created', 'auto-pause'])

const playerId = `aliplayer-${Math.random().toString(36).substr(2, 9)}`
let player = null

// 播放追踪相关状态
const sessionId = ref(null)
const lastPosition = ref(0)
const progressUpdateInterval = ref(null)
const isTracking = ref(props.enableTracking)

// 自动暂停相关状态
const continuousPlayTime = ref(0)  // 连续播放时间（秒）
const autoPauseTimer = ref(null)   // 自动暂停计时器

/**
 * 处理视频区域点击事件（暂停/播放）
 */
const handleVideoClick = (event) => {
  if (!player) return
  
  // 检查是否点击的是控制栏区域
  const target = event.target
  const isControlBar = target.closest('.prism-controlbar') || 
                       target.closest('.prism-big-play-btn') ||
                       target.classList.contains('prism-controlbar')
  
  // 如果不是点击控制栏，则切换播放/暂停状态
  if (!isControlBar) {
    try {
      const status = player.getStatus()
      if (status === 'playing') {
        player.pause()
      } else if (status === 'pause' || status === 'ready') {
        player.play()
      }
    } catch (error) {
      console.error('切换播放状态失败:', error)
    }
  }
}

const initPlayer = () => {
  // 销毁旧实例
  if (player) {
    cleanupTracking()
    player.dispose()
    player = null
  }

  // 确保容器存在
  const container = document.getElementById(playerId)
  if (!container) return

  // 初始化配置
  const options = {
    id: playerId,
    width: props.width,
    height: props.height,
    autoplay: props.autoplay,
    cover: props.cover,
    // 优先使用 vid + playAuth，否则使用 source
    vid: props.vid,
    playauth: props.playAuth,
    source: !props.vid ? props.source : undefined,
    // 其它常用配置
    isLive: false,
    rePlay: false,
    playsinline: true,
    preload: true,
    controlBarVisibility: 'hover',
    useH5Prism: true,
    // 语言设置为中文
    language: 'zh-cn',
    // 启用快捷键（空格暂停/播放，左右键快进快退）
    keyShortcut: true,
    // 启用倍速播放
    speedMode: 'web'
  }

  // 创建播放器实例
  // eslint-disable-next-line no-undef
  player = new Aliplayer(options, function (player) {
    console.log('播放器创建成功')
  })

  // 监听事件
  player.on('ready', () => {
    console.log('播放器准备就绪')
    emit('ready')
    
    // 检查是否有上次播放位置
    if (props.resourceUuid) {
      const savedPosition = getSavedPosition(props.resourceUuid)
      if (savedPosition > 5) {  // 大于5秒才提示续播
        showResumeDialog(savedPosition)
      }
    }
    
    // 如果启用了追踪且有资源UUID，创建播放会话
    if (isTracking.value && props.resourceUuid) {
      initPlaySession()
    }
  })

  player.on('play', () => {
    console.log('开始播放')
    emit('play')
    
    // 启动进度更新定时器
    if (isTracking.value && sessionId.value) {
      startProgressTracking()
    }
    
    // 启动自动暂停计时器
    if (props.autoPauseInterval > 0) {
      startAutoPauseTimer()
    }
  })

  player.on('pause', () => {
    console.log('暂停播放')
    emit('pause')
    
    // 停止进度更新定时器
    stopProgressTracking()
    
    // 停止自动暂停计时器
    stopAutoPauseTimer()
    
    // 记录暂停事件和保存播放位置
    if (player) {
      const currentPos = Math.floor(player.getCurrentTime())
      
      // 保存播放位置
      if (props.resourceUuid) {
        savePosition(props.resourceUuid, currentPos)
      }
      
      // 记录暂停事件到服务器
      if (isTracking.value && sessionId.value) {
        handlePauseEvent(currentPos)
      }
    }
  })

  player.on('ended', () => {
    console.log('播放结束')
    emit('ended')
    
    // 停止进度更新定时器
    stopProgressTracking()
    
    // 清除保存的播放位置（播放完成后）
    if (props.resourceUuid) {
      try {
        const key = `video_position_${props.resourceUuid}`
        sessionStorage.removeItem(key)
      } catch (error) {
        console.error('清除播放位置失败:', error)
      }
    }
    
    // 记录播放结束事件
    if (isTracking.value && sessionId.value && player) {
      const currentPos = Math.floor(player.getCurrentTime())
      handleEndEvent(currentPos)
    }
  })

  // 监听拖动事件
  player.on('seeked', () => {
    if (isTracking.value && sessionId.value && player) {
      const currentPos = Math.floor(player.getCurrentTime())
      handleSeekEvent(lastPosition.value, currentPos)
      lastPosition.value = currentPos
    }
  })

  // 监听时间更新事件
  player.on('timeupdate', () => {
    if (player) {
      const currentTime = Math.floor(player.getCurrentTime())
      lastPosition.value = currentTime
      
      // 每30秒自动保存一次播放位置（防止异常关闭丢失进度）
      if (props.resourceUuid && currentTime % 30 === 0 && currentTime > 0) {
        savePosition(props.resourceUuid, currentTime)
      }
    }
  })
  
  // 监听错误事件
  player.on('error', (error) => {
    console.error('播放器错误:', error)
    emit('error', error)
  })
}

/**
 * 获取保存的播放位置
 */
const getSavedPosition = (resourceUuid) => {
  try {
    const key = `video_position_${resourceUuid}`
    const saved = sessionStorage.getItem(key)
    return saved ? parseInt(saved) : 0
  } catch (error) {
    return 0
  }
}

/**
 * 保存播放位置
 */
const savePosition = (resourceUuid, position) => {
  try {
    const key = `video_position_${resourceUuid}`
    sessionStorage.setItem(key, position.toString())
  } catch (error) {
    console.error('保存播放位置失败:', error)
  }
}

/**
 * 显示续播提示对话框
 */
const showResumeDialog = async (savedPosition) => {
  if (!player) return
  
  // 暂停播放器，等待用户选择
  player.pause()
  
  // 格式化时间显示
  const formatTime = (seconds) => {
    const minutes = Math.floor(seconds / 60)
    const secs = seconds % 60
    return `${minutes}分${secs}秒`
  }
  
  try {
    await ElMessageBox.confirm(
      `检测到上次观看到 ${formatTime(savedPosition)}，是否继续播放？`,
      '💡 视频续播',
      {
        confirmButtonText: '继续播放',
        cancelButtonText: '从头播放',
        distinguishCancelAndClose: true,
        type: 'info',
        center: true,
        closeOnClickModal: false
      }
    )
    
    // 用户选择继续播放
    console.log('用户选择继续播放，跳转到:', savedPosition, '秒')
    player.seek(savedPosition)
    if (props.autoplay) {
      player.play()
    }
  } catch (action) {
    // 用户选择从头播放或关闭对话框
    if (action === 'cancel') {
      console.log('用户选择从头播放')
      // 清除保存的位置
      if (props.resourceUuid) {
        try {
          const key = `video_position_${props.resourceUuid}`
          sessionStorage.removeItem(key)
        } catch (error) {
          console.error('清除播放位置失败:', error)
        }
      }
      // 从头播放
      player.seek(0)
      if (props.autoplay) {
        player.play()
      }
    } else {
      // 用户点击了关闭按钮（X），默认从头播放
      console.log('用户关闭对话框，从头播放')
      player.seek(0)
      if (props.autoplay) {
        player.play()
      }
    }
  }
}

// ========== 播放追踪功能 ==========

/**
 * 初始化播放会话
 */
const initPlaySession = async () => {
  if (!props.resourceUuid || !player) return
  
  try {
    const duration = Math.floor(player.getDuration() || 0)
    if (duration === 0) {
      // 如果还没有获取到时长，等待一段时间后重试
      setTimeout(initPlaySession, 1000)
      return
    }
    
    const deviceType = getDeviceType()
    const res = await createPlaySession(props.resourceUuid, duration, deviceType)
    
    if (res.code === 200 && res.data) {
      sessionId.value = res.data.session_id
      console.log('播放会话创建成功:', sessionId.value)
      emit('session-created', sessionId.value)
    }
  } catch (error) {
    console.error('创建播放会话失败:', error)
  }
}

/**
 * 启动进度追踪
 */
const startProgressTracking = () => {
  // 清除之前的定时器
  stopProgressTracking()
  
  // 每10秒上报一次进度
  progressUpdateInterval.value = setInterval(() => {
    updateProgress()
  }, 10000)
}

/**
 * 停止进度追踪
 */
const stopProgressTracking = () => {
  if (progressUpdateInterval.value) {
    clearInterval(progressUpdateInterval.value)
    progressUpdateInterval.value = null
  }
}

/**
 * 更新播放进度
 */
const updateProgress = async () => {
  if (!sessionId.value || !player) return
  
  try {
    const currentPos = Math.floor(player.getCurrentTime())
    const isPaused = player.paused()
    const status = isPaused ? 'paused' : 'playing'
    
    // 保存播放位置到本地（用于续播）
    if (props.resourceUuid && currentPos > 0) {
      savePosition(props.resourceUuid, currentPos)
    }
    
    await updatePlayProgress(sessionId.value, currentPos, status, 'progress')
  } catch (error) {
    console.error('更新播放进度失败:', error)
  }
}

/**
 * 处理拖动事件
 */
const handleSeekEvent = async (fromPos, toPos) => {
  if (!sessionId.value) return
  
  try {
    await recordSeekEvent(sessionId.value, fromPos, toPos)
    console.log('记录拖动事件:', fromPos, '->', toPos)
  } catch (error) {
    console.error('记录拖动事件失败:', error)
  }
}

/**
 * 处理暂停事件
 */
const handlePauseEvent = async (position) => {
  if (!sessionId.value) return
  
  try {
    await recordPauseEvent(sessionId.value, position)
    console.log('记录暂停事件:', position)
  } catch (error) {
    console.error('记录暂停事件失败:', error)
  }
}

/**
 * 处理播放结束事件
 */
const handleEndEvent = async (position) => {
  if (!sessionId.value) return
  
  try {
    await recordEndEvent(sessionId.value, position)
    console.log('记录播放结束事件:', position)
  } catch (error) {
    console.error('记录播放结束事件失败:', error)
  }
}

/**
 * 清理追踪资源
 */
const cleanupTracking = () => {
  stopProgressTracking()
  sessionId.value = null
  lastPosition.value = 0
}

// ========== 自动暂停功能 ==========

/**
 * 启动自动暂停计时器
 */
const startAutoPauseTimer = () => {
  // 清除之前的计时器
  stopAutoPauseTimer()
  
  // 每秒递增连续播放时间
  autoPauseTimer.value = setInterval(() => {
    continuousPlayTime.value++
    
    // 检查是否达到自动暂停时间
    if (continuousPlayTime.value >= props.autoPauseInterval) {
      handleAutoPause()
    }
  }, 1000)
}

/**
 * 停止自动暂停计时器
 */
const stopAutoPauseTimer = () => {
  if (autoPauseTimer.value) {
    clearInterval(autoPauseTimer.value)
    autoPauseTimer.value = null
  }
  // 重置连续播放时间
  continuousPlayTime.value = 0
}

/**
 * 处理自动暂停
 */
const handleAutoPause = () => {
  if (!player) return
  
  // 停止计时器
  stopAutoPauseTimer()
  
  // 暂停播放
  player.pause()
  
  // 显示提示信息
  console.log('已连续播放3分钟，自动暂停')
  
  // 触发自定义事件，由父组件决定如何显示提示
  emit('auto-pause', {
    playTime: props.autoPauseInterval,
    currentPosition: player.getCurrentTime()
  })
}

/**
 * 获取设备类型
 */
const getDeviceType = () => {
  const ua = navigator.userAgent
  if (/(tablet|ipad|playbook|silk)|(android(?!.*mobi))/i.test(ua)) {
    return 'Tablet'
  }
  if (/Mobile|Android|iP(hone|od)|IEMobile|BlackBerry|Kindle|Silk-Accelerated|(hpw|web)OS|Opera M(obi|ini)/.test(ua)) {
    return 'Mobile'
  }
  return 'PC'
}

onMounted(() => {
  nextTick(() => {
    if (window.Aliplayer) {
      initPlayer()
    } else {
      // 如果脚本还没加载完，轮询检查
      const checkInterval = setInterval(() => {
        if (window.Aliplayer) {
          clearInterval(checkInterval)
          initPlayer()
        }
      }, 100)
    }
  })
})

onBeforeUnmount(() => {
  // 保存当前播放位置（组件卸载前）
  if (player && props.resourceUuid) {
    const currentPos = Math.floor(player.getCurrentTime())
    if (currentPos > 0) {
      savePosition(props.resourceUuid, currentPos)
      console.log('组件卸载，保存播放位置:', currentPos)
    }
  }
  
  // 清理追踪资源
  cleanupTracking()
  
  // 清理自动暂停计时器
  stopAutoPauseTimer()
  
  // 销毁播放器
  if (player) {
    player.dispose()
    player = null
  }
})

// 监听属性变化，重新初始化或更新播放器
watch(() => [props.vid, props.source], () => {
  nextTick(() => {
    initPlayer()
  })
})

// 暴露方法给父组件
defineExpose({
  // 播放控制
  play: () => player?.play(),
  pause: () => player?.pause(),
  seek: (time) => player?.seek(time),
  // 获取播放器状态
  getCurrentTime: () => player?.getCurrentTime() || 0,
  getDuration: () => player?.getDuration() || 0,
  getStatus: () => player?.getStatus(),
  // 获取会话ID
  getSessionId: () => sessionId.value
})
</script>

<style scoped>
.video-player-container {
  width: 100%;
  height: 100%;
  background-color: #000;
  cursor: pointer;
  position: relative;
}

/* 确保视频元素也显示指针 */
.video-player-container :deep(video) {
  cursor: pointer;
}

/* 控制栏区域保持默认光标 */
.video-player-container :deep(.prism-controlbar) {
  cursor: default;
}

.video-player-container :deep(.prism-controlbar *) {
  cursor: pointer;
}
</style>

