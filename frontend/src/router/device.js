/**
 * Device系统路由配置
 */
export default [
  {
    path: '/device',
    component: () => import('@/layouts/DeviceLayout.vue'),
    meta: { requiresAuth: true },
    redirect: '/device/dashboard',
    children: [
      {
        path: 'dashboard',
        name: 'DeviceDashboard',
        component: () => import('@device/views/Dashboard.vue'),
        meta: { title: '仪表盘' }
      },
      {
        path: 'devices',
        name: 'DeviceList',
        component: () => import('@device/views/Devices.vue'),
        meta: { title: '设备列表' }
      },
      {
        path: 'devices/:id',
        name: 'DeviceDetail',
        component: () => import('@device/views/DeviceDetail.vue'),
        meta: { title: '设备详情' }
      },
      {
        path: 'products',
        name: 'ProductList',
        component: () => import('@device/views/Products.vue'),
        meta: { title: '产品管理' }
      },
      {
        path: 'device-groups',
        name: 'DeviceGroupList',
        component: () => import('@device/views/DeviceGroups.vue'),
        meta: { title: '设备分组' }
      },
      {
        path: 'firmware',
        name: 'FirmwareManagement',
        component: () => import('@device/views/DeviceConfig.vue'),
        meta: { title: '固件管理' }
      },
      {
        path: 'system-config',
        name: 'SystemConfig',
        component: () => import('@device/views/SystemConfig.vue'),
        meta: { title: '系统配置', requiresAdmin: true }
      },
      {
        path: 'module-config',
        name: 'ModuleConfig',
        component: () => import('@device/views/ModuleConfig.vue'),
        meta: { title: '模块配置', requiresAdmin: true }
      }
    ]
  }
]
