# 固件文件说明

此目录用于存放 ESP32 设备的固件文件。

## 固件列表

- `ESP32-S3-Lite-01-v1.7.bin` - ESP32-S3-Lite v1.7 固件（约 6 MB）

## 添加新固件

1. 将新的固件文件（.bin 格式）复制到此目录
2. 修改 `frontend/src/modules/device/views/FirmwareFlasher.vue` 文件中的 `firmwareList` 配置
3. 添加新固件的信息：
   - id: 唯一标识符
   - name: 固件名称
   - version: 版本号
   - filename: 文件路径（相对于 public 目录）
   - size: 文件大小
   - date: 发布日期
   - description: 描述信息
   - address: 烧录地址（通常为 '0x0'）

## 示例配置

```javascript
{
  id: 'esp32s3-lite-v1.7',
  name: 'ESP32-S3-Lite v1.7',
  version: '1.7',
  filename: '/firmware/ESP32-S3-Lite-01-v1.7.bin',
  size: '约 6 MB',
  date: '2024-12-23',
  description: '最新稳定版本，包含所有功能优化',
  address: '0x0'
}
```

## 注意事项

- 固件文件应为 ESP32 芯片编译的二进制文件（.bin 格式）
- 确保固件文件与目标设备型号匹配
- 固件文件会在构建时被复制到 dist 目录

