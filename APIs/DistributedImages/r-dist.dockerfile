# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
ARG base_image
FROM base_image

# Replace the container-based task management with the distributed library
RUN rm -rf /ai4e_api_tools/task_management
COPY ./APIs/1.0/base-r/task_management /ai4e_api_tools/task_management
COPY ./APIs/1.0/Common/task_management/distributed_api_task.py /ai4e_api_tools/task_management
