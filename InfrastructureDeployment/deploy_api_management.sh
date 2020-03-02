#!/bin/bash

source ./InfrastructureDeployment/setup_env.sh

echo "Issuing request:"
echo "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.Web/sites/$FUNCTION_APP_NAME/functions/CacheConnectorGet/listKeys?api-version=2018-11-01"
get_key=$(az rest --method post --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.Web/sites/$FUNCTION_APP_NAME/functions/CacheConnectorGet/listKeys?api-version=2018-11-01")
if [ $? -ne 0 ]
then
    echo "Could not get the CacheConnectorGet Azure Functions key."
    exit $?
fi

get_key=$(echo $get_key | jq '.default' | sed -e 's/^"//' -e 's/"$//')
get_fun_url="https://$CACHE_MANAGER_FUNCTION_APP_NAME.azurewebsites.net/api/CacheConnectorGet?code=$get_key"

# Configure and create the API Management service
python3 -c "import APIManagement.api_management_customizer as customizer; customizer.customize_api_management_creation_body('$API_MANAGEMENT_ADMIN_EMAIL', '$API_MANAGEMENT_ORGANIZATION_NAME', '$API_MANAGEMENT_SKU', '$API_MANAGEMENT_REGION')"

echo "Issuing request:"
echo "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME?api-version=2019-01-01"
az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME?api-version=2019-01-01" --body @customized_api_management_body.json
if [ $? -ne 0 ]
then
    echo "Could not create the API Management instance."
    exit $?
fi

echo "Issuing request:"
echo "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/TaskManagement?api-version=2019-01-01" 
# Create the TaskManagement API
az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/TaskManagement?api-version=2019-01-01" --body @APIManagement/task_management_api_body.json
if [ $? -ne 0 ]
then
    echo "Could not create the API Management TaskManagement API."
    exit $?
fi

# Create the TaskManagement API GET operation
echo "Issuing request:"
echo "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/TaskManagement/operations/task?api-version=2019-01-01"
az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/TaskManagement/operations/task?api-version=2019-01-01" --body @APIManagement/task_management_operation_body.json
if [ $? -ne 0 ]
then
    echo "Could not create the API Management TaskManagement API GET operation."
    exit $?
fi

# Create the TaskManagement API GET operation's policy
echo "Issuing request:"
echo "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/TaskManagement/operations/task/policies/policy?api-version=2019-01-01"
python3 -c "import APIManagement.api_management_customizer as customizer; customizer.customize_task_management_policy('$get_fun_url')"
az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/TaskManagement/operations/task/policies/policy?api-version=2019-01-01" --body @customized_task_management_policy.json
if [ $? -ne 0 ]
then
    echo "Could not create the API Management TaskManagement API GET operation's policy."
    exit $?
fi