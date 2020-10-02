#!/bin/bash
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

source ./InfrastructureDeployment/setup_env.sh

az account set --subscription $AZURE_SUBSCRIPTION_ID
if [ $? -ne 0 ]
then
    echo "Could not set subscription $AZURE_SUBSCRIPTION_ID."
    echo "deploy_aks.sh failed"
    exit $?
fi

echo "Creating the Azure Function Apps."
if "$DEPLOY_CACHE_MANAGER_FUNCTION_APP" = "true"
then
    echo "Creating the cache manager Azure Function App."
    echo "az functionapp create --name $CACHE_MANAGER_FUNCTION_APP_NAME --storage-account $FUNCTION_STORAGE_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --plan $FUNCTION_APP_NAME-plan --deployment-container-image-name $CACHE_MANAGER_IMAGE --app-insights $APP_INSIGHTS_RESOURCE_NAME "
    az functionapp create --name $CACHE_MANAGER_FUNCTION_APP_NAME --storage-account $FUNCTION_STORAGE_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --plan $FUNCTION_APP_NAME-plan --deployment-container-image-name $CACHE_MANAGER_IMAGE --app-insights $APP_INSIGHTS_RESOURCE_NAME 
    if [ $? -ne 0 ]
    then
        echo "Could not create the $CACHE_MANAGER_FUNCTION_APP_NAME cache manager Azure Function App."
        echo "deploy_cache_manager.sh failed"
        exit $?
    fi

    storageConnectionString=$(az storage account show-connection-string --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --name $FUNCTION_STORAGE_NAME --query connectionString --output tsv)
    if [ $? -ne 0 ]
    then
        echo "Could not get the $FUNCTION_STORAGE_NAME storage connection string."
        echo "deploy_cache_manager.sh failed"
        exit $?
    fi
    
    az functionapp config appsettings set --name $CACHE_MANAGER_FUNCTION_APP_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --settings AzureWebJobsStorage=${storageConnectionString}
    if [ $? -ne 0 ]
    then
        echo "Could not set $CACHE_MANAGER_FUNCTION_APP_NAME application settings."
        echo "deploy_cache_manager.sh failed"
        exit $?
    fi
  
    if [[ "$TRANSPORT_TYPE" = "eventgrid" ]]
    then
        # Get Event Grid Topic URI
        topic_uri=$(az eventgrid topic show -n $EVENT_GRID_TOPIC_NAME -g $INFRASTRUCTURE_RESOURCE_GROUP_NAME --query endpoint --output tsv)
        if [ $? -ne 0 ]
        then
            echo "Could not get the $EVENT_GRID_TOPIC_NAME event grid topic URI."
            echo "deploy_cache_manager.sh failed"
            exit $?
        fi

        # Assign Event Grid Topic URI
        az functionapp config appsettings set --name $CACHE_MANAGER_FUNCTION_APP_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --settings "EVENT_GRID_TOPIC_URI=${topic_uri}"
        if [ $? -ne 0 ]
        then
            echo "Could not set $CACHE_MANAGER_FUNCTION_APP_NAME event grid topic URI."
            echo "deploy_cache_manager.sh failed"
            exit $?
        fi

        # Get Event Grid Topic key
        topic_key=$(az eventgrid topic key list -n $EVENT_GRID_TOPIC_NAME -g $INFRASTRUCTURE_RESOURCE_GROUP_NAME --query key1 --output tsv)
        if [ $? -ne 0 ]
        then
            echo "Could not get the $EVENT_GRID_TOPIC_NAME Event Grid topic key."
            echo "deploy_cache_manager.sh failed"
            exit $?
        fi

        # Assign Event Grid Key
        az functionapp config appsettings set --name $CACHE_MANAGER_FUNCTION_APP_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --settings "EVENT_GRID_KEY=${topic_key}"
        if [ $? -ne 0 ]
        then
            echo "Could not get the $EVENT_GRID_TOPIC_NAME Event Grid key."
            echo "deploy_cache_manager.sh failed"
            exit $?
        fi
    fi

    if [[ "$TRANSPORT_TYPE" = "queue" ]]
    then
        servicebus_connection_string=$(az servicebus namespace authorization-rule keys list --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --namespace-name $SERVICEBUS_NAMESPACE --name RootManageSharedAccessKey --query primaryConnectionString --output tsv)
        # Assign SERVICE_BUS_CONNECTION_STRING
        az functionapp config appsettings set --name $CACHE_MANAGER_FUNCTION_APP_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --settings "SERVICE_BUS_CONNECTION_STRING=${servicebus_connection_string}"
        if [ $? -ne 0 ]
        then
            echo "Could not get the $EVENT_GRID_TOPIC_NAME Event Grid key."
            echo "deploy_cache_manager.sh failed"
            exit $?
        fi
    fi


    # Get Redis URI detail.
    redis_uri_detail=($(az redis show --name $AZURE_CACHE_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --query [hostName,sslPort] --output tsv))
    if [ $? -ne 0 ]
    then
        echo "Could not get the $AZURE_CACHE_NAME Redis URI connection string."
        echo "deploy_cache_manager.sh failed"
        exit $?
    fi

    # Get Redis access key.
    redis_key=$(az redis list-keys --name $AZURE_CACHE_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --query primaryKey --output tsv)
    if [ $? -ne 0 ]
    then
        echo "Could not get the $AZURE_CACHE_NAME Redis access key."
        echo "deploy_cache_manager.sh failed"
        exit $?
    fi

    # Assign the Redis info to an App Setting in the Web App
    az functionapp config appsettings set --name $CACHE_MANAGER_FUNCTION_APP_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --settings "REDIS_GENERAL_TIMEOUT=15000" "REDIS_SYNC_TIMEOUT=15000" "REDIS_CONNECTION_STRING=${redis_uri_detail[0]}:${redis_uri_detail[1]},password=$redis_key,ssl=True,abortConnect=False"
    if [ $? -ne 0 ]
    then
        echo "Could assign the $CACHE_MANAGER_FUNCTION_APP_NAME Redis connection string."
        echo "deploy_cache_manager.sh failed"
        exit $?
    fi


    # Assign REDIS_SYNC_TIMEOUT
    az functionapp config appsettings set --name $CACHE_MANAGER_FUNCTION_APP_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --settings "REDIS_SYNC_TIMEOUT=$REDIS_SYNC_TIMEOUT"
    if [ $? -ne 0 ]
    then
        echo "Could not set REDIS_SYNC_TIMEOUT."
        echo "deploy_backend_queue_function.sh failed"
        exit $?
    fi

    # Assign REDIS_ASYNC_TIMEOUT
    az functionapp config appsettings set --name $CACHE_MANAGER_FUNCTION_APP_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --settings "REDIS_ASYNC_TIMEOUT=$REDIS_ASYNC_TIMEOUT"
    if [ $? -ne 0 ]
    then
        echo "Could not set REDIS_ASYNC_TIMEOUT."
        echo "deploy_backend_queue_function.sh failed"
        exit $?
    fi

    # Assign REDIS_GENERAL_TIMEOUT
    az functionapp config appsettings set --name $CACHE_MANAGER_FUNCTION_APP_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --settings "REDIS_GENERAL_TIMEOUT=$REDIS_GENERAL_TIMEOUT"
    if [ $? -ne 0 ]
    then
        echo "Could not set REDIS_GENERAL_TIMEOUT."
        echo "deploy_backend_queue_function.sh failed"
        exit $?
    fi
fi