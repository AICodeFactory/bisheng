# 1. 登录 Azure
# az login

# 2. 设置资源组和容器应用名称
RESOURCE_GROUP="DefaultResourceGroup-EUS2"
CONTAINER_APP_NAME="bisheng-backend-test"

# 3. 进入容器执行命令
az containerapp exec \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --command "/bin/sh"

# # 或者直接执行单个命令
# az containerapp exec \
#   --name $CONTAINER_APP_NAME \
#   --resource-group $RESOURCE_GROUP \
#   --command "ls -la /app/bisheng"

# 查看配置文件内容
# az containerapp exec \
#   --name $CONTAINER_APP_NAME \
#   --resource-group $RESOURCE_GROUP \
#   --command "cat /app/bisheng/config.yaml"