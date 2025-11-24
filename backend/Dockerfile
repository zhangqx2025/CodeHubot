FROM python:3.11-slim

WORKDIR /app

# 设置构建参数，支持使用国内镜像源加速
ARG USE_CHINA_MIRROR=false
ARG PIP_INDEX_URL=""
ARG PIP_TRUSTED_HOST=""

# 根据构建参数设置 pip 镜像源（如果启用）
RUN if [ "$USE_CHINA_MIRROR" = "true" ]; then \
        pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && \
        pip config set global.trusted-host pypi.tuna.tsinghua.edu.cn; \
    elif [ -n "$PIP_INDEX_URL" ]; then \
        pip config set global.index-url $PIP_INDEX_URL && \
        if [ -n "$PIP_TRUSTED_HOST" ]; then \
            pip config set global.trusted-host $PIP_TRUSTED_HOST; \
        fi; \
    fi

# 安装系统依赖（优化：使用 no-install-recommends 减少下载量，合并清理操作）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc \
        libpq-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# 复制依赖文件（先复制依赖文件，利用 Docker 缓存层）
COPY requirements.txt .

# 安装Python依赖（先升级 pip，然后安装依赖）
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY . .

# 暴露端口
EXPOSE 8000

# 启动命令
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
