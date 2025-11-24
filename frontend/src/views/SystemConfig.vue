<template>
  <div class="system-config-container">
    <div class="page-header">
      <h2>系统配置</h2>
      <div class="header-actions">
        <el-button type="primary" @click="saveAllConfig">
          <el-icon><Check /></el-icon>
          保存所有配置
        </el-button>
      </div>
    </div>

    <el-row :gutter="20">
      <!-- 基础配置 -->
      <el-col :span="12">
        <el-card class="config-card">
          <template #header>
            <div class="card-header">
              <span>基础配置</span>
              <el-button size="small" @click="saveBasicConfig">保存</el-button>
            </div>
          </template>
          <el-form :model="basicConfig" label-width="120px">
            <el-form-item label="系统名称">
              <el-input v-model="basicConfig.systemName" placeholder="请输入系统名称" />
            </el-form-item>
            <el-form-item label="系统版本">
              <el-input v-model="basicConfig.systemVersion" placeholder="请输入系统版本" />
            </el-form-item>
            <el-form-item label="公司名称">
              <el-input v-model="basicConfig.companyName" placeholder="请输入公司名称" />
            </el-form-item>
            <el-form-item label="联系邮箱">
              <el-input v-model="basicConfig.contactEmail" placeholder="请输入联系邮箱" />
            </el-form-item>
            <el-form-item label="系统描述">
              <el-input v-model="basicConfig.description" type="textarea" :rows="3" placeholder="请输入系统描述" />
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>

      <!-- 安全配置 -->
      <el-col :span="12">
        <el-card class="config-card">
          <template #header>
            <div class="card-header">
              <span>安全配置</span>
              <el-button size="small" @click="saveSecurityConfig">保存</el-button>
            </div>
          </template>
          <el-form :model="securityConfig" label-width="120px">
            <el-form-item label="会话超时">
              <el-input-number v-model="securityConfig.sessionTimeout" :min="1" :max="1440" />
              <span class="unit">分钟</span>
            </el-form-item>
            <el-form-item label="密码最小长度">
              <el-input-number v-model="securityConfig.passwordMinLength" :min="6" :max="20" />
            </el-form-item>
            <el-form-item label="登录失败锁定">
              <el-switch v-model="securityConfig.loginLockEnabled" />
            </el-form-item>
            <el-form-item label="最大失败次数">
              <el-input-number v-model="securityConfig.maxLoginAttempts" :min="3" :max="10" :disabled="!securityConfig.loginLockEnabled" />
            </el-form-item>
            <el-form-item label="锁定时间">
              <el-input-number v-model="securityConfig.lockDuration" :min="5" :max="60" :disabled="!securityConfig.loginLockEnabled" />
              <span class="unit">分钟</span>
            </el-form-item>
            <el-form-item label="强制HTTPS">
              <el-switch v-model="securityConfig.forceHttps" />
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20" style="margin-top: 20px;">
      <!-- 邮件配置 -->
      <el-col :span="12">
        <el-card class="config-card">
          <template #header>
            <div class="card-header">
              <span>邮件配置</span>
              <div>
                <el-button size="small" @click="testEmail">测试</el-button>
                <el-button size="small" @click="saveEmailConfig">保存</el-button>
              </div>
            </div>
          </template>
          <el-form :model="emailConfig" label-width="120px">
            <el-form-item label="SMTP服务器">
              <el-input v-model="emailConfig.smtpHost" placeholder="请输入SMTP服务器地址" />
            </el-form-item>
            <el-form-item label="SMTP端口">
              <el-input-number v-model="emailConfig.smtpPort" :min="1" :max="65535" />
            </el-form-item>
            <el-form-item label="发送邮箱">
              <el-input v-model="emailConfig.fromEmail" placeholder="请输入发送邮箱" />
            </el-form-item>
            <el-form-item label="邮箱密码">
              <el-input v-model="emailConfig.password" type="password" placeholder="请输入邮箱密码" show-password />
            </el-form-item>
            <el-form-item label="启用SSL">
              <el-switch v-model="emailConfig.useSSL" />
            </el-form-item>
            <el-form-item label="启用TLS">
              <el-switch v-model="emailConfig.useTLS" />
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>

      <!-- 数据库配置 -->
      <el-col :span="12">
        <el-card class="config-card">
          <template #header>
            <div class="card-header">
              <span>数据库配置</span>
              <div>
                <el-button size="small" @click="testDatabase">测试连接</el-button>
                <el-button size="small" @click="saveDatabaseConfig">保存</el-button>
              </div>
            </div>
          </template>
          <el-form :model="databaseConfig" label-width="120px">
            <el-form-item label="数据库类型">
              <el-select v-model="databaseConfig.type" placeholder="请选择数据库类型">
                <el-option label="MySQL" value="mysql" />
                <el-option label="PostgreSQL" value="postgresql" />
                <el-option label="SQLite" value="sqlite" />
              </el-select>
            </el-form-item>
            <el-form-item label="服务器地址">
              <el-input v-model="databaseConfig.host" placeholder="请输入服务器地址" />
            </el-form-item>
            <el-form-item label="端口">
              <el-input-number v-model="databaseConfig.port" :min="1" :max="65535" />
            </el-form-item>
            <el-form-item label="数据库名">
              <el-input v-model="databaseConfig.database" placeholder="请输入数据库名" />
            </el-form-item>
            <el-form-item label="用户名">
              <el-input v-model="databaseConfig.username" placeholder="请输入用户名" />
            </el-form-item>
            <el-form-item label="密码">
              <el-input v-model="databaseConfig.password" type="password" placeholder="请输入密码" show-password />
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20" style="margin-top: 20px;">
      <!-- 告警配置 -->
      <el-col :span="12">
        <el-card class="config-card">
          <template #header>
            <div class="card-header">
              <span>告警配置</span>
              <el-button size="small" @click="saveAlertConfig">保存</el-button>
            </div>
          </template>
          <el-form :model="alertConfig" label-width="120px">
            <el-form-item label="启用邮件告警">
              <el-switch v-model="alertConfig.emailEnabled" />
            </el-form-item>
            <el-form-item label="启用短信告警">
              <el-switch v-model="alertConfig.smsEnabled" />
            </el-form-item>
            <el-form-item label="告警间隔">
              <el-input-number v-model="alertConfig.alertInterval" :min="1" :max="60" />
              <span class="unit">分钟</span>
            </el-form-item>
            <el-form-item label="最大告警次数">
              <el-input-number v-model="alertConfig.maxAlerts" :min="1" :max="100" />
            </el-form-item>
            <el-form-item label="告警接收邮箱">
              <el-input v-model="alertConfig.alertEmails" type="textarea" :rows="3" placeholder="多个邮箱用逗号分隔" />
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>

      <!-- 系统监控 -->
      <el-col :span="12">
        <el-card class="config-card">
          <template #header>
            <div class="card-header">
              <span>系统监控</span>
              <el-button size="small" @click="saveMonitorConfig">保存</el-button>
            </div>
          </template>
          <el-form :model="monitorConfig" label-width="120px">
            <el-form-item label="启用性能监控">
              <el-switch v-model="monitorConfig.performanceEnabled" />
            </el-form-item>
            <el-form-item label="数据采集间隔">
              <el-input-number v-model="monitorConfig.collectInterval" :min="10" :max="300" />
              <span class="unit">秒</span>
            </el-form-item>
            <el-form-item label="数据保留天数">
              <el-input-number v-model="monitorConfig.retentionDays" :min="7" :max="365" />
              <span class="unit">天</span>
            </el-form-item>
            <el-form-item label="CPU告警阈值">
              <el-input-number v-model="monitorConfig.cpuThreshold" :min="50" :max="95" />
              <span class="unit">%</span>
            </el-form-item>
            <el-form-item label="内存告警阈值">
              <el-input-number v-model="monitorConfig.memoryThreshold" :min="50" :max="95" />
              <span class="unit">%</span>
            </el-form-item>
            <el-form-item label="磁盘告警阈值">
              <el-input-number v-model="monitorConfig.diskThreshold" :min="70" :max="95" />
              <span class="unit">%</span>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import { Check } from '@element-plus/icons-vue'

