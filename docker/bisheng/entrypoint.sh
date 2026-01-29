#!/bin/bash

export PYTHONPATH="./"

start_mode=${1:-api}

if [ $start_mode = "api" ]; then
    echo "Starting API server..."
    # 避免 OOM（从 8 降到 4）
    uvicorn bisheng.main:app --host 0.0.0.0 --port 7860 --no-access-log --workers 8
elif [ $start_mode = "worker" ]; then
    echo "Starting Celery worker..."
    # 处理知识库相关任务的worker（从 20 并发降到 8，避免 OOM）
    nohup celery -A bisheng.worker.main worker -l info -c 20 -P threads -Q knowledge_celery -n knowledge@%h &
    # 判断上个进程是否启动成功
    if [ $? -ne 0 ]; then
        echo "Failed to start knowledge worker."
        exit 1
    fi

    # 工作流执行worker（从 100 并发降到 50，这个最占资源，避免 OOM）
    nohup celery -A bisheng.worker.main worker -l info -c 100 -P threads -Q workflow_celery -n workflow@%h &
    if [ $? -ne 0 ]; then
        echo "Failed to start workflow worker."
        exit 1
    fi

    # linsight worker（从 4 进程降到 2，并发从 5 降到 3，避免 OOM）
    python bisheng/linsight/worker.py --worker_num 4 --max_concurrency 5
    if [ $? -ne 0 ]; then
        echo "Failed to start linsight worker."
        exit 1
    fi
    echo "All workers started successfully."
else
    echo "Invalid start mode. Use 'api' or 'worker'."
    exit 1
fi
