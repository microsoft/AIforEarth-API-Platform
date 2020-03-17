#!/bin/bash

AZURE_SUBSCRIPTION_ID=""
INFRASTRUCTURE_RESOURCE_GROUP_NAME="-api-backend-rg"
FUNCTION_APP_NAME="-api-backend-cache-app"
CACHE_MANAGER_FUNCTION_APP_NAME="-api-backend-cache-app"

# Container registry that contains images to be used as services in Kubernetes
SERVICE_CONTAINER_REGISTRY_NAME="containerregistry"
SERVICE_CONTAINER_REGISTRY_RESOURCE_GROUP="-supporting-services-rg"

INSTALL_ISTIO="true"
INSTALL_CUSTOM_METRICS_ADAPTER="false"

INFRASTRUCTURE_LOCATION="eastus"

APP_INSIGHTS_RESOURCE_NAME="-api-backend-app-insights"          # Application Services name

# Container registry required for Azure Functions
CREATE_CONTAINER_REGISTRY="true"
CONTAINER_REGISTRY_NAME="testregistry"                              # ACR name
CONTAINER_REGISTRY_RESOURCE_GROUP="-registry-rg"

AKS_RESOURCE_GROUP_NAME="-api-backend-aks-rg"             # Azure Resource Group Name
AKS_CLUSTER_NAME="-api-backend"                           # AKS Cluster Name
KUBERNETES_VERSION="1.14.8"                                          # Kubernetes version to deploy
DNS_NAME_PREFIX="-api-backend"                            # Custom DNS prefix for your cluster

CLUSTER_GPU_NODE_COUNT=1                                             # Number of GPU nodes to be used for API hosting
CLUSTER_GPU_NODE_VM_SKU="Standard_NC6s_v3"                           # Azure GPU SKU representing the type of VM to use for the nodes
GPU_SCALE_MIN_NODE_COUNT=1                                           # The minimum number of GPU nodes to keep available
GPU_SCALE_MAX_NODE_COUNT=3                                           # The most number of GPU nodes to auto-scale
CLUSTER_CPU_NODE_COUNT=2                                             # Number of CPU nodes to be used for API hosting
CLUSTER_CPU_NODE_VM_SKU="Standard_DS2_v2"                            # Azure CPU SKU representing the type of VM to use for the nodes
CPU_SCALE_MIN_NODE_COUNT=1                                           # The minimum number of CPU nodes to keep available
CPU_SCALE_MAX_NODE_COUNT=3                                           # The most number of CPU nodes to auto-scale

ISTIO_VERSION="1.4.5"                                                # The version of Istio to install
AZURE_CACHE_NAME="-api-backend-cache"                     # Azure Cache Name 

FUNCTION_STORAGE_NAME="testfuncstorage"                     # Azure Function Storage
DEPLOY_CACHE_MANAGER_FUNCTION_APP="true"
DEPLOY_BACKEND_WEBHOOK_FUNCTION_APP="true"
DEPLOY_REQUEST_REPORTER_FUNCTION_APP="true"
DEPLOY_TASK_PROCESS_LOGGER_FUNCTION_APP="true"
BACKEND_WEBHOOK_FUNCTION_APP_NAME="-api-backend-webhook-app"
REQUEST_REPORTER_FUNCTION_APP_NAME="-api-backend-requests-app"
TASK_PROCESS_LOGGER_FUNCTION_APP_NAME="-api-backend-processes-app"

# DO NOT CHANGE
CACHE_MANAGER_IMAGE="containerregistry.azurecr.io/func-cache-manager:1.0"
BACKEND_WEBHOOK_IMAGE="containerregistry.azurecr.io/func-backend-webhook:1.0"
REQUEST_REPORTER_IMAGE="containerregistry.azurecr.io/func-request-reporter:1.0"
TASK_PROCESS_LOGGER_IMAGE="containerregistry.azurecr.io/func-task-process-logger:1.0"
FUNCTION_IMAGE_DOCKER_USER_NAME="containerregistry"
FUNCTION_IMAGE_DOCKER_USER_PASSWORD="Dv/v0gPrnqIwNkEU5JSwZKPZu9lqgrwV"

EVENT_GRID_TOPIC_NAME="-api-backend-grid-topic"           # Event Grid topic name

SERVICE_PRINCIPAL_METRIC_ADAPTER_NAME="-metric-adapter-sp"

API_MANAGEMENT_NAME="-api-backend-api-mgmt"
API_MANAGEMENT_ORGANIZATION_NAME=""
API_MANAGEMENT_ADMIN_EMAIL=""
API_MANAGEMENT_REGION="East US"
API_MANAGEMENT_SKU="Consumption"

SERVICE_URL_PATH="none"