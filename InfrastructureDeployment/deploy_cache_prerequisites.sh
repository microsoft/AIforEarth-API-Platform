#!/bin/bash
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

source ./InfrastructureDeployment/setup_env.sh

az account set --subscription $AZURE_SUBSCRIPTION_ID
if [ $? -ne 0 ]
then
    echo "Could not set subscription $AZURE_SUBSCRIPTION_ID."
    echo "deploy_prerequisites.sh failed"
    exit $?
fi

# Create cache.
echo "Creating Redis cache."
az redis create --name $AZURE_CACHE_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --location $INFRASTRUCTURE_LOCATION --vm-size C0 --sku Basic --query [hostName,sslPort] --output tsv
if [ $? -ne 0 ]
then
    echo "Could not create the Redis cache $AZURE_CACHE_NAME."
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
