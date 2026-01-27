# 构建和推送镜像到 Azure Container Registry

本文档说明如何将 bisheng 项目的 backend 和 frontend 镜像构建并推送到 Azure Container Registry (ACR)。

## 前置要求

1. **安装 Docker**
   - 确保已安装 Docker Desktop 或 Docker Engine
   - 验证: `docker --version`

2. **安装 Azure CLI**
   - 安装 Azure CLI: https://docs.microsoft.com/cli/azure/install-azure-cli
   - 验证: `az --version`

3. **登录 Azure**
   ```bash
   az login
   ```

4. **获取 ACR 名称**
   - 您的 Azure Container Registry 名称，格式通常为: `yourregistry.azurecr.io`
   - 或者在 Azure 门户中创建新的 ACR

## 使用方法

### 方法 1: 使用自动化脚本（推荐）

```bash
# 给脚本添加执行权限
chmod +x build-and-push.sh

# 执行构建和推送
./build-and-push.sh <ACR_NAME> [TAG] [BUILD_BASE]

# 参数说明:
#   ACR_NAME   - Azure Container Registry 名称（必需）
#   TAG        - 镜像标签，默认为 'latest'
#   BUILD_BASE - 是否构建基础镜像，默认为 'true'
#                设置为 'true', '1', 'yes' 时会构建基础镜像
#                设置为 'false', '0', 'no' 时会跳过基础镜像构建

# 示例
# 构建所有镜像（包括基础镜像）
./build-and-push.sh ndaconreg.azurecr.io v260122 true
./build-and-push.sh ndaconreg.azurecr.io latest

# 跳过基础镜像构建（使用已存在的基础镜像）
./build-and-push.sh ndaconreg.azurecr.io v260122 false
./build-and-push.sh ndaconreg.azurecr.io v260122 no
```

#### 完整构建流程（BUILD_BASE=true 或未指定）

脚本会自动完成以下步骤：
1. 登录到 Azure Container Registry
2. 构建 backend 基础镜像 (`bisheng-backend:base.v8`)
3. 推送 backend 基础镜像到 ACR
4. 构建 backend 应用镜像
5. 推送 backend 应用镜像到 ACR
6. 构建 frontend 镜像
7. 推送 frontend 镜像到 ACR

#### 快速构建流程（BUILD_BASE=false）

当基础镜像已存在时，可以跳过基础镜像构建以加快速度：
1. 登录到 Azure Container Registry
2. 检查本地基础镜像，如果不存在则从 ACR 拉取
3. 构建 backend 应用镜像
4. 推送 backend 应用镜像到 ACR
5. 构建 frontend 镜像
6. 推送 frontend 镜像到 ACR

**注意**: 如果跳过基础镜像构建，脚本会：
- 首先检查本地是否存在 `dataelement/bisheng-backend:base.v8` 镜像
- 如果本地不存在，会尝试从 ACR 拉取 `${ACR_NAME}/bisheng-backend:base.v8`
- 如果 ACR 中也不存在，构建会失败

### 方法 2: 手动执行步骤

如果您希望手动控制每个步骤，可以按照以下顺序执行：

#### 1. 登录到 Azure Container Registry

```bash
az acr login --name <ACR_NAME>
# 例如: az acr login --name myregistry
```

#### 2. 构建和推送 backend 基础镜像

```bash
cd src/backend
docker build -f base.Dockerfile -t <ACR_NAME>/bisheng-backend:base.v8 .
docker push <ACR_NAME>/bisheng-backend:base.v8
```

#### 3. 构建和推送 backend 应用镜像

```bash
# 仍在 src/backend 目录中
docker build -f Dockerfile -t <ACR_NAME>/bisheng-backend:<TAG> .
docker push <ACR_NAME>/bisheng-backend:<TAG>
```

**注意**: 如果 Dockerfile 中引用的基础镜像 `dataelement/bisheng-backend:base.v8` 在本地不存在，需要先拉取或构建它。可以修改 Dockerfile 第一行使用 ACR 中的镜像，或者在构建前先标记本地镜像：

```bash
docker tag <ACR_NAME>/bisheng-backend:base.v8 dataelement/bisheng-backend:base.v8
```

#### 4. 构建和推送 frontend 镜像

```bash
cd ../frontend
docker build -f Dockerfile -t <ACR_NAME>/bisheng-frontend:<TAG> .
docker push <ACR_NAME>/bisheng-frontend:<TAG>
```

## 验证镜像

推送完成后，可以在 Azure 门户或使用命令行验证镜像：

```bash
# 列出所有镜像
az acr repository list --name <ACR_NAME> --output table

# 查看特定仓库的标签
az acr repository show-tags --name <ACR_NAME> --repository bisheng-backend --output table
az acr repository show-tags --name <ACR_NAME> --repository bisheng-frontend --output table
```

## 使用镜像

构建完成后，可以在 docker-compose.yml 或其他配置中使用这些镜像：

```yaml
services:
  backend:
    image: <ACR_NAME>/bisheng-backend:<TAG>
  
  frontend:
    image: <ACR_NAME>/bisheng-frontend:<TAG>
```

## 使用场景建议

### 首次构建或基础镜像有更新
使用默认参数或明确指定 `BUILD_BASE=true`：
```bash
./build-and-push.sh ndaconreg.azurecr.io v2.3.0 true
```

### 仅应用代码更新（基础镜像未变）
如果只是应用代码有更新，而基础镜像没有变化，可以跳过基础镜像构建以节省时间：
```bash
./build-and-push.sh ndaconreg.azurecr.io v2.3.0 false
```

## 注意事项

1. **基础镜像依赖**: backend 的 Dockerfile 依赖于 `dataelement/bisheng-backend:base.v8`。在构建应用镜像前，确保基础镜像已构建并推送。

2. **跳过基础镜像构建**: 当 `BUILD_BASE=false` 时，脚本会：
   - 优先使用本地已有的基础镜像
   - 如果本地不存在，会尝试从 ACR 拉取
   - 如果 ACR 中也不存在，构建会失败，需要先构建基础镜像

3. **网络和代理**: 如果在构建过程中遇到网络问题，可能需要配置代理或使用镜像源。

4. **构建时间**: 
   - 首次构建基础镜像可能需要较长时间（通常 10-30 分钟）
   - 跳过基础镜像构建时，应用镜像构建通常只需要几分钟

5. **镜像大小**: 构建后的镜像可能较大，确保 ACR 有足够的存储空间。

6. **权限**: 确保您的 Azure 账户有推送到 ACR 的权限。

## 故障排除

### 登录失败
```bash
# 确保已登录 Azure
az login

# 检查 ACR 权限
az acr check-health --name <ACR_NAME>
```

### 构建失败
- 检查 Dockerfile 路径是否正确
- 确认所有依赖文件都存在
- 查看详细的构建日志

### 推送失败
- 确认 ACR 名称正确
- 检查网络连接
- 验证 ACR 权限设置

### 网络问题或者拉取失败

可以尝试先直接拉取一下依赖镜像试下，比如
```bash
docker pull node:20-alpine
docker pull nginx:latest
```