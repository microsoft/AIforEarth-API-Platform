## API Platform Deployment
The API Platform may be deployed using shell scripts.  Effort was made to separate core components for two reasons:
- Optional functionality can be chosen
- Connectivity issues can result in failure of service deployment.  If this occurs, the failed and subsequent services may be deployed without starting over.

There are three types of files required for deployment:
- [setup_env.sh](setup_env.sh)
    - Variable setting script, which is used for all deployment configuration.
    - This script MUST be edited prior to execution of any deployment scripts.
- [deploy_infrastructure.sh](./deploy_infrastructure.sh)
    - Master script that runs each deployment script in sequence.
- Individual component/feature deployment scripts.

## Contents
1. [Installation Process](#Installation-Process)
2. [Component/feature deployment scripts](#Component/feature-deployment-scripts)

## Installation Process
To quickly get up and running, follow these steps.

1. Edit the [setup_env.sh](setup_env.sh) file.  This is where you configure the deployment.
2. From the top-level directory, run the following script.  Note that connection issues and service creation latencies may result in errors.  The scripts are designed such that you can rerun and services will not be recreated.  There are some commented out resolutions in the scripts that may be of value.
```bash
bash InfrastructureDeployment/deploy_infrastructure.sh
```
3. [Secure the Istio Gateway](https://istio.io/docs/tasks/traffic-management/ingress/secure-ingress-mount/#configure-a-tls-ingress-gateway-with-a-file-mount-based-approach).  This is optional, but should be completed for production instances.  All of these steps are documented at the above link, but are listed here for brevity.  To secure the gateway, please follow these steps:
   1.  Get the ingress IP and ports of the Istio gateway:
   ```bash
   kubectl get svc istio-ingressgateway -n istio-system
   ```
   2. Generate server certificate and private key:
   ```bash
   openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
   ```
   3. Create a certificate and a private key (replace httpbin.example.com and organization):
   ```bash
   openssl req -out httpbin.example.com.csr -newkey rsa:2048 -nodes -keyout httpbin.example.com.key -subj "/CN=httpbin.example.com/O=httpbin organization"

   openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in httpbin.example.com.csr -out httpbin.example.com.crt
   ```
   4. Create a Kubernetes secret to hold the server’s certificate and private key (the secret must be named istio-ingressgateway-certs in the istio-system namespace):
   ```bash
   kubectl create -n istio-system secret tls istio-ingressgateway-certs --key httpbin.example.com.key --cert httpbin.example.com.crt
   ```
   5. Modify the default Istio gateway to use the HTTPS protocol (replace httpbin.example.com):
    ```bash
    kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
        name: ai4e-gateway
    spec:
        selector:
            istio: ingressgateway # use istio default ingress gateway
        servers:
        - port:
            number: 443
            name: https
            protocol: HTTPS
        tls:
            mode: SIMPLE
            serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
            privateKey: /etc/istio/ingressgateway-certs/tls.key
        hosts:
            - "*" # replace with API Management URL
    EOF
    ```


## Component/feature deployment scripts
Provided that prerequisites have been deployed, component deployment scripts may be run outside of the [deploy_infrastructure.sh](./deploy_infrastructure.sh) script.  The scripts are typically executed in the following order.

### [deploy_prerequisites.sh](./deploy_prerequisites.sh)
1. Sets the current subscription.
2. Creates the infrastructure resource group.
3. Creates the Application Insights resource.
    - Be sure to copy the instrumentation key.
4. Create the container registry to be used to house AKS service images.
5. Create the storage account for the required Azure Functions.

### [deploy_aks.sh](deploy_aks.sh)
1. Creates the resource group needed for AKS.
2. Creates the service principal application for AKS.
    - Be sure to copy the service principal details and keep them secure.
3. Grant the service principal application container registry pull rights.
4. Creates the AKS service.
5. Adds configured node pools to the AKS cluster (CPU or GPU).
6. Stores the AKS cluster's credentials in the local ~/.kube/config file.
7. Enables the GPU [NVidia plugin](https://github.com/NVIDIA/k8s-device-plugin) on AKS (GPU only).

### [customize_aks.sh](customize_aks.sh)
1. Adds [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/) admin account so that an admin can access the dashboard.
2. Install [Istio](https://istio.io/) for [AKS service mesh](https://docs.microsoft.com/en-us/azure/aks/servicemesh-istio-about) utilities and features.
    1. Downloads Istio.
    2. Applies the Istio manifest.
    3. Creates the istio-system namespace in AKS.
    4. Adds [base routing rules](../Cluster/networking/routing_base.yml).
    5. Creates an Azure Container Registry role so that AKS can pull the service images.
    6. Creates the Azure Container Registry AcrPull role assignment for AKS.

### [deploy_custom_metrics_adapter.sh](deploy_custom_metrics_adapter.sh)
The [Azure Kubernetes Metrics Adapter](https://github.com/Azure/azure-k8s-metrics-adapter) is used, in conjunction with Application Insights, to provide scaling on any metric logged to Application Insights.
1. Deploys the [Azure Kubernetes Metrics Adapter](https://github.com/Azure/azure-k8s-metrics-adapter).
2. Creates a service principal and secret for the metric adapter.
3. Stores the service principal secret in AKS.

### [deploy_cache_prerequisites.sh](deploy_cache_prerequisites.sh)
- The Cache Manager is the task system that is used to manage long-running (async) service (API) requests.  The Cache Manager is constructed with custom Azure Functions, Azure Redis Cache, and Azure Event Grid.  Due to the complex nature of the Cache Manager, the following order of scripts must be maintained:
    1. [deploy_cache_prerequisites.sh](deploy_cache_prerequisites.sh)
    2. [deploy_event_grid_topic.sh](deploy_event_grid_topic.sh)
    3. [deploy_cache_manager.sh](deploy_cache_manager.sh)
    4. Unless you are planning to use a [TLS https gateway](https://istio.io/docs/tasks/traffic-management/ingress/secure-ingress-mount/#configure-a-tls-ingress-gateway-with-a-file-mount-based-approach), the [deploy_backend_webhook_function.sh](deploy_backend_webhook_function.sh)
deploy_cache_prerequisites installs the following:
1. Creates an Azure Redis Cache.
2. Creates an Azure Function App Plan to host the execution of the functions.

### [deploy_event_grid_topic.sh](deploy_event_grid_topic.sh)
1. Creates the Event Grid Topic.

### [deploy_cache_manager.sh](deploy_cache_manager.sh)
1. Creates the Cache Manager Function App.
2. Configures the Cache Manager Function App settings.

### [deploy_backend_webhook_function.sh](deploy_backend_webhook_function.sh)
The backend webhook is an Azure function that exposes an https URL and pushes the request to AKS.  This is needed when a [TLS https gateway](https://istio.io/docs/tasks/traffic-management/ingress/secure-ingress-mount/) is not used.  A common usage is during development and testing.
1. Creates the backend webhook Azure Function App.
2. Configures the backend webhook Azure Function App settings.

### [deploy_request_reporter_function.sh](deploy_request_reporter_function.sh)
The request reporter stores and retrieves the number of requests a service is processing at any given moment.  The request reporter works in conjunction with the API Framework.  An API can be configured with a maximum requests processing count, which puts backpressure on the async task system or returns a 503, in the case of a sync API.  The current number of requests are also logged to Application Insights, which can be used to scale up/down the available service instances in AKS via the [Azure Kubernetes Metrics Adapter](https://github.com/Azure/azure-k8s-metrics-adapter).
1. Creates the request reporter Azure Function App.
2. Configures the request reporter Azure Function App settings.

### [deploy_task_process_logger_function.sh](deploy_task_process_logger_function.sh)
The task process logger retrieves the number of tasks being processed and the number of tasks awaiting processing.  This can be used in conjunction with Application Insights, which can be used to scale up/down the available service instances in AKS via the [Azure Kubernetes Metrics Adapter](https://github.com/Azure/azure-k8s-metrics-adapter).
1. Creates the task process logger Azure Function App.
2. Configures the task process logger Azure Function App settings.

### [deploy_event_grid_subscription.sh](deploy_event_grid_subscription.sh)
1. Gets the backend webhook Azure Function's secret URL.
2. Creates the Event Grid subscription for the backend webhook.

### [deploy_api_management.sh](deploy_api_management.sh)
1. Gets the CacheConnectorGet Azure Function's secret URL.
2. Configures the payload required to create an API Management service instance.
3. Creates the API Management service instance.
4. Creates the TaskManagement API in the API Management service instance.
5. Creates the TaskManagement API GET operation.
6. Creates the TaskManagement API GET operation's policy.