#!/bin/bash

source ./InfrastructureDeployment/setup_env.sh

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
