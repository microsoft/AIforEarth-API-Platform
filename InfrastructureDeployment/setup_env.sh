#!/bin/bash

FUNCTION_IMAGE_DOCKER_USER_NAME=""
FUNCTION_IMAGE_DOCKER_USER_PASSWORD=""

AZURE_SUBSCRIPTION_ID=""
DEPLOYMENT_PREFIX="ai4e-api-backend-master-test-2"
# Storage account names must be fewer than 24 characters.
FUNCTION_STORAGE_NAME=""                     # Azure Function Storage
CONTAINER_REGISTRY_NAME=""                              # ACR name
CONTAINER_REGISTRY_RESOURCE_GROUP=""


INSTALL_ISTIO="true"
INSTALL_CUSTOM_METRICS_ADAPTER="false"

INFRASTRUCTURE_RESOURCE_GROUP_NAME="$DEPLOYMENT_PREFIX-rg"     # Azure Resource Group
INFRASTRUCTURE_LOCATION="eastus"

APP_INSIGHTS_RESOURCE_NAME="$DEPLOYMENT_PREFIX-app-insights"          # Application Services name
CREATE_CONTAINER_REGISTRY="false"

AKS_RESOURCE_GROUP_NAME="$DEPLOYMENT_PREFIX-aks-rg"             # Azure Resource Group Name
AKS_CLUSTER_NAME="$DEPLOYMENT_PREFIX"                           # AKS Cluster Name
KUBERNETES_VERSION="1.15.10"                                          # Kubernetes version to deploy
DNS_NAME_PREFIX="$DEPLOYMENT_PREFIX"                            # Custom DNS prefix for your cluster

CLUSTER_GPU_NODE_COUNT=2                                             # Number of GPU nodes to be used for API hosting
CLUSTER_GPU_NODE_VM_SKU="Standard_NC6"                               # Azure GPU SKU representing the type of VM to use for the nodes
GPU_SCALE_MIN_NODE_COUNT=2                                           # The minimum number of GPU nodes to keep available
GPU_SCALE_MAX_NODE_COUNT=2                                           # The most number of GPU nodes to auto-scale
CLUSTER_CPU_NODE_COUNT=2                                             # Number of CPU nodes to be used for API hosting
CLUSTER_CPU_NODE_VM_SKU="Standard_DS2_v2"                            # Azure CPU SKU representing the type of VM to use for the nodes
CPU_SCALE_MIN_NODE_COUNT=2                                           # The minimum number of CPU nodes to keep available
CPU_SCALE_MAX_NODE_COUNT=2                                           # The most number of CPU nodes to auto-scale

ISTIO_VERSION="1.4.5"                                                # The version of Istio to install
AZURE_CACHE_NAME="$DEPLOYMENT_PREFIX-cache"                     # Azure Cache Name 

FUNCTION_APP_NAME="$DEPLOYMENT_PREFIX-cache-app"                      # Azure Function App Name
DEPLOY_CACHE_MANAGER_FUNCTION_APP="true"
DEPLOY_BACKEND_WEBHOOK_FUNCTION_APP="true"
DEPLOY_REQUEST_REPORTER_FUNCTION_APP="true"
DEPLOY_TASK_PROCESS_LOGGER_FUNCTION_APP="true"
CACHE_MANAGER_FUNCTION_APP_NAME="$DEPLOYMENT_PREFIX-cache-app"
BACKEND_WEBHOOK_FUNCTION_APP_NAME="$DEPLOYMENT_PREFIX-webhook-app"
REQUEST_REPORTER_FUNCTION_APP_NAME="$DEPLOYMENT_PREFIX-requests-app"
TASK_PROCESS_LOGGER_FUNCTION_APP_NAME="$DEPLOYMENT_PREFIX-processes-app"

CACHE_MANAGER_IMAGE="mcr.microsoft.com/aiforearth/func-cache-manager:1.0"
BACKEND_WEBHOOK_IMAGE="mcr.microsoft.com/aiforearth/func-backend-webhook:1.0"
REQUEST_REPORTER_IMAGE="mcr.microsoft.com/aiforearth/func-request-reporter:1.0"
TASK_PROCESS_LOGGER_IMAGE="mcr.microsoft.com/aiforearth/func-task-process-logger:1.0"

EVENT_GRID_TOPIC_NAME="$DEPLOYMENT_PREFIX-grid-topic"           # Event Grid topic name

SERVICE_PRINCIPAL_METRIC_ADAPTER_NAME="$DEPLOYMENT_PREFIX-metric-adapter-sp"

API_MANAGEMENT_NAME="$DEPLOYMENT_PREFIX-api-mgmt"
API_MANAGEMENT_ORGANIZATION_NAME="AI for Earth"
API_MANAGEMENT_ADMIN_EMAIL="test@microsoft.com"
API_MANAGEMENT_REGION="East US"
API_MANAGEMENT_SKU="Consumption"

SERVICE_URL_PATH="none"