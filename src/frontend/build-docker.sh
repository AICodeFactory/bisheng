#!/bin/bash

# Docker 镜像构建脚本
# 用于构建 bisheng-frontend Docker 镜像

set -e  # 遇到错误立即退出

# 镜像名称
IMAGE_NAME="bisheng-frontend"

# 获取脚本所在目录（frontend 目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "开始构建 Docker 镜像: $IMAGE_NAME"
echo "构建目录: $SCRIPT_DIR"
echo "=========================================="

# 检查 Dockerfile 是否存在
if [ ! -f "Dockerfile" ]; then
    echo "错误: 未找到 Dockerfile"
    exit 1
fi

# 构建镜像
echo "正在构建镜像..."
docker build -t "$IMAGE_NAME" .

if [ $? -eq 0 ]; then
    echo "=========================================="
    echo "✅ 镜像构建成功: $IMAGE_NAME"
    echo "=========================================="
    echo ""
    echo "可以使用以下命令查看镜像:"
    echo "  docker images $IMAGE_NAME"
    echo ""
    echo "可以使用以下命令运行容器:"
    echo "  docker run -d -p 3001:3001 --name bisheng-frontend $IMAGE_NAME"
    echo ""
    echo "或者使用 docker-compose 重启 frontend 服务:"
    echo "  cd ../../docker && docker compose -f docker-compose-aliyun.yml up -d --force-recreate frontend"
else
    echo "=========================================="
    echo "❌ 镜像构建失败"
    echo "=========================================="
    exit 1
fi
