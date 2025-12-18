<template>
  <div id="app">
    <!-- Token监控组件 -->
    <TokenMonitor />
    
    <router-view v-slot="{ Component, route }">
      <transition name="fade" mode="out-in">
        <component :is="Component" :key="route.path" />
      </transition>
    </router-view>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useUserStore } from './store/user'
import TokenMonitor from './components/TokenMonitor.vue'

const userStore = useUserStore()

onMounted(() => {
  // 检查用户登录状态
  userStore.checkAuth()
})
</script>

<style>
html, body, #app {
  min-height: 100vh;
  height: auto;
  margin: 0;
  padding: 0;
  overflow-x: hidden;
  overflow-y: auto;
}

#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  color: #2c3e50;
  /* 让内容根据页面自然滚动，不强制固定 */
}

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

/* 让顶层容器在页面中自适应填满视口高度 */
.el-container {
  min-height: 100vh;
}

/* 路由过渡动画 */
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.fade-enter-from, .fade-leave-to {
  opacity: 0;
}

/* 移除错误的高度强制设置，使用 Element Plus 自身的布局 */
/* .el-aside, .el-main, .el-header {
  height: 100vh !important;
} */
</style>
