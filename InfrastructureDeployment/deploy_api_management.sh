#!/bin/bash

source ./InfrastructureDeployment/setup_env.sh

echo "Issuing request:"
echo "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.Web/sites/$FUNCTION_APP_NAME/functions/CacheConnectorGet/listKeys?api-version=2018-11-01"
get_key=$(az rest --method post --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.Web/sites/$FUNCTION_APP_NAME/functions/CacheConnectorGet/listKeys?api-version=2018-11-01")

echo $get_key
iteration=1

get_key_len=${#get_key}
while [ $get_key_len -le 1 ]
do
    if [ $iteration -ge 18 ]
    then
        echo "Could not get the CacheConnectorGet Azure Functions key."
        echo "deploy_api_management.sh failed"
        exit $?
    fi

    echo "Could not get the CacheConnectorGet Azure Functions key. Function may not be ready. Waiting 10 seconds."
    iteration=$(($iteration+1))
    echo "Try $iteration of 18"
    sleep 10
    get_key=$(az rest --method post --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.Web/sites/$FUNCTION_APP_NAME/functions/CacheConnectorGet/listKeys?api-version=2018-11-01")
    get_key_len=${#get_key}
done

get_key=$(echo $get_key | jq '.default' | sed -e 's/^"//' -e 's/"$//')
get_fun_url="https://$CACHE_MANAGER_FUNCTION_APP_NAME.azurewebsites.net/api/CacheConnectorGet?code=$get_key"

# Configure and create the API Management service
python3 -c "import APIManagement.api_management_customizer as customizer; customizer.customize_api_management_creation_body('$API_MANAGEMENT_ADMIN_EMAIL', '$API_MANAGEMENT_ORGANIZATION_NAME', '$API_MANAGEMENT_SKU', '$API_MANAGEMENT_REGION')"

echo "Issuing request to configure and create the API Management service:"
echo "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME?api-version=2019-01-01"
az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME?api-version=2019-01-01" --body @customized_api_management_body.json
while [ $? -ne 0 ]
do
    if [ $iteration -ge 18 ]
    then
        echo "Could not create the API Management service."
        echo "deploy_api_management.sh failed"
        exit $?
    fi

    echo "Could not create the API Management service. Retrying in 10 seconds."
    iteration=$(($iteration+1))
    echo "Try $iteration of 18"
    sleep 10
    az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME?api-version=2019-01-01" --body @customized_api_management_body.json
done

echo "Issuing request to create the TaskManagement API:"
echo "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/TaskManagement?api-version=2019-01-01" 
# Create the TaskManagement API
az rest --method put --uri "https://amanagement.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/TaskManagement?api-version=2019-01-01" --body @APIManagement/task_management_api_body.json
result=$?
echo "result: $result"

iteration=1
while [ $result -ne 0 ]
do
    if [ $iteration -ge 18 ]
    then
        echo "Could not create the API Management TaskManagement API."
        echo "deploy_api_management.sh failed"
        exit $?
    fi

    echo "Could not create the API Management TaskManagement API. Retrying in 10 seconds."
    iteration=$(($iteration+1))
    echo "Try $iteration of 18"
    sleep 10
    az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/TaskManagement?api-version=2019-01-01" --body @APIManagement/task_management_api_body.json
    result=$?
done

# Create the TaskManagement API GET operation
echo "Issuing request to create the TaskManagement API GET operation:"
echo "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/TaskManagement/operations/task?api-version=2019-01-01"
az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/TaskManagement/operations/task?api-version=2019-01-01" --body @APIManagement/task_management_operation_body.json
echo "result: $?"

iteration=1
while [ $? -ne 0 ]
do
    if [ $iteration -ge 18 ]
    then
        echo "Could not create the API Management TaskManagement API Get operation."
        echo "deploy_api_management.sh failed"
        exit $?
    fi

    echo "Could not create the API Management TaskManagement API Get operation. Retrying in 10 seconds."
    iteration=$(($iteration+1))
    echo "Try $iteration of 18"
    sleep 10
    az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/TaskManagement/operations/task?api-version=2019-01-01" --body @APIManagement/task_management_operation_body.json
done

# Create the TaskManagement API GET operation's policy
echo "Issuing request to create the TaskManagement API GET operation's policy:"
echo "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/TaskManagement/operations/task/policies/policy?api-version=2019-01-01"
python3 -c "import APIManagement.api_management_customizer as customizer; customizer.customize_task_management_policy('$get_fun_url')"
az rest --method put --uri "https://management.azure.com/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$INFRASTRUCTURE_RESOURCE_GROUP_NAME/providers/Microsoft.ApiManagement/service/$API_MANAGEMENT_NAME/apis/TaskManagement/operations/task/policies/policy?api-version=2019-01-01" --body @customized_task_management_policy.json
if [ $? -ne 0 ]
then
    echo "Could not create the API Management TaskManagement API GET operation's policy."
    echo "deploy_api_management.sh failed"
    exit $?
fi