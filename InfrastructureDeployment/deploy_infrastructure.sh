#!/bin/bash
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

source ./InfrastructureDeployment/setup_env.sh

source ./InfrastructureDeployment/deploy_prerequisites.sh
source ./InfrastructureDeployment/deploy_aks.sh
source ./InfrastructureDeployment/customize_aks.sh
source ./InfrastructureDeployment/deploy_custom_metrics_adapter.sh
source ./InfrastructureDeployment/deploy_cache_prerequisites.sh

if [[ "$TRANSPORT_TYPE" = "eventgrid" ]]
then
    source ./InfrastructureDeployment/deploy_event_grid_topic.sh
else
    source ./InfrastructureDeployment/deploy_servicebus_queue.sh
fi

source ./InfrastructureDeployment/deploy_cache_manager.sh

if [[ "$TRANSPORT_TYPE" = "eventgrid" ]]
then
    source ./InfrastructureDeployment/deploy_backend_webhook_function.sh
else
    source ./InfrastructureDeployment/deploy_backend_queue_function.sh
fi

source ./InfrastructureDeployment/deploy_request_reporter_function.sh
source ./InfrastructureDeployment/deploy_task_process_logger_function.sh

if [[ "$TRANSPORT_TYPE" = "eventgrid" ]]
then
    source ./InfrastructureDeployment/deploy_event_grid_subscription.sh
fi

source ./InfrastructureDeployment/deploy_api_management.sh

echo "API Platform deployment complete"