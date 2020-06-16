#!/bin/bash

source ./InfrastructureDeployment/setup_env.sh

if "$DEPLOY_TASK_PROCESS_LOGGER_FUNCTION_APP" = "true"
then
    echo "Creating the task process logger Azure Function App."
    az functionapp create --name $TASK_PROCESS_LOGGER_FUNCTION_APP_NAME --storage-account $FUNCTION_STORAGE_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --plan $FUNCTION_APP_NAME-plan --deployment-container-image-name $TASK_PROCESS_LOGGER_IMAGE --app-insights $APP_INSIGHTS_RESOURCE_NAME  
    if [ $? -ne 0 ]
    then
        echo "Could not create the $TASK_PROCESS_LOGGER_FUNCTION_APP_NAME task process logger Azure Function App."
        echo "deploy_task_process_logger_function.sh failed"
        exit $?
    fi

    storageConnectionString=$(az storage account show-connection-string --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --name $FUNCTION_STORAGE_NAME --query connectionString --output tsv)
    if [ $? -ne 0 ]
    then
        echo "Could not get the $FUNCTION_STORAGE_NAME storage connection string."
        echo "deploy_task_process_logger_function.sh failed"
        exit $?
    fi

    az functionapp config appsettings set --name $TASK_PROCESS_LOGGER_FUNCTION_APP_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --settings AzureWebJobsStorage=${storageConnectionString}
    if [ $? -ne 0 ]
    then
        echo "Could not set $TASK_PROCESS_LOGGER_FUNCTION_APP_NAME application settings."
        echo "deploy_task_process_logger_function.sh failed"
        exit $?
    fi

    # Get Event Grid Topic URI
    topic_uri=$(az eventgrid topic show -n $EVENT_GRID_TOPIC_NAME -g $INFRASTRUCTURE_RESOURCE_GROUP_NAME --query endpoint --output tsv)
    if [ $? -ne 0 ]
    then
        echo "Could not get the $EVENT_GRID_TOPIC_NAME event grid topic URI."
        echo "deploy_task_process_logger_function.sh failed"
        exit $?
    fi

    # Assign Event Grid Topic URI
    az functionapp config appsettings set --name $TASK_PROCESS_LOGGER_FUNCTION_APP_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --settings "EVENT_GRID_TOPIC_URI=${topic_uri}"
    if [ $? -ne 0 ]
    then
        echo "Could not set $TASK_PROCESS_LOGGER_FUNCTION_APP_NAME event grid topic URI."
        echo "deploy_task_process_logger_function.sh failed"
        exit $?
    fi

    # Get Event Grid Topic key
    topic_key=$(az eventgrid topic key list -n $EVENT_GRID_TOPIC_NAME -g $INFRASTRUCTURE_RESOURCE_GROUP_NAME --query key1 --output tsv)
    if [ $? -ne 0 ]
    then
        echo "Could not get the $EVENT_GRID_TOPIC_NAME Event Grid topic key."
        echo "deploy_task_process_logger_function.sh failed"
        exit $?
    fi

    # Assign Event Grid Key
    az functionapp config appsettings set --name $TASK_PROCESS_LOGGER_FUNCTION_APP_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --settings "EVENT_GRID_KEY=${topic_key}"
    if [ $? -ne 0 ]
    then
        echo "Could not get the $EVENT_GRID_TOPIC_NAME Event Grid key."
        echo "deploy_task_process_logger_function.sh failed"
        exit $?
    fi

    # Get Redis URI detail.
    redis_uri_detail=($(az redis show --name $AZURE_CACHE_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --query [hostName,sslPort] --output tsv))
    if [ $? -ne 0 ]
    then
        echo "Could not get the $AZURE_CACHE_NAME Redis URI connection string."
        echo "deploy_task_process_logger_function.sh failed"
        exit $?
    fi

    # Get Redis access key.
    redis_key=$(az redis list-keys --name $AZURE_CACHE_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --query primaryKey --output tsv)
    if [ $? -ne 0 ]
    then
        echo "Could not get the $AZURE_CACHE_NAME Redis access key."
        echo "deploy_task_process_logger_function.sh failed"
        exit $?
    fi

    # Assign the Redis connection string to an App Setting in the Web App
    az functionapp config appsettings set --name $TASK_PROCESS_LOGGER_FUNCTION_APP_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --settings "REDIS_CONNECTION_STRING=${redis_uri_detail[0]}:${redis_uri_detail[1]},password=$redis_key,ssl=True,abortConnect=False"
    if [ $? -ne 0 ]
    then
        echo "Could assign the $TASK_PROCESS_LOGGER_FUNCTION_APP_NAME Redis connection string."
        echo "deploy_task_process_logger_function.sh failed"
        exit $?
    fi
fi