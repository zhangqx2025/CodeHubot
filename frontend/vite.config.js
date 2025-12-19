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
          // 其他第三方库统一打包（避免过度分割导致循环依赖）
          if (id.includes('node_modules')) {
            return 'vendor'
          }
          // 业务模块不再强制分割，由 Vite 自动处理
          // 这样可以避免模块间循环依赖导致的初始化错误
        }
      }
    }
  }
})
