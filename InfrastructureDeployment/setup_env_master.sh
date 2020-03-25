#!/bin/bash

INSTALL_ISTIO="true"
INSTALL_CUSTOM_METRICS_ADAPTER="false"

INFRASTRUCTURE_RESOURCE_GROUP_NAME="-rg"     # Azure Resource Group
INFRASTRUCTURE_LOCATION="eastus"

APP_INSIGHTS_RESOURCE_NAME="-app-insights"          # Application Services name
AZURE_SUBSCRIPTION_ID=""
CREATE_CONTAINER_REGISTRY="false"
CONTAINER_REGISTRY_NAME=""                              # ACR name
CONTAINER_REGISTRY_RESOURCE_GROUP="_registry_rg"

AKS_RESOURCE_GROUP_NAME="-aks-rg"             # Azure Resource Group Name
AKS_CLUSTER_NAME=""                           # AKS Cluster Name
KUBERNETES_VERSION="1.14.8"                                          # Kubernetes version to deploy
DNS_NAME_PREFIX=""                            # Custom DNS prefix for your cluster

CLUSTER_GPU_NODE_COUNT=1                                             # Number of GPU nodes to be used for API hosting
CLUSTER_GPU_NODE_VM_SKU="Standard_NC6s_v3"                           # Azure GPU SKU representing the type of VM to use for the nodes
GPU_SCALE_MIN_NODE_COUNT=1                                           # The minimum number of GPU nodes to keep available
GPU_SCALE_MAX_NODE_COUNT=3                                           # The most number of GPU nodes to auto-scale
CLUSTER_CPU_NODE_COUNT=2                                             # Number of CPU nodes to be used for API hosting
CLUSTER_CPU_NODE_VM_SKU="Standard_DS2_v2"                            # Azure CPU SKU representing the type of VM to use for the nodes
CPU_SCALE_MIN_NODE_COUNT=1                                           # The minimum number of CPU nodes to keep available
CPU_SCALE_MAX_NODE_COUNT=3                                           # The most number of CPU nodes to auto-scale

ISTIO_VERSION="1.4.5"                                                # The version of Istio to install
AZURE_CACHE_NAME="-cache"                     # Azure Cache Name 

FUNCTION_STORAGE_NAME=""                     # Azure Function Storage
FUNCTION_APP_NAME="-cache-app"                      # Azure Function App Name
DEPLOY_CACHE_MANAGER_FUNCTION_APP="true"
DEPLOY_BACKEND_WEBHOOK_FUNCTION_APP="true"
DEPLOY_REQUEST_REPORTER_FUNCTION_APP="true"
DEPLOY_TASK_PROCESS_LOGGER_FUNCTION_APP="true"
CACHE_MANAGER_FUNCTION_APP_NAME="-cache-app"
BACKEND_WEBHOOK_FUNCTION_APP_NAME="-webhook-app"
REQUEST_REPORTER_FUNCTION_APP_NAME="-requests-app"
TASK_PROCESS_LOGGER_FUNCTION_APP_NAME="-processes-app"

CACHE_MANAGER_IMAGE=".azurecr.io/func-cache-manager:1.0"
BACKEND_WEBHOOK_IMAGE=".azurecr.io/func-backend-webhook:1.0"
REQUEST_REPORTER_IMAGE=".azurecr.io/func-request-reporter:1.0"
TASK_PROCESS_LOGGER_IMAGE=".azurecr.io/func-task-process-logger:1.0"

EVENT_GRID_TOPIC_NAME="-grid-topic"           # Event Grid topic name

SERVICE_PRINCIPAL_METRIC_ADAPTER_NAME="-metric-adapter-sp"

API_MANAGEMENT_NAME="-api-mgmt"
API_MANAGEMENT_ORGANIZATION_NAME="AI for Earth"
API_MANAGEMENT_ADMIN_EMAIL=""
API_MANAGEMENT_REGION="East US"
API_MANAGEMENT_SKU="Consumption"

SERVICE_URL_PATH="none"