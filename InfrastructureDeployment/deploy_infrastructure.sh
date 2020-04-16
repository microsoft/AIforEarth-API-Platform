#!/bin/bash

source ./InfrastructureDeployment/deploy_prerequisites.sh
source ./InfrastructureDeployment/deploy_aks.sh
source ./InfrastructureDeployment/customize_aks.sh
source ./InfrastructureDeployment/deploy_custom_metrics_adapter.sh
source ./InfrastructureDeployment/deploy_cache_prerequisites.sh
source ./InfrastructureDeployment/deploy_event_grid_topic.sh
source ./InfrastructureDeployment/deploy_cache_manager.sh
source ./InfrastructureDeployment/deploy_backend_webhook_function.sh
source ./InfrastructureDeployment/deploy_request_reporter_function.sh
source ./InfrastructureDeployment/deploy_task_process_logger_function.sh
source ./InfrastructureDeployment/deploy_event_grid_subscription.sh
source ./InfrastructureDeployment/deploy_api_management.sh

echo "API Platform deployment complete"
