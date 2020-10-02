#!/bin/bash
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

source ./InfrastructureDeployment/setup_env.sh

az account set --subscription $AZURE_SUBSCRIPTION_ID
if [ $? -ne 0 ]
then
    echo "Could not set subscription $AZURE_SUBSCRIPTION_ID."
    echo "deploy_aks.sh failed"
    exit $?
fi

# Enable the Event Grid resource provider.
az provider register --namespace Microsoft.EventGrid
if [ $? -ne 0 ]
then
    echo "Could not enable the event grid resource provider."
    exit $?
fi

# Create an Event Grid Topic
echo "Creating the Event Grid topic."
az eventgrid topic create --name $EVENT_GRID_TOPIC_NAME -l $INFRASTRUCTURE_LOCATION -g $INFRASTRUCTURE_RESOURCE_GROUP_NAME
if [ $? -ne 0 ]
then
    echo "Could not create the Event Grid topic $EVENT_GRID_TOPIC_NAME."
    exit $?
fi
