<template>
  <router-view v-if="authStore.isInitialized" />
  <div v-else style="display: flex; align-items: center; justify-content: center; height: 100vh;">
    <div style="text-align: center;">
      <div style="font-size: 20px; color: #666;">正在加载...</div>
    </div>
  </div>
</template>

<script setup>
import { watch } from 'vue'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

// 监听初始化完成后刷新用户信息
watch(() => authStore.isInitialized, async (initialized) => {
  if (initialized && authStore.isAuthenticated) {
    await authStore.refreshUserInfo()
  }
})
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html, body, #app {
  height: 100%;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 
    'Helvetica Neue', Arial, 'Noto Sans', sans-serif, 
    'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol';
}

#app {
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

/* 全局滚动条样式 */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: #f1f1f1;
}

::-webkit-scrollbar-thumb {
  background: #888;
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: #555;
}

/* Element Plus 样式覆盖 */
.el-button + .el-button {
  margin-left: 12px;
}
</style>
