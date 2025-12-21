# 🔧 ESP32 固件烧录功能

## 📖 概述

在设备管理系统中集成了 ESP32 固件在线烧录功能，用户可以通过浏览器直接给 ESP32 设备烧录固件，无需安装任何额外软件。

**访问地址**: `http://localhost:3000/device/firmware-flasher`

## ✨ 功能特性

- ✅ **零安装** - 无需安装驱动或软件，纯浏览器操作
- ✅ **实时进度** - 烧录进度实时显示
- ✅ **详细日志** - 完整的操作日志记录
- ✅ **多版本支持** - 支持多个固件版本管理
- ✅ **完整功能** - 烧录、擦除、重启一应俱全
- ✅ **美观界面** - 现代化的 UI 设计
- ✅ **易于使用** - 清晰的操作流程和提示

## 🚀 快速开始

### 1️⃣ 安装依赖

```bash
cd frontend
npm install
```

### 2️⃣ 启动服务

```bash
npm run dev
```

### 3️⃣ 访问页面

在 Chrome 或 Edge 浏览器中打开：
```
http://localhost:3000/device/firmware-flasher
```

### 4️⃣ 开始烧录

1. 用 USB 数据线连接 ESP32 设备
2. 点击"连接设备"
3. 选择固件版本
4. 点击"开始烧录"
5. 等待完成（约 2-3 分钟）

## 📋 文档导航

| 文档 | 说明 |
|------|------|
| [快速开始](./docs/固件烧录快速开始.md) | 5 分钟上手指南 |
| [功能说明](./docs/固件烧录功能说明.md) | 详细功能介绍和使用方法 |
| [安装指南](./docs/固件烧录功能安装指南.md) | 完整的安装配置步骤 |
| [测试清单](./固件烧录功能测试清单.md) | 功能测试检查清单 |
| [完成总结](./固件烧录功能完成总结.md) | 开发完成情况总结 |

## 🎯 核心技术

- **Web Serial API** - 浏览器原生串口通信
- **esptool-js** - JavaScript 版 ESP32 烧录工具
- **Vue 3** - 前端框架
- **Element Plus** - UI 组件库

## 📁 文件结构

```
frontend/
├── src/
│   ├── layouts/
│   │   └── DeviceLayout.vue           # 左侧菜单（已添加固件烧录）
│   ├── modules/device/views/
│   │   └── FirmwareFlasher.vue        # 固件烧录主页面
│   └── router/
│       └── device.js                   # 路由配置
├── public/
│   └── firmware/
│       ├── ESP32-S3-Lite-01-v1.6.bin  # 固件文件
│       └── README.md                   # 固件管理说明
└── package.json                        # 依赖配置

docs/
├── 固件烧录功能说明.md                # 详细说明
├── 固件烧录功能安装指南.md            # 安装指南
└── 固件烧录快速开始.md                # 快速开始
```

## ⚠️ 重要提示

### 浏览器要求

**必须使用以下浏览器之一：**
- ✅ Google Chrome 89+
- ✅ Microsoft Edge 89+
- ✅ Opera 75+

**不支持：**
- ❌ Firefox
- ❌ Safari
- ❌ 移动端浏览器

### 硬件要求

- ✅ USB **数据线**（非充电线）
- ✅ ESP32 系列设备（ESP32-S3、ESP32-C3 等）
- ✅ 正确安装的驱动（CH340/CP210x）

### 使用注意

1. ⚠️ 烧录过程中请勿断开设备
2. ⚠️ 确保选择正确的固件版本
3. ⚠️ 擦除 Flash 会删除所有数据
4. ⚠️ 首次烧录可能需要 3-5 分钟

## 🎨 界面预览

固件烧录页面包含：

1. **状态卡片** - 显示连接状态和芯片信息
2. **连接控制** - 连接/断开设备
3. **固件选择** - 选择固件版本和查看详情
4. **操作按钮** - 烧录、擦除、重启
5. **进度显示** - 实时烧录进度
6. **日志面板** - 详细操作日志
7. **使用提示** - 完整的使用说明

## 🔧 添加新固件

### 步骤 1: 上传固件文件

```bash
cp your-firmware.bin frontend/public/firmware/
```

