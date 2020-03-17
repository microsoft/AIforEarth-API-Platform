#!/bin/bash

source ./InfrastructureDeployment/setup_env.sh

# Create Event Grid Subscription
backend_webhook_fn=$(az rest --method post --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.Web/sites/$BACKEND_WEBHOOK_FUNCTION_APP_NAME/functions/BackendWebhook/listKeys?api-version=2018-11-01")
iteration=1
while [ $? -ne 0 ]
do
    if [ $iteration -ge 10 ]
    then
        echo "Could not get the backend webhook keys."
        echo "deploy_event_grid_subscription.sh failed"
        exit $?
    fi

    echo "Could not get the backend webhook keys. Retrying in 10 seconds."
    iteration=$(($iteration+1))
    echo "Try $iteration of 10"
    sleep 10
    backend_webhook_fn=$(az rest --method post --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.Web/sites/$BACKEND_WEBHOOK_FUNCTION_APP_NAME/functions/BackendWebhook/listKeys?api-version=2018-11-01")
done

backend_webhook_fn_key=$(echo $backend_webhook_fn | jq '.default' | sed -e 's/^"//' -e 's/"$//')
backend_webhook_fn_url="https://$BACKEND_WEBHOOK_FUNCTION_APP_NAME.azurewebsites.net/api/BackendWebhook?code=$backend_webhook_fn_key"

az eventgrid event-subscription create --name "cache-webhook"  --source-resource-id /subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.EventGrid/topics/$EVENT_GRID_TOPIC_NAME --endpoint $backend_webhook_fn_url
iteration=1
while [ $? -ne 0 ]
do
    if [ $iteration -ge 10 ]
    then
        echo "Could not create the Event Grid Subscription."
        echo "deploy_event_grid_subscription.sh failed"
        exit $?
    fi

    echo "Could not create the Event Grid Subscription. Retrying in 10 seconds."
    iteration=$(($iteration+1))
    echo "Try $iteration of 10"
    sleep 10
    az eventgrid event-subscription create --name "cache-webhook"  --source-resource-id /subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.EventGrid/topics/$EVENT_GRID_TOPIC_NAME --endpoint $backend_webhook_fn_url
done