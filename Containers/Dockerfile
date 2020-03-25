ARG SERVICE_IMAGE_BASE=mcr.microsoft.com/aiforearth/base-py:latest
ARG LANGUAGE=py
ARG COPY_PATH="./base-$LANGUAGE/task_management"
FROM ${SERVICE_IMAGE_BASE}

# Replace the local libraries with the distributed libraries required for production use.
COPY ${COPY_PATH} /ai4e_api_tools/task_management
COPY ./Common/task_management/distributed_api_task.py /ai4e_api_tools/task_management
