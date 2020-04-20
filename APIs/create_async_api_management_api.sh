#!/bin/bash

AZURE_SUBSCRIPTION_ID=""
INFRASTRUCTURE_RESOURCE_GROUP_NAME=""     # Azure Resource Group

API_MANAGEMENT_NAME=""

API_PATH="landcover"
API_DISPLAY_NAME="AI for Earth Land Cover Mapping API"
API_DESCRIPTION="API for retrieving pre-computed classifications of aerial image pixels into natural and human-made terrain types."


if test -z "$INFRASTRUCTURE_RESOURCE_GROUP_NAME" 
then
    echo "setupenv.sh must be completed first."
    exit 1
fi

az account set --subscription $AZURE_SUBSCRIPTION_ID
if [ $? -ne 0 ]
then
    echo "Could not set subscription $AZURE_SUBSCRIPTION_ID."
    exit $?
fi

# Deploy API Management
upsert_key=$(az rest --method post --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.Web/sites/$FUNCTION_APP_NAME/functions/CacheConnectorUpsert/listKeys?api-version=2018-11-01")
if [ $? -ne 0 ]
then
    echo "Could not get the CacheConnectorUpsert Azure Functions key."
    exit $?
fi

upsert_key=$(echo $upsert_key | jq '.default' | sed -e 's/^"//' -e 's/"$//')
upsert_fun_url="https://$CACHE_MANAGER_FUNCTION_APP_NAME.azurewebsites.net/api/CacheConnectorUpsert?code=$upsert_key"

ingress_ip=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ $? -ne 0 ]
then
    echo "Could not get the istio-ingressgateway ip."
    exit $?
fi

# Create the API
api_body="{\"properties\": {\"displayName\": \"$API_DISPLAY_NAME\",\"path\": \"$API_PATH\",\"protocols\": [\"https\"]}}"
az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/$API_PATH?api-version=2019-01-01" --body $api_body
if [ $? -ne 0 ]
then
    echo "Could not create the $API_DISPLAY_NAME API."
    exit $?
fi

# Create the API policy
python3 -c "import APIManagement.api_management_customizer as customizer; customizer.customize_api_policy('$upsert_fun_url')"
az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/$API_PATH/policies/policy?api-version=2019-01-01" --body @customized_api_policy.json
if [ $? -ne 0 ]
then
    echo "Could not create the $API_DISPLAY_NAME API POST operation's policy."
    exit $?
fi

# Create the API POST operation
api_operation_body="{\"properties\": {\"displayName\": \"$API_OPERATION_DISPLAY_NAME\",\"method\": \"POST\",\"urlTemplate\": \"$API_OPERATION_URL\"}}"
az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/$API_PATH/operations/$API_OPERATION_URL?api-version=2019-01-01" --body $api_operation_body
if [ $? -ne 0 ]
then
    echo "Could not create the $API_DISPLAY_NAME API operation."
    exit $?
fi

# Create the API operation's policy
api_backend_policy="<policies><inbound><set-backend-service base-url=https://\"$ingress_ip\" /><rewrite-uri template=\"$BACKEND_API_URL\" /><base /></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>"
az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/$API_PATH/operations/$API_OPERATION_URL/policies/policy?api-version=2019-01-01" --body $api_backend_policy
if [ $? -ne 0 ]
then
    echo "Could not create the $API_DISPLAY_NAME API POST operation's policy."
    exit $?
fi