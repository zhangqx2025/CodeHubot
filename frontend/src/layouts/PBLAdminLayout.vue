<template>
  <el-container class="pbl-layout pbl-admin-layout">
    <el-aside width="240px" class="layout-aside">
      <div class="logo-container">
        <el-icon :size="28"><User /></el-icon>
        <span class="logo-text">PBL管理平台</span>
      </div>
      
      <el-menu
        :default-active="activeMenu"
        :router="true"
        class="layout-menu"
      >
        <el-menu-item index="/pbl/admin/dashboard">
          <el-icon><DataAnalysis /></el-icon>
          <span>管理控制台</span>
        </el-menu-item>
        
        <el-menu-item index="/pbl/admin/courses">
          <el-icon><Reading /></el-icon>
          <span>课程管理</span>
        </el-menu-item>
        
        <el-menu-item index="/pbl/admin/templates">
          <el-icon><Document /></el-icon>
          <span>课程模板</span>
        </el-menu-item>
        
        <el-menu-item index="/pbl/admin/users">
          <el-icon><User /></el-icon>
          <span>用户管理</span>
        </el-menu-item>
        
        <el-menu-item index="/pbl/admin/schools">
          <el-icon><School /></el-icon>
          <span>学校管理</span>
        </el-menu-item>
        
        <el-menu-item index="/pbl/admin/analytics">
          <el-icon><TrendCharts /></el-icon>
          <span>数据统计</span>
        </el-menu-item>
      </el-menu>
    </el-aside>
    
    <el-container>
      <el-header class="layout-header">
        <div class="header-left">
          <el-breadcrumb separator="/">
            <el-breadcrumb-item :to="{ path: '/' }">首页</el-breadcrumb-item>
            <el-breadcrumb-item>PBL管理平台</el-breadcrumb-item>
          </el-breadcrumb>
        </div>
        
        <div class="header-right">
          <el-button text @click="backToPortal">
            <el-icon><Grid /></el-icon> 切换系统
          </el-button>
          
          <el-dropdown @command="handleCommand">
            <span class="user-dropdown">
              <el-avatar :size="32" :style="{ background: '#ff9a9e' }">
                {{ authStore.userName.charAt(0) }}
              </el-avatar>
              <span class="user-name">{{ authStore.userName }}</span>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="profile">个人中心</el-dropdown-item>
                <el-dropdown-item command="settings">系统设置</el-dropdown-item>
                <el-dropdown-item divided command="logout">退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>
      
      <el-main class="layout-main">
        <router-view v-slot="{ Component }">
          <transition name="fade-transform" mode="out-in">
            <component :is="Component" />
          </transition>
        </router-view>
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  User, DataAnalysis, Reading, Document, School, TrendCharts, Grid
} from '@element-plus/icons-vue'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const activeMenu = computed(() => route.path)

function backToPortal() {
  router.push('/')
}

function handleCommand(command) {
  switch (command) {
    case 'profile':
      ElMessage.info('个人中心功能开发中')
      break
    case 'settings':
      ElMessage.info('系统设置功能开发中')
      break
    case 'logout':
      ElMessageBox.confirm('确定要退出登录吗？', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        authStore.logout()
        router.push('/login')
        ElMessage.success('已退出登录')
      })
      break
  }
}
</script>

<style scoped lang="scss">
.pbl-admin-layout {
  height: 100vh;
}

.layout-aside {
  background: linear-gradient(180deg, #ff9a9e 0%, #fecfef 100%);
  
  .logo-container {
    height: 60px;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 12px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.3);
    color: white;
    
    .logo-text {
      font-size: 18px;
      font-weight: 600;
    }
  }
  
  .layout-menu {
    border: none;
    background: transparent;
    
    :deep(.el-menu-item) {
      color: white;
      
      &:hover {
        background: rgba(255, 255, 255, 0.2);
      }
      
      &.is-active {
        background: rgba(255, 255, 255, 0.3);
        font-weight: 600;
      }
    }
  }
}

.layout-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: white;
  border-bottom: 1px solid #f0f0f0;
  padding: 0 20px;
  
  .header-right {
    display: flex;
    align-items: center;
    gap: 20px;
    
    .user-dropdown {
      display: flex;
      align-items: center;
      gap: 10px;
      cursor: pointer;
      
      .user-name {
        font-size: 14px;
        color: #2c3e50;
      }
      
      &:hover .user-name {
        color: #ff9a9e;
      }
    }
  }
}

.layout-main {
  background: #f5f7fa;
  padding: 20px;
}

.fade-transform-leave-active,
.fade-transform-enter-active {
  transition: all 0.3s;
}

.fade-transform-enter-from {
  opacity: 0;
  transform: translateX(-30px);
}

.fade-transform-leave-to {
  opacity: 0;
  transform: translateX(30px);
}
</style>
