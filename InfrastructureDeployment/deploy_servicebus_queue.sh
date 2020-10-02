#!/bin/bash
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

source ./InfrastructureDeployment/setup_env.sh

az account set --subscription $AZURE_SUBSCRIPTION_ID
if [ $? -ne 0 ]
then
    echo "Could not set subscription $AZURE_SUBSCRIPTION_ID."
    echo "deploy_servicebus_queue.sh failed"
    exit $?
fi


az servicebus namespace create --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --name $SERVICEBUS_NAMESPACE --location $INFRASTRUCTURE_LOCATION

az aks get-credentials --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME

echo "Getting the ingress ip."
ingress_ip=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ $? -ne 0 ]
then
    echo "Could not get the istio-ingressgateway ip."
    exit $?
fi

# Create the service bus queue.
for queue_name_path in "${queue_name_paths[@]}"
do
    cleaned_ip=${ingress_ip//\./''}
    cleaned_url_template=${queue_name_path//\//''}
    queue_name="$HTTP_SCHEME$cleaned_ip$cleaned_url_template"
    echo $queue_name
    az servicebus queue create --name $queue_name --resource-group $INFRASTRUCTURE_RESOURCE_GROUP_NAME --namespace-name $SERVICEBUS_NAMESPACE --max-delivery-count $SERVICEBUS_QUEUE_MAX_DELIVERY_COUNT
    if [ $? -ne 0 ]
    then
        echo "Could not create the service bus queue $queue_name_path."
        echo "deploy_servicebus_queue.sh failed"
        exit $?
    fi
done

echo "Queue creation complete."