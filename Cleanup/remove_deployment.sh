#!/bin/bash

AZURE_SUBSCRIPTION_ID=""
INFRASTRUCTURE_RESOURCE_GROUP_NAME="-api-backend-rg"
CONTAINER_REGISTRY_RESOURCE_GROUP="-registry-rg"
AKS_RESOURCE_GROUP_NAME="-api-backend-aks-rg"
AKS_CLUSTER_NAME="-api-backend"

az group delete --name $INFRASTRUCTURE_RESOURCE_GROUP_NAME --subscription $AZURE_SUBSCRIPTION_ID --no-wait --yes
az group delete --name $CONTAINER_REGISTRY_RESOURCE_GROUP --subscription $AZURE_SUBSCRIPTION_ID --no-wait --yes
az group delete --name $AKS_RESOURCE_GROUP_NAME --subscription $AZURE_SUBSCRIPTION_ID --no-wait --yes

