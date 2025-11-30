# 阿里云 API 密钥配置指南

## 📖 目录

1. [为什么需要阿里云 API 密钥](#为什么需要阿里云-api-密钥)
2. [如何获取 API 密钥](#如何获取-api-密钥)
3. [如何配置 API 密钥](#如何配置-api-密钥)
4. [验证配置](#验证配置)
5. [常见问题](#常见问题)

---

## 为什么需要阿里云 API 密钥

知识库的**文档向量化**功能使用了阿里云通义千问的 **Embedding API**，用于将文本转换成向量表示，以支持语义搜索。

**必需场景**:
- ✅ 上传文档到知识库
- ✅ 文档向量化处理
- ✅ 语义搜索和检索

**不需要场景**:
- ❌ 其他功能（设备管理、用户管理等）不需要

---

## 如何获取 API 密钥

### 方法 1: 通过阿里云控制台（推荐）

#### 步骤 1: 注册阿里云账号
如果还没有阿里云账号，访问：https://www.aliyun.com/ 注册

#### 步骤 2: 开通 DashScope 服务
1. 访问通义千问控制台：https://dashscope.console.aliyun.com/
2. 首次访问会提示开通服务，点击**开通**
3. 阅读并同意服务协议

#### 步骤 3: 获取 API Key
1. 访问 API Key 管理页面：https://dashscope.console.aliyun.com/apiKey
2. 点击**创建新的 API Key**
3. 复制生成的 API Key（格式类似：`sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`）

⚠️ **重要提示**:
- API Key 只会显示一次，务必妥善保存
- 如果丢失，需要重新创建
- 不要将 API Key 提交到代码仓库

#### 步骤 4: 充值（可选）
- 通义千问提供免费额度，新用户通常有试用额度
- 如需长期使用，访问**费用中心**充值
- Embedding API 价格：约 ¥0.0007/千 tokens（非常便宜）

**费用参考**（2024年价格）:
- 1个文档（约5000字）≈ 7000 tokens ≈ ¥0.005（半分钱）
- 1000个文档 ≈ ¥5
- 每月处理1万个文档 ≈ ¥50

---

## 如何配置 API 密钥

### 方式 1: 配置环境变量文件（推荐）

#### 在开发环境（本地）:

1. **复制环境变量模板**:
```bash
cd /path/to/CodeHubot/backend
cp env.example .env
```

2. **编辑 `.env` 文件**:
```bash
vim .env
# 或使用其他编辑器
nano .env
```

3. **添加 API 密钥**:
找到以下部分并填入您的 API Key：
```bash
# ==================== 知识库向量化配置 ====================
# 阿里云通义千问 Embedding API 密钥
DASHSCOPE_API_KEY=sk-your-actual-api-key-here
```

将 `sk-your-actual-api-key-here` 替换为您从阿里云获取的真实 API Key。

4. **保存并退出**:
```bash
# vim: 按 ESC 然后输入 :wq
# nano: 按 Ctrl+X，然后 Y，然后 Enter
```

5. **重启后端服务**:
```bash
# 如果使用 systemctl
sudo systemctl restart your-backend-service

# 如果手动运行
pkill -f uvicorn
cd /path/to/CodeHubot/backend
nohup uvicorn main:app --host 0.0.0.0 --port 8000 &
```

---

#### 在生产环境（远程服务器）:

**方式 A: 使用 .env 文件（推荐）**

SSH 登录到服务器后，执行相同的步骤：

```bash
cd /path/to/CodeHubot/backend

# 如果还没有 .env 文件
cp env.example .env

# 编辑配置
vim .env

# 找到并修改这一行
DASHSCOPE_API_KEY=sk-your-actual-api-key-here

# 保存后重启服务
sudo systemctl restart your-backend-service
```

**方式 B: 使用系统环境变量**

如果您使用 systemd 管理服务：

```bash
# 编辑服务配置
sudo vim /etc/systemd/system/your-backend-service.service

# 在 [Service] 部分添加
Environment="DASHSCOPE_API_KEY=sk-your-actual-api-key-here"

# 重新加载并重启
sudo systemctl daemon-reload
sudo systemctl restart your-backend-service
```

**方式 C: 使用 Docker（如果使用 Docker）**

在 `docker-compose.yml` 中：
```yaml
services:
  backend:
    environment:
      - DASHSCOPE_API_KEY=sk-your-actual-api-key-here
```

或使用 `.env` 文件：
```yaml
services:
  backend:
    env_file:
      - .env
```

---

### 方式 2: 直接设置环境变量（临时）

**仅用于测试，重启后会失效**:

```bash
export DASHSCOPE_API_KEY=sk-your-actual-api-key-here

# 然后运行后端
cd /path/to/CodeHubot/backend
python main.py
```

---

## 验证配置

### 方法 1: 检查环境变量

```bash
# SSH 到服务器
cd /path/to/CodeHubot/backend

# 查看配置
cat .env | grep DASHSCOPE_API_KEY

# 或检查环境变量（如果已启动服务）
ps aux | grep uvicorn
```

### 方法 2: 使用 Python 脚本测试

创建测试脚本 `test_api_key.py`:

```python
import os
from dotenv import load_dotenv

# 加载 .env 文件
load_dotenv()

# 检查 API Key
api_key = os.getenv("DASHSCOPE_API_KEY") or os.getenv("QWEN_API_KEY")

if api_key:
    print(f"✅ API Key 已配置")
    print(f"   前缀: {api_key[:10]}...")
    print(f"   长度: {len(api_key)} 字符")
else:
    print("❌ 未找到 API Key")
    print("   请检查环境变量：DASHSCOPE_API_KEY 或 QWEN_API_KEY")
```

运行测试:
```bash
cd /path/to/CodeHubot/backend
python test_api_key.py
```

### 方法 3: 测试实际向量化

```bash
cd /path/to/CodeHubot/backend

# 使用我们之前创建的脚本
python scripts/manual_embed_document.py list

# 如果有待处理文档，尝试向量化
python scripts/manual_embed_document.py 1
```

**成功的输出**:
```
🔄 开始处理文档: 测试文档.txt
   ID: 1
   UUID: abc-123-def
✅ 文档处理成功!
   文本块数量: 25
```

**失败的输出**（API Key 未配置）:
```
❌ Embedding服务未配置: API密钥未设置
```

---

## 常见问题

### Q1: 提示 "API密钥未设置" 怎么办？

**A**: 按以下步骤检查：

1. **确认 .env 文件存在**:
```bash
ls -la /path/to/backend/.env
```

2. **检查配置内容**:
```bash
cat /path/to/backend/.env | grep DASHSCOPE
```

3. **确认格式正确**:
```bash
# 正确格式（无引号，无空格）
DASHSCOPE_API_KEY=sk-abc123def456

# 错误格式
DASHSCOPE_API_KEY = sk-abc123def456  # ❌ 有空格
DASHSCOPE_API_KEY="sk-abc123def456"  # ❌ 有引号（某些情况下也可以）
```

4. **重启服务**:
```bash
sudo systemctl restart your-backend-service
```

---

### Q2: 提示 "Invalid API Key" 怎么办？

**A**: 可能的原因：

1. **API Key 复制错误**
   - 检查是否完整复制
   - 检查是否有多余的空格或换行

2. **API Key 已失效**
   - 访问阿里云控制台重新生成

3. **服务未开通**
   - 访问 https://dashscope.console.aliyun.com/ 确认已开通

---

### Q3: 提示 "超出配额" 或 "余额不足" 怎么办？

**A**: 需要充值：

1. 访问阿里云控制台
2. 进入**费用中心** → **账户总览**
3. 充值（建议先充 50-100 元测试）
4. 返回 DashScope 控制台确认额度

---

### Q4: 如何查看 API 使用量和费用？

**A**: 

1. 访问 DashScope 控制台：https://dashscope.console.aliyun.com/
2. 点击**用量统计**
3. 查看详细的调用次数和费用

---

### Q5: 可以使用其他 Embedding 服务吗？

**A**: 目前代码支持：

1. **阿里云通义千问**（推荐）
   - 中文支持好
   - 价格便宜
   - 国内访问快

2. **OpenAI**（可选）
   - 需要修改代码配置
   - 需要国际网络
   - 价格较贵

如需使用 OpenAI，配置：
```bash
# .env 文件中
OPENAI_API_KEY=sk-your-openai-key
```

并修改代码中的 provider 参数为 `openai`。

---

### Q6: 如何确保 API Key 安全？

**A**: 安全最佳实践：

1. ✅ 不要将 `.env` 文件提交到 Git
```bash
# 确保 .gitignore 包含
echo ".env" >> .gitignore
```

2. ✅ 使用环境变量而不是硬编码

3. ✅ 定期轮换 API Key

4. ✅ 限制 API Key 权限（在阿里云控制台）

5. ✅ 监控 API 使用量，发现异常及时处理

---

## 完整配置示例

### `.env` 文件完整示例:

```bash
# 数据库配置
DB_HOST=localhost
DB_PORT=3306
DB_USER=aiot_user
DB_PASSWORD=your_db_password
DB_NAME=aiot_admin

# JWT配置
SECRET_KEY=your-very-long-secret-key-at-least-32-characters
ACCESS_TOKEN_EXPIRE_MINUTES=120

# MQTT配置
MQTT_BROKER_HOST=localhost
MQTT_BROKER_PORT=1883

# 知识库向量化配置（重要！）
DASHSCOPE_API_KEY=sk-your-actual-dashscope-api-key-here

# 环境配置
ENVIRONMENT=production
LOG_LEVEL=INFO
```

---

## 快速开始（完整流程）

```bash
# 1. 获取 API Key
# 访问: https://dashscope.console.aliyun.com/apiKey

# 2. 配置到服务器
ssh user@your-server
cd /path/to/CodeHubot/backend
vim .env

# 3. 添加配置
DASHSCOPE_API_KEY=sk-your-api-key-here

# 4. 重启服务
sudo systemctl restart your-backend-service

# 5. 测试
python scripts/manual_embed_document.py list
python scripts/manual_embed_document.py all

# 6. 验证
# 登录前端 → 知识库 → 上传文档 → 查看状态变化
```

---

## 联系支持

如果配置遇到问题，请提供以下信息：

1. 错误日志（注意隐藏 API Key）
2. 环境变量配置（隐藏敏感信息）
3. Python 版本
4. 系统信息

---

**最后更新**: 2025-11-30  
**版本**: v1.0

