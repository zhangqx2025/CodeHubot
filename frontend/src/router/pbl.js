/**
 * PBL系统路由配置
 */

// PBL学生端路由
const studentRoutes = {
  path: '/pbl/student',
  component: () => import('@/layouts/PBLStudentLayout.vue'),
  meta: { requiresAuth: true, roles: ['student'] },
  redirect: '/pbl/student/courses',
  children: [
    {
      path: 'courses',
      name: 'StudentCourses',
      component: () => import('@pbl/student/views/MyCourses.vue'),
      meta: { title: '我的课程' }
    },
    {
      path: 'courses/:id',
      name: 'StudentCourseDetail',
      component: () => import('@pbl/student/views/MyCourses.vue'),
      meta: { title: '课程详情' }
    },
    {
      path: 'tasks',
      name: 'StudentTasks',
      component: () => import('@pbl/student/views/MyTasks.vue'),
      meta: { title: '我的任务' }
    },
    {
      path: 'projects',
      name: 'StudentProjects',
      component: () => import('@pbl/student/views/MyCourses.vue'),
      meta: { title: '我的项目' }
    },
    {
      path: 'portfolio',
      name: 'StudentPortfolio',
      component: () => import('@pbl/student/views/StudentPortfolio.vue'),
      meta: { title: '我的作品集' }
    }
  ]
}

// PBL教师端路由
const teacherRoutes = {
  path: '/pbl/teacher',
  component: () => import('@/layouts/PBLTeacherLayout.vue'),
  meta: { requiresAuth: true, roles: ['teacher'] },
  redirect: '/pbl/teacher/dashboard',
  children: [
    {
      path: 'dashboard',
      name: 'TeacherDashboard',
      component: () => import('@pbl/teacher/views/TeacherDashboard.vue'),
      meta: { title: '教学仪表盘' }
    },
    {
      path: 'courses',
      name: 'TeacherCourses',
      component: () => import('@pbl/teacher/views/TeacherCourses.vue'),
      meta: { title: '课程管理' }
    },
    {
      path: 'tasks',
      name: 'TeacherTasks',
      component: () => import('@pbl/teacher/views/TeacherTasks.vue'),
      meta: { title: '任务管理' }
    },
    {
      path: 'students',
      name: 'TeacherStudents',
      component: () => import('@pbl/teacher/views/TeacherStudents.vue'),
      meta: { title: '学生管理' }
    }
  ]
}

// PBL管理端路由
const adminRoutes = {
  path: '/pbl/admin',
  component: () => import('@/layouts/PBLAdminLayout.vue'),
  meta: { requiresAuth: true, roles: ['platform_admin', 'school_admin'] },
  redirect: '/pbl/admin/dashboard',
  children: [
    {
      path: 'dashboard',
      name: 'AdminDashboard',
      component: () => import('@pbl/admin/views/AdminDashboard.vue'),
      meta: { title: '管理仪表盘' }
    },
    {
      path: 'users',
      name: 'AdminUsers',
      component: () => import('@pbl/admin/views/AdminUsers.vue'),
      meta: { title: '用户管理' }
    },
    {
      path: 'schools',
      name: 'AdminSchools',
      component: () => import('@pbl/admin/views/AdminSchools.vue'),
      meta: { title: '学校管理' }
    },
    {
      path: 'courses',
      name: 'AdminCourses',
      component: () => import('@pbl/admin/views/AdminCourses.vue'),
      meta: { title: '课程管理' }
    }
  ]
}

// PBL渠道商端路由
const channelRoutes = {
  path: '/pbl/channel',
  component: () => import('@/layouts/PBLChannelLayout.vue'),
  meta: { requiresAuth: true, roles: ['channel_partner'] },
  redirect: '/pbl/channel/schools',
  children: [
    {
      path: 'schools',
      name: 'ChannelSchools',
      component: () => import('@pbl/channel/views/ChannelSchools.vue'),
      meta: { title: '合作学校' }
    },
    {
      path: 'schools/:schoolId/courses',
      name: 'ChannelSchoolCourses',
      component: () => import('@pbl/channel/views/ChannelSchoolCourses.vue'),
      meta: { title: '学校课程' }
    },
    {
      path: 'courses/:courseUuid',
      name: 'ChannelCourseDetail',
      component: () => import('@pbl/channel/views/ChannelCourseDetail.vue'),
      meta: { title: '课程详情' }
    }
  ]
}

// PBL渠道管理端路由
const channelManagementRoutes = {
  path: '/pbl/channel-mgmt',
  component: () => import('@/layouts/ChannelManagementLayout.vue'),
  meta: { requiresAuth: true, roles: ['channel_manager', 'platform_admin'] },
  redirect: '/pbl/channel-mgmt/partners',
  children: [
    {
      path: 'partners',
      name: 'ChannelPartners',
      component: () => import('@pbl/channel-mgmt/views/ChannelPartners.vue'),
      meta: { title: '渠道商管理' }
    },
    {
      path: 'partners/:partnerId',
      name: 'ChannelPartnerDetail',
      component: () => import('@pbl/channel-mgmt/views/ChannelPartnerDetail.vue'),
      meta: { title: '渠道商详情' }
    },
    {
      path: 'schools',
      name: 'SchoolManagement',
      component: () => import('@pbl/channel-mgmt/views/SchoolManagement.vue'),
      meta: { title: '学校管理' }
    },
    {
      path: 'assign-schools',
      name: 'AssignSchools',
      component: () => import('@pbl/channel-mgmt/views/AssignSchools.vue'),
      meta: { title: '学校分配' }
    },
    {
      path: 'statistics',
      name: 'ChannelStatistics',
      component: () => import('@pbl/channel-mgmt/views/ChannelStatistics.vue'),
      meta: { title: '渠道统计' }
    }
  ]
}

export default [studentRoutes, teacherRoutes, adminRoutes, channelRoutes, channelManagementRoutes]