### 步骤 2: 更新配置

编辑 `frontend/src/modules/device/views/FirmwareFlasher.vue`：

```javascript
const firmwareList = ref([
  // 现有固件...
  {
    id: 'esp32s3-lite-v1.7',
    name: 'ESP32-S3-Lite v1.7',
    version: '1.7',
    filename: '/firmware/your-firmware.bin',
    size: '约 6.2 MB',
    date: '2025-01-15',
    description: '新版本说明',
    address: '0x0'
  }
])
```

### 步骤 3: 重启服务

```bash
npm run dev
```

## 🐛 常见问题

### Q: 浏览器提示不支持 Web Serial API

**A:** 请使用 Chrome 或 Edge 浏览器，并确保版本为 89 或更高。

### Q: 找不到串口设备

**A:** 
1. 检查是否使用数据线（非充电线）
2. 安装 CH340 或 CP210x 驱动
3. 关闭占用串口的程序
4. 重新插拔 USB 线

### Q: 烧录失败

**A:** 
1. 先点击"擦除 Flash"
2. 然后重新烧录
3. 检查 USB 连接是否稳定

### Q: npm install 失败

**A:**
```bash
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

## 📊 技术细节

### Web Serial API

利用浏览器原生的 Web Serial API 实现串口通信：

```javascript
// 请求串口访问
const port = await navigator.serial.requestPort({
  filters: [
    { usbVendorId: 0x303a }, // Espressif
    { usbVendorId: 0x10c4 }, // Silicon Labs
    { usbVendorId: 0x1a86 }, // QinHeng Electronics
  ]
})
```

### esptool-js

使用 JavaScript 版本的 esptool 进行固件烧录：

```javascript
import { ESPLoader, Transport } from 'esptool-js'

const esploader = new ESPLoader({
  transport: transport,
  baudrate: 115200,
  terminal: { /* ... */ }
})

await esploader.writeFlash({
  fileArray: fileArray,
  flashSize: 'keep',
  compress: true,
  reportProgress: (fileIndex, written, total) => {
    // 更新进度
  }
})
```

## 🚀 生产环境部署

### 构建

```bash
cd frontend
npm run build
```

### 部署

将 `dist` 目录部署到 Web 服务器，确保：

1. 固件文件正确复制到 `dist/firmware/`
2. 配置正确的 MIME 类型
3. 允许大文件传输（50MB+）

详见 [安装指南](./docs/固件烧录功能安装指南.md)。

## 🎯 后续优化

### 计划中的功能

- [ ] 批量烧录多个设备
- [ ] 固件版本在线升级检测
- [ ] 自定义固件上传
- [ ] 烧录历史记录
- [ ] 固件签名验证
- [ ] 版本回滚功能

### 用户体验优化

- [ ] 添加烧录向导
- [ ] 优化错误提示
- [ ] 固件对比功能
- [ ] 多语言支持

## 📞 技术支持

遇到问题？

1. 查看 [功能说明文档](./docs/固件烧录功能说明.md)
2. 查看 [常见问题](#-常见问题)
3. 检查浏览器控制台错误信息
4. 查看操作日志面板

## 🔗 相关资源

- [Web Serial API 文档](https://developer.mozilla.org/en-US/docs/Web/API/Web_Serial_API)
- [esptool-js GitHub](https://github.com/espressif/esptool-js)
- [ESP32 官方文档](https://docs.espressif.com/projects/esp-idf/zh_CN/latest/esp32/)
- [Element Plus 文档](https://element-plus.org/)

## 📝 更新日志

### v1.0.0 (2024-12-21)

- ✨ 初始版本发布
- ✅ 支持 ESP32-S3 设备烧录
- ✅ 集成到设备管理后台
- ✅ 实时进度显示
- ✅ 详细操作日志
- ✅ 完整的使用文档

## 📄 许可证

本项目遵循项目主许可证。

---

## 🎉 开始使用

```bash
# 1. 安装依赖
cd frontend && npm install

# 2. 启动服务
npm run dev

# 3. 打开浏览器
# http://localhost:3000/device/firmware-flasher
```

**享受便捷的固件烧录体验！** 🚀

