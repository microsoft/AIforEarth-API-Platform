#!/bin/bash

AZURE_SUBSCRIPTION_ID=""
DEPLOYMENT_PREFIX=""
HTTP_SCHEME="http"

INFRASTRUCTURE_RESOURCE_GROUP_NAME="$DEPLOYMENT_PREFIX-rg"
API_MANAGEMENT_NAME="$DEPLOYMENT_PREFIX-api-mgmt"

CACHE_MANAGER_FUNCTION_APP_NAME="$DEPLOYMENT_PREFIX-cache-app"

API_PATH="landcover"
API_DISPLAY_NAME="AI for Earth Land Cover Mapping API"
API_DESCRIPTION="API for retrieving pre-computed classifications of aerial image pixels into natural and human-made terrain types."
URL_TEMPLATE="/v1/landcover/classify"

API_OPERATION_DISPLAY_NAME="Landcover classify"
API_OPERATION_URL="classify"

if test -z "$INFRASTRUCTURE_RESOURCE_GROUP_NAME" 
then
    echo "Variables must be set first.."
    exit 1
fi

az account set --subscription $AZURE_SUBSCRIPTION_ID
if [ $? -ne 0 ]
then
    echo "Could not set subscription $AZURE_SUBSCRIPTION_ID."
    exit $?
fi

echo "Getting the cache upsert key."
upsert_key=$(az rest --method post --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.Web/sites/$CACHE_MANAGER_FUNCTION_APP_NAME/functions/CacheConnectorUpsert/listKeys?api-version=2018-11-01")
if [ $? -ne 0 ]
then
    echo "Could not get the CacheConnectorUpsert Azure Functions key."
    exit $?
fi

upsert_key=$(echo $upsert_key | jq '.default' | sed -e 's/^"//' -e 's/"$//')
upsert_fun_url="https://$CACHE_MANAGER_FUNCTION_APP_NAME.azurewebsites.net/api/CacheConnectorUpsert?code=$upsert_key"

echo "Getting the ingress ip."
ingress_ip=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ $? -ne 0 ]
then
    echo "Could not get the istio-ingressgateway ip."
    exit $?
fi

# Create the API
echo "Creating the API."
api_body="{\"properties\": {\"displayName\": \"$API_DISPLAY_NAME\",\"path\": \"$API_PATH\",\"protocols\": [\"https\"],\"description\":\"$API_DESCRIPTION\"}}"
az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/$API_PATH?api-version=2019-01-01" --body "$api_body"
if [ $? -ne 0 ]
then
    echo "Could not create the $API_DISPLAY_NAME API."
    exit $?
fi

# Create the API POST operation
echo "Creating the API POST operation."
api_operation_body="{\"properties\": {\"displayName\": \"$API_OPERATION_DISPLAY_NAME\",\"method\": \"POST\",\"urlTemplate\": \"$API_OPERATION_URL\"}}"
az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/$API_PATH/operations/$API_OPERATION_URL?api-version=2019-01-01" --body "$api_operation_body"
if [ $? -ne 0 ]
then
    echo "Could not create the $API_DISPLAY_NAME API operation."
    exit $?
fi

# Create the API operation's policy
echo "Creating the API POST operation's policy."
python3 -c "import api_management_customizer as customizer; customizer.customize_async_api_policy('$HTTP_SCHEME://$ingress_ip','$URL_TEMPLATE','$upsert_fun_url')"
az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/$API_PATH/operations/$API_OPERATION_URL/policies/policy?api-version=2019-01-01" --body @customized_async_api_policy.json
if [ $? -ne 0 ]
then
    echo "Could not create the $API_OPERATION_URL operation's policy."
    exit $?
fi