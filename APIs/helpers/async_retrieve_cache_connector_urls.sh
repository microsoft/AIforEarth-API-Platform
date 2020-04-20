#!/bin/bash

AZURE_SUBSCRIPTION_ID=""
INFRASTRUCTURE_RESOURCE_GROUP_NAME="-api-backend-rg"
FUNCTION_APP_NAME="-api-backend-cache-app"
CACHE_MANAGER_FUNCTION_APP_NAME="-api-backend-cache-app"

get_key=$(az rest --method post --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.Web/sites/$FUNCTION_APP_NAME/functions/CacheConnectorGet/listKeys?api-version=2018-11-01")
if [ $? -ne 0 ]
then
    echo "Could not get the CacheConnectorGet Azure Functions key."
    exit $?
fi

get_key=$(echo $get_key | jq '.default' | sed -e 's/^"//' -e 's/"$//')
get_fun_url="https://$CACHE_MANAGER_FUNCTION_APP_NAME.azurewebsites.net/api/CacheConnectorGet?code=$get_key"
echo "CACHE_CONNECTOR_GET_URI: \"$get_fun_url\""

upsert_key=$(az rest --method post --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.Web/sites/$FUNCTION_APP_NAME/functions/CacheConnectorUpsert/listKeys?api-version=2018-11-01")
if [ $? -ne 0 ]
then
    echo "Could not get the CacheConnectorUpsert Azure Functions key."
    exit $?
fi

upsert_key=$(echo $upsert_key | jq '.default' | sed -e 's/^"//' -e 's/"$//')
upsert_fun_url="https://$CACHE_MANAGER_FUNCTION_APP_NAME.azurewebsites.net/api/CacheConnectorUpsert?code=$upsert_key"
echo "CACHE_CONNECTOR_UPSERT_URI: \"$upsert_fun_url\""