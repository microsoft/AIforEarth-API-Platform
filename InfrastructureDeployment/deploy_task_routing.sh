#!/bin/bash

source ./InfrastructureDeployment/setup_env.sh

# Create cache.
echo "Creating Redis cache."
az redis create --name $AZURE_CACHE_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --location $INFRASTRUCTURE_LOCATION --vm-size C0 --sku Basic --query [hostName,sslPort] --output tsv
if [ $? -ne 0 ]
then
    echo "Could not create the Redis cache $AZURE_CACHE_NAME."
    exit $?
fi

# Enable the Event Grid resource provider.
az provider register --namespace Microsoft.EventGrid
if [ $? -ne 0 ]
then
    echo "Could not enable the event grid resource provider."
    exit $?
fi

# Create an Event Grid Topic
echo "Creating the Event Grid topic."
az eventgrid topic create --name $EVENT_GRID_TOPIC_NAME -l $INFRASTRUCTURE_LOCATION -g $INFRASTRUCTURE_RESOURCE_GROUP_NAME
if [ $? -ne 0 ]
then
    echo "Could not create the Event Grid topic $EVENT_GRID_TOPIC_NAME."
    exit $?
fi

# A storage account is required for Azure Functions.
echo "Creating an Azure Storage Account for the Azure Functions."
az storage account create --name $FUNCTION_STORAGE_NAME --location $INFRASTRUCTURE_LOCATION --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --sku Standard_LRS
if [ $? -ne 0 ]
then
    echo "Could not create the Azure Storage Account $FUNCTION_STORAGE_NAME for the Azure Functions."
    exit $?
fi

# Create an Azure Function App to host the execution of the functions.
echo "Creating the Azure Function App Plan."
az functionapp plan create --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --name $FUNCTION_APP_NAME-plan --location $INFRASTRUCTURE_LOCATION --number-of-workers 1 --sku EP1 --is-linux
if [ $? -ne 0 ]
then
    echo "Could not create the $FUNCTION_APP_NAME-plan Azure Function App Plan."
    exit $?
fi