# 阿里云VOD视频点播配置说明

## 功能说明

阿里云VOD（视频点播）服务用于：
- 为学生提供安全的视频播放授权
- 支持视频观看次数限制
- 记录学生观看历史
- 提供视频播放统计

## 配置步骤

### 1. 获取阿里云访问密钥

1. 登录 [阿里云控制台](https://www.aliyun.com/)
2. 进入 **AccessKey管理** 页面
3. 创建或查看已有的AccessKey
4. 记录 `AccessKey ID` 和 `AccessKey Secret`

### 2. 开通VOD服务

1. 在阿里云控制台搜索 "视频点播"
2. 开通VOD服务
3. 选择合适的区域（推荐 `cn-shanghai`）

### 3. 配置环境变量

在服务器的 `.env` 文件中添加以下配置：

```bash
# 阿里云VOD配置
ALIYUN_ACCESS_KEY_ID=你的AccessKeyId
ALIYUN_ACCESS_KEY_SECRET=你的AccessKeySecret
ALIYUN_VOD_REGION_ID=cn-shanghai
```

**注意事项：**
- `ALIYUN_ACCESS_KEY_ID` 和 `ALIYUN_ACCESS_KEY_SECRET` 必填
- `ALIYUN_VOD_REGION_ID` 可选，默认为 `cn-shanghai`
- 区域可选值：`cn-shanghai`、`cn-beijing`、`cn-shenzhen` 等

### 4. 重启服务

配置完成后，重启Docker服务使配置生效：

```bash
cd /path/to/docker
docker-compose -f docker-compose.prod.yml restart backend
```

或者重启所有服务：

```bash
docker-compose -f docker-compose.prod.yml restart
```

## 验证配置

启动后端服务后，查看日志确认VOD服务是否正常：

```bash
docker logs codehubot-backend | grep VOD
```

如果配置成功，应该看到：
```
✅ 阿里云VOD客户端初始化成功
   - Region ID: cn-shanghai
   - Endpoint: vod.cn-shanghai.aliyuncs.com
```

如果配置失败，会看到警告：
```
⚠️ 阿里云VOD配置未设置，视频播放功能将不可用
```

## 临时禁用VOD功能

如果暂时不需要视频功能，可以不配置这些环境变量。系统会自动禁用视频播放功能，返回友好的提示信息：

```json
{
  "code": 503,
  "message": "阿里云VOD服务未配置，无法播放视频"
}
```

## 安全建议

1. **不要将AccessKey直接写入代码或配置文件**，使用环境变量
2. **定期轮换AccessKey**，建议每3-6个月更换一次
3. **使用RAM子账号**，为VOD服务创建专用的RAM子账号，只授予VOD相关权限
4. **启用IP白名单**，在阿里云控制台限制API访问来源IP

## 故障排查

### 问题1：视频播放返回503错误

**原因：** VOD服务未配置或配置错误

**解决方法：**
1. 检查环境变量是否正确设置
2. 查看backend容器日志
3. 确认阿里云账号已开通VOD服务

### 问题2：获取播放凭证失败

**原因：** 
- AccessKey权限不足
- 视频ID不存在
- 区域配置错误

**解决方法：**
1. 确认RAM账号有VOD权限
2. 检查视频是否已上传到阿里云VOD
3. 验证区域ID是否正确

## 相关文档

- [阿里云VOD官方文档](https://help.aliyun.com/product/29932.html)
- [VOD API参考](https://help.aliyun.com/document_detail/61064.html)
- [AccessKey管理](https://ram.console.aliyun.com/manage/ak)

## 技术支持

如有问题，请联系系统管理员或查看项目文档。

