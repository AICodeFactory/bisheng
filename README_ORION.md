# Bisheng Orion 部署运维指南

本文档总结 Bisheng 在 Orion 环境下的 Docker 部署、启动、停止与运维操作。

## 前置要求

- 进入 `docker` 目录执行相关命令
- 使用 `docker-compose-orion-20260224.yml` 配置文件

```bash
cd docker
```

---

## 一、Docker 服务管理

### 启动 Docker 服务

```bash
sudo systemctl start docker
```

### 停止 Docker 服务

```bash
sudo systemctl stop docker
```

---

## 二、使用 Docker Compose 启动（推荐）

### 完整启动（一键启动所有服务）

```bash
cd docker
docker compose -f docker-compose-orion-20260224.yml -p bisheng up -d
```

### 分步启动（按依赖顺序）

按依赖顺序依次启动各服务，确保依赖先就绪。

#### 1. 启动基础依赖

```bash
docker compose -f docker-compose-orion-20260224.yml -p bisheng up -d redis
docker compose -f docker-compose-orion-20260224.yml -p bisheng up -d elasticsearch
docker compose -f docker-compose-orion-20260224.yml -p bisheng up -d etcd
docker compose -f docker-compose-orion-20260224.yml -p bisheng up -d minio
docker compose -f docker-compose-orion-20260224.yml -p bisheng up -d milvus
```

#### 2. 启动应用服务

```bash
docker compose -f docker-compose-orion-20260224.yml -p bisheng up -d backend
docker compose -f docker-compose-orion-20260224.yml -p bisheng up -d backend_worker
docker compose -f docker-compose-orion-20260224.yml -p bisheng up -d frontend
```

---

## 三、使用 docker start 启动（容器已存在时）

适用于容器已创建、仅需重启的场景。

### 1. 启动核心依赖

```bash
sudo docker start bisheng-milvus-etcd
sudo docker start bisheng-milvus-minio
sudo docker start bisheng-redis
```

### 2. 等待依赖健康

可使用以下命令查看容器状态和日志：

```bash
# 查看所有容器状态
sudo docker ps -a

# 查看指定容器日志（示例：Redis）
sudo docker logs bisheng-redis
```

根据 healthcheck 间隔调整等待时间，例如：

```bash
sleep 30   # 等待 30 秒（可根据 healthcheck 间隔调整）
```

### 3. 启动其他服务

```bash
sudo docker start bisheng-milvus-standalone
sudo docker start bisheng-backend
sudo docker start bisheng-backend-worker
sudo docker start bisheng-es
sudo docker start bisheng-frontend
```

> **注意**：容器名称以 `docker-compose-orion-20260224.yml` 为准，如 `bisheng-es`（Elasticsearch）、`bisheng-milvus-standalone`（Milvus）。

---

## 四、运维与监控

### 查看容器状态

```bash
sudo docker ps -a
```

### 查看资源占用

```bash
sudo docker stats
```

### 查看日志

```bash
# 查看 backend 日志
docker logs bisheng-backend

# 查看其他服务日志
docker logs <container_name>
```

### 清理不需要的容器

```bash
# 1. 查看所有容器
sudo docker ps -a

# 2. 删除指定容器（谨慎操作）
# sudo docker rm <container_id_or_name>
```

---

## 五、完整重启流程示例

Docker 服务重启后的典型操作流程：

```bash
# 1. 启动 Docker 服务
sudo systemctl start docker

# 2. 检查状态并监控资源
sudo docker ps -a
sudo docker stats

# 3. 使用 docker compose 启动服务（推荐）
cd docker
docker compose -f docker-compose-orion-20260224.yml -p bisheng up -d
```

---

## 六、容器名称对照表

| 服务         | 容器名称                 |
|--------------|--------------------------|
| Redis        | bisheng-redis            |
| Elasticsearch| bisheng-es               |
| etcd         | bisheng-milvus-etcd      |
| MinIO        | bisheng-milvus-minio     |
| Milvus       | bisheng-milvus-standalone|
| Backend      | bisheng-backend          |
| Backend Worker | bisheng-backend-worker |
| Frontend     | bisheng-frontend         |
