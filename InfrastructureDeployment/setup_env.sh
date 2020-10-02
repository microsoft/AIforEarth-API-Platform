#!/bin/bash

AZURE_SUBSCRIPTION_ID=""
DEPLOYMENT_PREFIX="api-system"
# Storage account names must be fewer than 24 characters.
FUNCTION_STORAGE_NAME="apisystemfuncstore"                     # Azure Function Storage
CONTAINER_REGISTRY_NAME="apiregistry"                            
CONTAINER_REGISTRY_RESOURCE_GROUP="api-container-registry-rg"

CREATE_CONTAINER_REGISTRY="true"
TRANSPORT_TYPE="queue" # queue or eventgrid
INSTALL_ISTIO="true"
INSTALL_NVIDIA_DEVICE_PLUGIN="true"
ENABLE_AKS_MANAGED_IDENTITY='false'
INSTALL_CUSTOM_METRICS_ADAPTER="false"
DEPLOY_CACHE_MANAGER_FUNCTION_APP="true"
DEPLOY_BACKEND_WEBHOOK_FUNCTION_APP="false"
DEPLOY_BACKEND_QUEUE_FUNCTION_APP="true"
DEPLOY_REQUEST_REPORTER_FUNCTION_APP="false"
DEPLOY_TASK_PROCESS_LOGGER_FUNCTION_APP="false"

INFRASTRUCTURE_RESOURCE_GROUP_NAME="$DEPLOYMENT_PREFIX-rg"     # Azure Resource Group
INFRASTRUCTURE_LOCATION="eastus"

APP_INSIGHTS_RESOURCE_NAME="$DEPLOYMENT_PREFIX-app-insights"          # Application Services name

AKS_RESOURCE_GROUP_NAME="$DEPLOYMENT_PREFIX-aks-rg"             # Azure Resource Group Name
AKS_CLUSTER_NAME="$DEPLOYMENT_PREFIX-aks"                           # AKS Cluster Name

KUBERNETES_VERSION="1.16.13"                                            # Kubernetes version to deploy
DNS_NAME_PREFIX="$DEPLOYMENT_PREFIX"                            # Custom DNS prefix for your cluster
HTTP_SCHEME="http"

# Node keys must be lowercase.
declare -A node_skus=( ["e8sv3"]="Standard_E8s_v3")
declare -a pool_order=("e8sv3")
declare -A node_start_count=( ["e8sv3"]="1")
declare -A node_min_count=( ["e8sv3"]="1")
declare -A node_max_count=( ["e8sv3"]="3")
# Cannot have a node taint on the first node pool.
# IMPORTANT: tolerations must be entered in ./Cluster/config/nvidia-device-plugin-ds.yaml
#declare -A node_taints=( ["nc6sv3"]="sku=NC6sv3:NoSchedule" ["nc6"]="sku=NC6:NoSchedule")

ISTIO_VERSION="1.6.3"                                                # The version of Istio to install

AZURE_CACHE_NAME="$DEPLOYMENT_PREFIX-cache"                          # Azure Cache Name 
FUNCTION_APP_NAME="$DEPLOYMENT_PREFIX-cache-app"                     # Azure Function App Name

CACHE_MANAGER_FUNCTION_APP_NAME="$DEPLOYMENT_PREFIX-cache-mgr-app"
BACKEND_WEBHOOK_FUNCTION_APP_NAME="$DEPLOYMENT_PREFIX-webhook-app"
BACKEND_QUEUE_FUNCTION_APP_NAME="$DEPLOYMENT_PREFIX-queue-app"
REQUEST_REPORTER_FUNCTION_APP_NAME="$DEPLOYMENT_PREFIX-requests-app"
TASK_PROCESS_LOGGER_FUNCTION_APP_NAME="$DEPLOYMENT_PREFIX-processes-app"

CACHE_MANAGER_IMAGE="mcr.microsoft.com/aiforearth/func-cache-manager:1.1"
BACKEND_QUEUE_IMAGE="mcr.microsoft.com/aiforearth/func-backend-queue:1.0"
BACKEND_WEBHOOK_IMAGE="mcr.microsoft.com/aiforearth/func-backend-webhook:1.0"
REQUEST_REPORTER_IMAGE="mcr.microsoft.com/aiforearth/func-request-reporter:1.0"
TASK_PROCESS_LOGGER_IMAGE="mcr.microsoft.com/aiforearth/func-task-process-logger:1.0"


EVENT_GRID_TOPIC_NAME="$DEPLOYMENT_PREFIX-grid-topic"           # Event Grid topic name

SERVICEBUS_NAMESPACE="$DEPLOYMENT_PREFIX-sb-namespace"
SERVICEBUS_QUEUE_MAX_DELIVERY_COUNT=1440
# Queue names should match the API url templates (path).
declare -a queue_name_paths=("/v1/mypath/myapi1" "/v1/mypath/myapi2")

SERVICE_PRINCIPAL_METRIC_ADAPTER_NAME="$DEPLOYMENT_PREFIX-metric-adapter-sp"

REDIS_GENERAL_TIMEOUT=20000
REDIS_SYNC_TIMEOUT=60000
REDIS_ASYNC_TIMEOUT=60000
QUEUE_RETRY_DELAY_MS=60000

API_MANAGEMENT_NAME="$DEPLOYMENT_PREFIX-api-mgmt"
API_MANAGEMENT_ORGANIZATION_NAME="Your org name"
API_MANAGEMENT_ADMIN_EMAIL="valid@email.com"
API_MANAGEMENT_REGION="East US"
API_MANAGEMENT_SKU="Consumption"

SERVICE_URL_PATH="none"