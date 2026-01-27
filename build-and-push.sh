#!/bin/bash

# Azure Container Registry 构建和推送脚本
# 使用方法: ./build-and-push.sh <ACR_NAME> [TAG] [BUILD_BASE]
# 例如: 
#   ./build-and-push.sh myregistry.azurecr.io v260122 true   # 构建基础镜像
#   ./build-and-push.sh myregistry.azurecr.io v260122 false  # 跳过基础镜像（使用已有镜像）

set -e

ACR_NAME=${1:-""}
TAG=${2:-"latest"}
BUILD_BASE=${3:-"true"}

if [ -z "$ACR_NAME" ]; then
    echo "错误: 请提供 Azure Container Registry 名称"
    echo "使用方法: ./build-and-push.sh <ACR_NAME> [TAG] [BUILD_BASE]"
    echo "参数说明:"
    echo "  ACR_NAME   - Azure Container Registry 名称（必需）"
    echo "  TAG        - 镜像标签，默认为 'latest'"
    echo "  BUILD_BASE - 是否构建基础镜像，默认为 'true'"
    echo "               设置为 'true', '1', 'yes' 时会构建基础镜像"
    echo "               设置为 'false', '0', 'no' 时会跳过基础镜像构建"
    echo "示例:"
    echo "  ./build-and-push.sh myregistry.azurecr.io v260122 true"
    echo "  ./build-and-push.sh myregistry.azurecr.io v260122 false"
    exit 1
fi

# 标准化 BUILD_BASE 参数（支持多种输入格式）
BUILD_BASE=$(echo "$BUILD_BASE" | tr '[:upper:]' '[:lower:]')
if [[ "$BUILD_BASE" == "true" || "$BUILD_BASE" == "1" || "$BUILD_BASE" == "yes" ]]; then
    BUILD_BASE=true
else
    BUILD_BASE=false
fi

# 移除末尾的斜杠（如果有）
ACR_NAME=${ACR_NAME%/}

# 提取 ACR 登录名称（去掉 .azurecr.io 后缀）
ACR_LOGIN_NAME=${ACR_NAME%.azurecr.io}
if [ "$ACR_LOGIN_NAME" = "$ACR_NAME" ]; then
    # 如果没有 .azurecr.io 后缀，假设用户只提供了名称
    ACR_LOGIN_NAME=$ACR_NAME
    ACR_NAME="${ACR_NAME}.azurecr.io"
fi

echo "=========================================="
echo "开始构建并推送到 Azure Container Registry"
echo "=========================================="
echo "ACR 名称: $ACR_NAME"
echo "ACR 登录名称: $ACR_LOGIN_NAME"
echo "镜像标签: $TAG"
echo "构建基础镜像: $BUILD_BASE"
echo "=========================================="
echo ""

# 1. 登录到 Azure Container Registry
echo "步骤 1: 登录到 Azure Container Registry..."
az acr login --name $ACR_LOGIN_NAME
if [ $? -ne 0 ]; then
    echo "错误: 无法登录到 ACR。请确保："
    echo "  1. 已安装 Azure CLI"
    echo "  2. 已运行 'az login' 登录 Azure"
    echo "  3. ACR 名称正确"
    exit 1
fi

# 切换到 backend 目录
cd src/backend

# 2. 处理 backend 基础镜像
if [ "$BUILD_BASE" = true ]; then
    # 构建 backend 基础镜像
    echo ""
    echo "步骤 2: 构建 backend 基础镜像..."
    docker build -f base.Dockerfile -t ${ACR_NAME}/bisheng-backend:base.v8 -t dataelement/bisheng-backend:base.v8 .
    if [ $? -ne 0 ]; then
        echo "错误: backend 基础镜像构建失败"
        exit 1
    fi

    # 推送 backend 基础镜像
    echo ""
    echo "步骤 3: 推送 backend 基础镜像到 ACR..."
    docker push ${ACR_NAME}/bisheng-backend:base.v8
    if [ $? -ne 0 ]; then
        echo "错误: backend 基础镜像推送失败"
        exit 1
    fi
else
    # 跳过基础镜像构建，尝试从 ACR 拉取或使用本地镜像
    echo ""
    echo "步骤 2: 跳过基础镜像构建，检查基础镜像是否存在..."
    
    # 检查本地是否存在基础镜像
    if docker images | grep -q "dataelement/bisheng-backend.*base.v8"; then
        echo "找到本地基础镜像: dataelement/bisheng-backend:base.v8"
    else
        echo "本地未找到基础镜像，尝试从 ACR 拉取..."
        docker pull ${ACR_NAME}/bisheng-backend:base.v8
        if [ $? -eq 0 ]; then
            echo "成功从 ACR 拉取基础镜像"
            # 标记为本地镜像，以便 Dockerfile 可以使用
            docker tag ${ACR_NAME}/bisheng-backend:base.v8 dataelement/bisheng-backend:base.v8
        else
            echo "警告: 无法从 ACR 拉取基础镜像 ${ACR_NAME}/bisheng-backend:base.v8"
            echo "请确保基础镜像已存在于 ACR，或设置 BUILD_BASE=true 来构建基础镜像"
            exit 1
        fi
    fi
fi

# 3. 构建 backend 应用镜像（Azure 版本，包含配置文件）
echo ""
echo "步骤 3: 构建 backend 应用镜像（Azure 版本）..."
docker build -f Dockerfile_azure -t ${ACR_NAME}/bisheng-backend:${TAG} .
if [ $? -ne 0 ]; then
    echo "错误: backend 应用镜像构建失败"
    exit 1
fi

# 4. 推送 backend 应用镜像
echo ""
echo "步骤 4: 推送 backend 应用镜像到 ACR..."
docker push ${ACR_NAME}/bisheng-backend:${TAG}
if [ $? -ne 0 ]; then
    echo "错误: backend 应用镜像推送失败"
    exit 1
fi

# 5. 构建 frontend 镜像
echo ""
echo "步骤 5: 构建 frontend 镜像..."
cd ../frontend
docker build -f Dockerfile_azure -t ${ACR_NAME}/bisheng-frontend:${TAG} .
if [ $? -ne 0 ]; then
    echo "错误: frontend 镜像构建失败"
    exit 1
fi

# 6. 推送 frontend 镜像
echo ""
echo "步骤 6: 推送 frontend 镜像到 ACR..."
docker push ${ACR_NAME}/bisheng-frontend:${TAG}
if [ $? -ne 0 ]; then
    echo "错误: frontend 镜像推送失败"
    exit 1
fi

echo ""
echo "=========================================="
echo "构建和推送完成！"
echo "=========================================="
echo "镜像列表:"
if [ "$BUILD_BASE" = true ]; then
    echo "  - ${ACR_NAME}/bisheng-backend:base.v8 (新构建)"
fi
echo "  - ${ACR_NAME}/bisheng-backend:${TAG}"
echo "  - ${ACR_NAME}/bisheng-frontend:${TAG}"
echo "=========================================="
