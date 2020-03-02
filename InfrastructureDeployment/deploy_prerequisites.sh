#!/bin/bash

source ./InfrastructureDeployment/setup_env.sh

az account set --subscription $AZURE_SUBSCRIPTION_ID
if [ $? -ne 0 ]
then
    echo "Could not set subscription $AZURE_SUBSCRIPTION_ID."
    exit $?
fi

# Create Resource Group
az group create --name $INFRASTRUCTURE_RESOURCE_GROUP_NAME --location $INFRASTRUCTURE_LOCATION

if [ $? -ne 0 ]
then
    echo "Unable to create $INFRASTRUCTURE_RESOURCE_GROUP_NAME resource group."
    exit $?
fi

# Create the Application Insights resource
az resource create --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --resource-type "Microsoft.Insights/components" --name $APP_INSIGHTS_RESOURCE_NAME --location $INFRASTRUCTURE_LOCATION --properties '{"Application_Type":"other"}'

if [ $? -ne 0 ]
then
    echo "Unable to create $APP_INSIGHTS_RESOURCE_NAME Application Insights resource."
    exit $?
fi

# Create an Azure Container Registry
if "$CREATE_CONTAINER_REGISTRY" = "true"
then
    echo "Creating container registry."
    az acr create --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --name $CONTAINER_REGISTRY_NAME --sku Basic

    if [ $? -ne 0 ]
    then
        echo "Unable to create $CONTAINER_REGISTRY_NAME Azure Container Registry."
        exit $?
    fi
else
    echo "Skipping container registry creation."
fi