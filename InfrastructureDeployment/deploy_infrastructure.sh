#!/bin/bash

if test -z "$INFRASTRUCTURE_RESOURCE_GROUP_NAME" 
then
    echo "setupenv.sh must be completed first."
    exit 1
fi

source ./deploy_prerequisites.sh
source ./deploy_aks.sh
source ./customize_aks.sh
source ./deploy_custom_metrics_adapter.sh
source ./deploy_task_routing.sh
source ./deploy_cache_manager.sh
source ./deploy_supporting_functions.sh
source ./deploy_api_management.sh