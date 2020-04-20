#!/bin/bash

AZURE_SUBSCRIPTION_ID=""
INFRASTRUCTURE_RESOURCE_GROUP_NAME=""     # Azure Resource Group

API_MANAGEMENT_NAME=""

API_PATH="landcover"
API_DISPLAY_NAME="AI for Earth Land Cover Mapping API"
API_DESCRIPTION="API for retrieving pre-computed classifications of aerial image pixels into natural and human-made terrain types."

az account set --subscription $AZURE_SUBSCRIPTION_ID
if [ $? -ne 0 ]
then
    echo "Could not set subscription $AZURE_SUBSCRIPTION_ID."
    exit $?
fi

ingress_ip=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ $? -ne 0 ]
then
    echo "Could not get the istio-ingressgateway ip."
    exit $?
fi
ingress_ip="http://$ingress_ip"

# Create the API
echo "Creating the API"
api_body="{\"properties\": {\"displayName\": \"$API_DISPLAY_NAME\",\"path\": \"$API_PATH\",\"protocols\": [\"https\"],\"description\":\"$API_DESCRIPTION\"}}"
az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/$API_PATH?api-version=2019-01-01" --body "$api_body"
if [ $? -ne 0 ]
then
    echo "Could not create the $API_DISPLAY_NAME API."
    exit $?
fi

# Create the classify API POST operation
echo "Creating the classify operation."
classify_api_display_name="Classify"
classify_api_operation="classify"
classify_api_operation_url="/v2/classify"

api_operation_body="{\"properties\": {\"displayName\": \"$classify_api_display_name\",\"method\": \"POST\",\"urlTemplate\": \"$classify_api_operation_url\"}}"
az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/$API_PATH/operations/$classify_api_operation?api-version=2019-01-01" --body "$api_operation_body"
if [ $? -ne 0 ]
then
    echo "Could not create the $classify_api_display_name API operation."
    exit $?
fi

# Create the Classify by extent API POST operation
echo "Creating the Classify by extent operation."
classifybyextent_api_display_name="Classify by extent"
classifybyextent_api_operation="classifybyextent"
classifybyextent_api_operation_url="/v2/classifybyextent"

api_operation_body="{\"properties\": {\"displayName\": \"$classifybyextent_api_display_name\",\"method\": \"POST\",\"urlTemplate\": \"$classifybyextent_api_operation_url\"}}"
az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/$API_PATH/operations/$classifybyextent_api_operation?api-version=2019-01-01" --body "$api_operation_body"
if [ $? -ne 0 ]
then
    echo "Could not create the $classifybyextent_api_display_name API operation."
    exit $?
fi

# Create the Get tile API POST operation
echo "Creating the Get tile operation."
gettile_api_display_name="Get tile"
gettile_api_operation="tile"
gettile_api_operation_url="/v2/tile"

api_operation_body="{\"properties\": {\"displayName\": \"$gettile_api_display_name\",\"method\": \"POST\",\"urlTemplate\": \"$gettile_api_operation_url\"}}"
az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/$API_PATH/operations/$gettile_api_operation?api-version=2019-01-01" --body "$api_operation_body"
if [ $? -ne 0 ]
then
    echo "Could not create the $gettile_api_display_name API operation."
    exit $?
fi

# Create the Get tile by extent API POST operation
echo "Creating the Get tile by extent operation."
tilebyextent_api_display_name="Get tile by extent"
tilebyextent_api_operation="tilebyextent"
tilebyextent_api_operation_url="/v2/tilebyextent"

api_operation_body="{\"properties\": {\"displayName\": \"$tilebyextent_api_display_name\",\"method\": \"POST\",\"urlTemplate\": \"$tilebyextent_api_operation_url\"}}"
az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/$API_PATH/operations/$tilebyextent_api_operation?api-version=2019-01-01" --body "$api_operation_body"
if [ $? -ne 0 ]
then
    echo "Could not create the $tilebyextent_api_display_name API operation."
    exit $?
fi

python3 -c "import api_management_customizer as customizer; customizer.customize_backend_policy('$ingress_ip')"
az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/$API_PATH/operations/$classify_api_operation/policies/policy?api-version=2019-01-01" --body @customized_request_backend_policy.json
if [ $? -ne 0 ]
then
    echo "Could not create the $API_DISPLAY_NAME operation's policy."
    exit $?
fi

az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/$API_PATH/operations/$classifybyextent_api_operation/policies/policy?api-version=2019-01-01" --body @customized_request_backend_policy.json
if [ $? -ne 0 ]
then
    echo "Could not create the $API_DISPLAY_NAME operation's policy."
    exit $?
fi

az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/$API_PATH/operations/$gettile_api_operation/policies/policy?api-version=2019-01-01" --body @customized_request_backend_policy.json
if [ $? -ne 0 ]
then
    echo "Could not create the $API_DISPLAY_NAME operation's policy."
    exit $?
fi

az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/$API_PATH/operations/$tilebyextent_api_operation/policies/policy?api-version=2019-01-01" --body @customized_request_backend_policy.json
if [ $? -ne 0 ]
then
    echo "Could not create the $API_DISPLAY_NAME operation's policy."
    exit $?
fi