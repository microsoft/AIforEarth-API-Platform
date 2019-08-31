# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
ARG version
ARG tag
FROM ai4eapibackendv2gpu3registry.azurecr.io/camera-trap/1.0-detection-sync:2

# Replace the container-based task management with the distributed library
RUN rm -rf /ai4e_api_tools/task_management
COPY ./1.0/base-py/ai4e_service.py /ai4e_api_tools
COPY ./1.0/base-py/task_management /ai4e_api_tools/task_management
COPY ./1.0/Common/task_management/distributed_api_task.py /ai4e_api_tools/task_management