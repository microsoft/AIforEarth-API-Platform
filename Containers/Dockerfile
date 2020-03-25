ARG SERVICE_IMAGE_BASE=mcr.microsoft.com/aiforearth/base-py:latest
FROM ${SERVICE_IMAGE_BASE}

# Replace the local libraries with the distributed libraries required for production use.
COPY ./base-py/task_management/api_task.py /ai4e_api_tools/task_management
COPY ./base-r/task_management/api_task.R /ai4e_api_tools/task_management
COPY ./Common/task_management/distributed_api_task.py /ai4e_api_tools/task_management
