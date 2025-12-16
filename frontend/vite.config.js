import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

export default defineConfig({
  plugins: [vue()],
  base: '/',
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
      '@device': resolve(__dirname, 'src/modules/device'),
      '@ai': resolve(__dirname, 'src/modules/ai'),
      '@pbl': resolve(__dirname, 'src/modules/pbl'),
      '@shared': resolve(__dirname, 'src/shared')
    }
  },
  css: {
    preprocessorOptions: {
      scss: {
        api: 'modern-compiler' // 使用新的 Sass API，避免弃用警告
      }
    }
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true
      }
    }
  },
  build: {
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true
      }
    },
    rollupOptions: {
      output: {
        manualChunks(id) {
          // Element Plus 单独打包
          if (id.includes('node_modules/element-plus')) {
            return 'element-plus'
          }
          // Element Plus 图标单独打包
          if (id.includes('node_modules/@element-plus/icons-vue')) {
            return 'element-icons'
          }
          // Vue 核心库单独打包
          if (id.includes('node_modules/vue/') || 
              id.includes('node_modules/@vue/') ||
              id.includes('node_modules/vue-router/') || 
              id.includes('node_modules/pinia/')) {
            return 'vue-vendor'
          }
          // Device模块
          if (id.includes('/src/modules/device/')) {
            return 'module-device'
          }
          // AI模块
          if (id.includes('/src/modules/ai/')) {
            return 'module-ai'
          }
          // PBL学生模块
          if (id.includes('/src/modules/pbl/student/')) {
            return 'module-pbl-student'
          }
          // PBL教师模块
          if (id.includes('/src/modules/pbl/teacher/')) {
            return 'module-pbl-teacher'
          }
          // PBL管理模块
          if (id.includes('/src/modules/pbl/admin/')) {
            return 'module-pbl-admin'
          }
          // 其他第三方库
          if (id.includes('node_modules')) {
            return 'vendor'
          }
        }
      }
    }
  }
})
