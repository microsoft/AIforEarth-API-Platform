#!/bin/bash

source ./InfrastructureDeployment/setup_env.sh

if "$DEPLOY_BACKEND_QUEUE_FUNCTION_APP" = "true"
then
    az aks get-credentials --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME

    echo "Getting the ingress ip."
    ingress_ip=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ $? -ne 0 ]
    then
        echo "Could not get the istio-ingressgateway ip."
        exit $?
    fi

    for queue_name_path in "${queue_name_paths[@]}"
    do
        cleaned_url_template=${queue_name_path//\//''}
        echo "Creating the backend queue Azure Function App."
        function_app_name="$BACKEND_QUEUE_FUNCTION_APP_NAME-$cleaned_url_template"
        az functionapp create --name $function_app_name --storage-account $FUNCTION_STORAGE_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --plan $FUNCTION_APP_NAME-plan --deployment-container-image-name $BACKEND_QUEUE_IMAGE --app-insights $APP_INSIGHTS_RESOURCE_NAME 
        if [ $? -ne 0 ]
        then
            echo "Could not create the $function_app_name backend queue Azure Function App."
            echo "deploy_backend_queue_function.sh failed"
            exit $?
        fi

        storageConnectionString=$(az storage account show-connection-string --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --name $FUNCTION_STORAGE_NAME --query connectionString --output tsv)
        if [ $? -ne 0 ]
        then
            echo "Could not get the $FUNCTION_STORAGE_NAME storage connection string."
            echo "deploy_backend_queue_function.sh failed"
            exit $?
        fi

        az functionapp config appsettings set --name $function_app_name --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --settings AzureWebJobsStorage=${storageConnectionString}
        if [ $? -ne 0 ]
        then
            echo "Could not set $function_app_name application settings."
            echo "deploy_backend_queue_function.sh failed"
            exit $?
        fi

        # Get Redis URI detail.
        redis_uri_detail=($(az redis show --name $AZURE_CACHE_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --query [hostName,sslPort] --output tsv))
        if [ $? -ne 0 ]
        then
            echo "Could not get the $AZURE_CACHE_NAME Redis URI connection string."
            echo "deploy_backend_queue_function.sh failed"
            exit $?
        fi

        # Get Redis access key.
        redis_key=$(az redis list-keys --name $AZURE_CACHE_NAME --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --query primaryKey --output tsv)
        if [ $? -ne 0 ]
        then
            echo "Could not get the $AZURE_CACHE_NAME Redis access key."
            echo "deploy_backend_queue_function.sh failed"
            exit $?
        fi

        # Assign the Redis connection string to an App Setting in the Web App
        az functionapp config appsettings set --name $function_app_name --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --settings "REDIS_CONNECTION_STRING=${redis_uri_detail[0]}:${redis_uri_detail[1]},password=$redis_key,ssl=True,abortConnect=False,sslprotocols=tls12"
        if [ $? -ne 0 ]
        then
            echo "Could assign the $function_app_name Redis connection string."
            echo "deploy_backend_queue_function.sh failed"
            exit $?
        fi

        # Assign REDIS_SYNC_TIMEOUT
        az functionapp config appsettings set --name $function_app_name --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --settings "REDIS_SYNC_TIMEOUT=$REDIS_SYNC_TIMEOUT"
        if [ $? -ne 0 ]
        then
            echo "Could not set REDIS_SYNC_TIMEOUT."
            echo "deploy_backend_queue_function.sh failed"
            exit $?
        fi

        # Assign REDIS_ASYNC_TIMEOUT
        az functionapp config appsettings set --name $function_app_name --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --settings "REDIS_ASYNC_TIMEOUT=$REDIS_ASYNC_TIMEOUT"
        if [ $? -ne 0 ]
        then
            echo "Could not set REDIS_ASYNC_TIMEOUT."
            echo "deploy_backend_queue_function.sh failed"
            exit $?
        fi

        # Assign REDIS_GENERAL_TIMEOUT
        az functionapp config appsettings set --name $function_app_name --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --settings "REDIS_GENERAL_TIMEOUT=$REDIS_GENERAL_TIMEOUT"
        if [ $? -ne 0 ]
        then
            echo "Could not set REDIS_GENERAL_TIMEOUT."
            echo "deploy_backend_queue_function.sh failed"
            exit $?
        fi

        # Assign the SERVICE_BUS_QUEUE name
        cleaned_ip=${ingress_ip//\./''}
        queue_name="$HTTP_SCHEME$cleaned_ip$cleaned_url_template"
        echo $queue_name

        az functionapp config appsettings set --name $function_app_name --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --settings "SERVICE_BUS_QUEUE=$queue_name"
        if [ $? -ne 0 ]
        then
            echo "Could not set SERVICE_BUS_QUEUE."
            echo "deploy_backend_queue_function.sh failed"
            exit $?
        fi

        servicebus_connection_string=$(az servicebus namespace authorization-rule keys list --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --namespace-name $SERVICEBUS_NAMESPACE --name RootManageSharedAccessKey --query primaryConnectionString --output tsv)
        # Assign AzureWebJobsServiceBus
        az functionapp config appsettings set --name $function_app_name --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --settings "AzureWebJobsServiceBus=${servicebus_connection_string}"
        if [ $? -ne 0 ]
        then
            echo "Could not set AzureWebJobsServiceBus."
            echo "deploy_cache_manager.sh failed"
            exit $?
        fi

        az functionapp config appsettings set --name $function_app_name --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --settings "QUEUE_RETRY_DELAY_MS=$QUEUE_RETRY_DELAY_MS"
        if [ $? -ne 0 ]
        then
            echo "Could not set QUEUE_RETRY_DELAY_MS."
            echo "deploy_cache_manager.sh failed"
            exit $?
        fi
    done
fi
