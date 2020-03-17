#!/bin/bash

source ./InfrastructureDeployment/setup_env.sh

az account set --subscription $AZURE_SUBSCRIPTION_ID
if [ $? -ne 0 ]
then
    echo "Could not set subscription $AZURE_SUBSCRIPTION_ID."
    echo "deploy_prerequisites.sh failed"
    exit $?
fi

# Create Resource Group
az group create --name $INFRASTRUCTURE_RESOURCE_GROUP_NAME --location $INFRASTRUCTURE_LOCATION

if [ $? -ne 0 ]
then
    echo "Unable to create $INFRASTRUCTURE_RESOURCE_GROUP_NAME resource group."
    echo "deploy_prerequisites.sh failed"
    exit $?
fi

# Create the Application Insights resource
app_insights_data=$(az resource create --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --resource-type "Microsoft.Insights/components" --name $APP_INSIGHTS_RESOURCE_NAME --location $INFRASTRUCTURE_LOCATION --properties '{"Application_Type":"other"}')

if [ $? -ne 0 ]
then
    echo "Unable to create $APP_INSIGHTS_RESOURCE_NAME Application Insights resource."
    echo "deploy_prerequisites.sh failed"
    exit $?
fi

inst_key=$(echo $app_insights_data | jq '.properties.InstrumentationKey' | sed -e 's/^"//' -e 's/"$//')

echo "-----------------------------------------------------------"
echo "APPLICATION INSIGHTS INSTRUMENTATION KEY - SAVE!"
echo "APPINSIGHTS_INSTRUMENTATIONKEY: $inst_key"
echo "-----------------------------------------------------------"
read -p "Press enter to continue"

# Create an Azure Container Registry
if "$CREATE_CONTAINER_REGISTRY" = "true"
then
    echo "Creating container registry."
    az group create --name $CONTAINER_REGISTRY_RESOURCE_GROUP --location $INFRASTRUCTURE_LOCATION
    az acr create --resource-group $CONTAINER_REGISTRY_RESOURCE_GROUP --name $CONTAINER_REGISTRY_NAME --sku Basic

    if [ $? -ne 0 ]
    then
        echo "Unable to create $CONTAINER_REGISTRY_NAME Azure Container Registry."
        echo "deploy_prerequisites.sh failed"
        exit $?
    fi
else
    echo "Skipping container registry creation."
fi

az storage account create -n $FUNCTION_STORAGE_NAME -g $INFRASTRUCTURE_RESOURCE_GROUP_NAME -l $INFRASTRUCTURE_LOCATION --sku Standard_LRS

if [ $? -ne 0 ]
then
    echo "Unable to create $FUNCTION_STORAGE_NAME Azure Function storage account."
    echo "deploy_prerequisites.sh failed"
    exit $?
fi