const basicConfig = reactive({
  systemName: 'AIOT管理系统',
  systemVersion: '1.0.0',
  companyName: '科技有限公司',
  contactEmail: 'admin@example.com',
  description: '物联网设备管理系统，提供设备监控、数据分析、告警管理等功能'
})

const securityConfig = reactive({
  sessionTimeout: 120,
  passwordMinLength: 8,
  loginLockEnabled: true,
  maxLoginAttempts: 5,
  lockDuration: 15,
  forceHttps: false
})

const emailConfig = reactive({
  smtpHost: 'smtp.example.com',
  smtpPort: 587,
  fromEmail: 'noreply@example.com',
  password: '',
  useSSL: false,
  useTLS: true
})

const databaseConfig = reactive({
  type: 'mysql',
  host: 'localhost',
  port: 3306,
  database: 'aiot_admin',
  username: 'root',
  password: ''
})

const alertConfig = reactive({
  emailEnabled: true,
  smsEnabled: false,
  alertInterval: 5,
  maxAlerts: 10,
  alertEmails: 'admin@example.com, ops@example.com'
})

const monitorConfig = reactive({
  performanceEnabled: true,
  collectInterval: 60,
  retentionDays: 30,
  cpuThreshold: 80,
  memoryThreshold: 85,
  diskThreshold: 90
})

const saveBasicConfig = () => {
  ElMessage.success('基础配置保存成功')
}

const saveSecurityConfig = () => {
  ElMessage.success('安全配置保存成功')
}

const saveEmailConfig = () => {
  ElMessage.success('邮件配置保存成功')
}

const saveDatabaseConfig = () => {
  ElMessage.success('数据库配置保存成功')
}

const saveAlertConfig = () => {
  ElMessage.success('告警配置保存成功')
}

const saveMonitorConfig = () => {
  ElMessage.success('监控配置保存成功')
}

const saveAllConfig = () => {
  ElMessage.success('所有配置保存成功')
}

const testEmail = () => {
  ElMessage.info('正在测试邮件配置...')
  setTimeout(() => {
    ElMessage.success('邮件测试成功')
  }, 2000)
}

const testDatabase = () => {
  ElMessage.info('正在测试数据库连接...')
  setTimeout(() => {
    ElMessage.success('数据库连接测试成功')
  }, 2000)
}
</script>

<style scoped>
.system-config-container {
  padding: 20px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.page-header h2 {
  margin: 0;
  color: #303133;
}

.config-card {
  margin-bottom: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.unit {
  margin-left: 10px;
  color: #909399;
  font-size: 14px;
}
</style>