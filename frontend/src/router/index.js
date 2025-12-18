/**
 * 统一路由配置
 * 整合Device和PBL所有路由
 */
import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { ElMessage } from 'element-plus'

// 导入路由模块
import deviceRoutes from './device'
import pblRoutes from './pbl'
import aiRoutes from './ai'

const routes = [
  // 登录页
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/Login.vue'),
    meta: { title: '登录', public: true }
  },
  
  // 门户页（系统选择）
  {
    path: '/',
    name: 'Portal',
    component: () => import('@/views/Portal.vue'),
    meta: { title: '系统门户', requiresAuth: true }
  },
  
  // Device系统路由
  ...deviceRoutes,
  
  // PBL系统路由
  ...pblRoutes,
  
  // AI系统路由
  ...aiRoutes,
  
  // 404页面
  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: () => import('@/views/NotFound.vue'),
    meta: { title: '页面不存在' }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) {
      return savedPosition
    } else {
      return { top: 0 }
    }
  }
})

// 全局前置守卫
router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()
  
  // 设置页面标题
  document.title = to.meta.title ? `${to.meta.title} - CodeHubot` : 'CodeHubot'
  
  // 公开页面直接放行
  if (to.meta.public) {
    // 检查实际的token，而不仅仅是store状态
    const hasToken = localStorage.getItem('access_token') || 
                     localStorage.getItem('admin_access_token') || 
                     localStorage.getItem('student_access_token')
    
    // 如果有token且访问登录页，跳转到门户
    if (to.path === '/login' && hasToken && authStore.isAuthenticated) {
      next('/')
      return
    }
    next()
    return
  }
  
  // 检查是否需要认证
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    ElMessage.warning('请先登录')
    next({
      path: '/login',
      query: { redirect: to.fullPath }
    })
    return
  }
  
  // 检查角色权限
  if (to.meta.roles) {
    const userRole = authStore.userRole
    if (!to.meta.roles.includes(userRole)) {
      ElMessage.error('没有权限访问该页面')
      next('/')
      return
    }
  }
  
  // 检查平台管理员权限
  if (to.meta.requiresPlatformAdmin) {
    const userRole = authStore.userInfo?.role
    if (userRole !== 'platform_admin') {
      ElMessage.error('只有平台管理员可以访问该页面')
      next('/')
      return
    }
  }
  
  // 检查教师或管理员权限
  if (to.meta.requiresTeacherOrAdmin) {
    const userRole = authStore.userInfo?.role
    if (!['platform_admin', 'school_admin', 'teacher'].includes(userRole)) {
      ElMessage.error('只有教师或管理员可以访问该页面')
      next('/')
      return
    }
  }
  
  next()
})

// 全局后置钩子
router.afterEach((to, from) => {
  // 可以在这里添加页面访问统计等逻辑
})

export default router
