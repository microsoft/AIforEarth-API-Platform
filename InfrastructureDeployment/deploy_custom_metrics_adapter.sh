#!/bin/bash

source ./InfrastructureDeployment/setup_env.sh

# Application Insights Custom Metrics Adapter
if "$INSTALL_CUSTOM_METRICS_ADAPTER" = "true"
then
    # Deploy the adapter.
    echo "Creating Application Insights Custom Metrics Adapter."
    kubectl apply -f https://raw.githubusercontent.com/Azure/azure-k8s-metrics-adapter/master/deploy/adapter.yaml
    if [ $? -ne 0 ]
    then
        echo "Could not apply the Application Insights Custom Metrics Adapter."
        exit $?
    fi

    # Create a service principal and secret.
    sp_password=$(az ad sp create-for-rbac -n $SERVICE_PRINCIPAL_METRIC_ADAPTER_NAME --role "Monitoring Reader" --scopes /subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AKS_RESOURCE_GROUP_NAME --query password --output tsv)
    if [ $? -ne 0 ]
    then
        echo "Could not create the service principal and secret for $SERVICE_PRINCIPAL_METRIC_ADAPTER_NAME."
        exit $?
    fi

    # Get the appId, tenantId, and secret of the service principal.
    app_id=$(az ad sp list --display-name $SERVICE_PRINCIPAL_METRIC_ADAPTER_NAME --query '[].{appId:appId}' --output tsv)
    if [ $? -ne 0 ]
    then
        echo "Could not get the app id for $SERVICE_PRINCIPAL_METRIC_ADAPTER_NAME."
        exit $?
    fi

    tenant_id=$(az ad sp show --id $app_id --query appOwnerTenantId --output tsv)
    if [ $? -ne 0 ]
    then
        echo "Could not get the tenant id for $SERVICE_PRINCIPAL_METRIC_ADAPTER_NAME."
        exit $?
    fi

    # Use values from service principle created above to create secret.
    kubectl create secret generic azure-k8s-metrics-adapter -n custom-metrics --from-literal=azure-tenant-id=$tenant_id --from-literal=azure-client-id=$app_id --from-literal=azure-client-secret=$sp_password
    if [ $? -ne 0 ]
    then
        echo "Could not create the secret required for teh custom metrics adapter."
        exit $?
    fi
fi