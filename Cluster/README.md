# AI for Earth - Create and Configure AKS Cluster
The following is a step-by-step procedure on how to create and configure an AKS cluster with Istio for use as an AI for Earth API hosting platform.

## Prerequsites
To facilitate the install, the following tools are required:
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Helm Client](https://helm.sh/docs/using_helm/#installing-helm)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)

Please execute all commands from the Cluster directory.

## Configuration Variables
To make the process smoother, set up some configuration variables.  The corresponding services must already exist).
```bash
AZURE_SUBSCRIPTION_ID=""
CACHE_MANAGEMENT_RESOURCE_GROUP_NAME="ai4e-api-backend-cache-rg"     # Azure Resource Group
APP_INSIGHTS_RESOURCE_NAME="ai4e-api-backend-app-insights"           # Application Services name
CONTAINER_REGISTRY_NAME="ai4eapibackendregistry"                     # ACR name
```

To make the process smoother, set up some configuration variables.  The corresponding services do not yet need to exist.
```bash
AKS_RESOURCE_GROUP_NAME="ai4e-api-backend-gpu-rg" # Azure Resource Group Name
AKS_CLUSTER_NAME="ai4e-api-backend-gpu"           # AKS Cluster Name
CLUSTER_NODE_COUNT=2                              # Number of nodes to be used for API hosting
CLUSTER_NODE_VM_SKU="Standard_NC6s_v3"            # Azure SKU representing the type of VM to use for the nodes
KUBERNETES_VERSION="1.13.10"                      # Kubernetes version to deploy
DNS_NAME_PREFIX="ai4e-api-backend-gpu"            # Custom DNS prefix for your cluster
SCALE_MIN_NODE_COUNT=1                            # The minimum number of nodes to keep available
SCALE_MAX_NODE_COUNT=3                            # The most number of nodes to auto-scale
ISTIO_VERSION="1.2.5"                             # The version of Istio to install
GRAFANA_ENABLED="true"                            # Enable Grafana
KIALI_ENABLED="true"                              # Enable Kiali
GRAFANA_PASSWORD=""                               # Password for Grafana
KIALI_PASSWORD=""                                 # Password for Kiali
```

## Resource Group
Create an Azure Resource Group to house the cluster backend. We recommend that you separate include the node sku type within the name, if you are hosting both, CPU and GPU clusters.
```bash
az group create --name $AKS_RESOURCE_GROUP_NAME --location eastus
```

## AKS Cluster
```bash
# Add aks-preview extension to enable the autoscaler and monitoring add-ons.
az extension add --name aks-preview

# Register the node autoscaler feature.
az feature register --name VMSSPreview --namespace Microsoft.ContainerService

az provider register --namespace Microsoft.ContainerService

# Create the cluster.
az aks create --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME --node-count $CLUSTER_NODE_COUNT --node-vm-size $CLUSTER_NODE_VM_SKU --kubernetes-version $KUBERNETES_VERSION --dns-name-prefix $DNS_NAME_PREFIX --generate-ssh-keys --enable-vmss --enable-cluster-autoscaler --min-count $SCALE_MIN_NODE_COUNT --max-count $SCALE_MAX_NODE_COUNT --enable-addons monitoring

# Get the cluster login credentials.  This updates your ~/.kube/config file and allows access via kubectl and Helm.
az aks get-credentials --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME
```

## Initialize Helm
Initilizes Helm on the client and the AKS cluster.
```bash
helm init
```

## Tiller Service Account
Create a service account for tiller, so that Helm can be used with the cluster.
```bash
kubectl apply -f ./policy/rbac_config.yaml

kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

kubectl --namespace kube-system patch deploy tiller-deploy  -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}' 
```

## Enable GPU Plugin
If you are using GPU nodes, you must add the [NVidia device plugin](https://github.com/NVIDIA/k8s-device-plugin). All [Nvidia licenses](https://github.com/NVIDIA/k8s-device-plugin/blob/master/LICENSE) apply.
```bash
kubectl apply -f ./config/nvidia-device-plugin-ds.yaml
```

## Kubernetes Dashboard Account
To utilize the default [Kubernetes dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/), you must add a service account for it.
```bash
kubectl apply -f ./policy/dashboard-admin.yaml
```

## Istio Credentials
Download [Istio](https://istio.io/) and set up required credentials.
```bash
# Download Istio.
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=$ISTIO_VERSION sh -

# Create a namespace for the Istio services.
kubectl create namespace istio-system

# Use Helm to create an Istio credential template and deploy it to the cluster with kubectl.
helm template istio-$ISTIO_VERSION/install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
```

## Grafana
If you'd like to use the [Grafana](https://grafana.com/grafana) dashboards to aid in visualizing cluster metrics, set up a secret.
```bash
GRAFANA_USERNAME=$(echo -n "grafana" | base64)
GRAFANA_PASSPHRASE=$(echo -n $GRAFANA_PASSWORD | base64)

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: grafana
  namespace: istio-system
  labels:
    app: grafana
type: Opaque
data:
  username: $GRAFANA_USERNAME
  passphrase: $GRAFANA_PASSPHRASE
EOF
```

## Kiali
If you'd like to use [Kiali](https://github.com/kiali/kiali) for microservice connection observability, set up a secret.
```bash
GRAFANA_USERNAME=$(echo -n "grafana" | base64)
GRAFANA_PASSPHRASE=$(echo -n $KIALI_PASSWORD | base64)

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: grafana
  namespace: istio-system
  labels:
    app: grafana
type: Opaque
data:
  username: $GRAFANA_USERNAME
  passphrase: $GRAFANA_PASSPHRASE
EOF
```

## Install Istio
```bash
# Use Helm to install Istio to the cluster.
helm template istio-$ISTIO_VERSION/install/kubernetes/helm/istio --name istio --namespace istio-system --set global.proxy.includeIPRanges="10.244.0.0/16\,10.240.0.0/16" --set global.controlPlaneSecurityEnabled=true --set mixer.adapters.useAdapterCRDs=false --set grafana.enabled=$GRAFANA_ENABLED --set grafana.security.enabled=$GRAFANA_ENABLED --set tracing.enabled=true --set kiali.enabled=$KIALI_ENABLED | kubectl apply -f -
```
See the [Istio instructions](https://istio.io/docs/setup/kubernetes/install/kubernetes/#verifying-the-installation) for information on how to verify your installation.

## Registry Access
Kuberntes [pulls images](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-aks) from a container registry.  You must have this registry set up before running this step.

```bash
# Get the id of the service principal configured for AKS
client_id=$(az aks show --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME --query "servicePrincipalProfile.clientId" --output tsv)

# Get the ACR registry resource id
acr_id=$(az acr show --name $CONTAINER_REGISTRY_NAME --resource-group $CACHE_MANAGEMENT_RESOURCE_GROUP_NAME --query "id" --output tsv)

# Create role assignment
az role assignment create --assignee $client_id --role acrpull --scope $acr_id
```

## Istio Base Routing
```bash
# Lock down and add the routing configuration to Istio.
kubectl apply -f ./networking/routing_base.yml

# Prior to deploying any services, we need set up auto injection to add a sidecar to new pods, automatically.
kubectl label namespace default istio-injection=enabled
```

## Application Insights Istio Adapter
To ingest metrics into Application Insights from Istio, you must set the following enviornment variables in the [application-insights-istio-mixer-adapter-deployment.yaml](./monitoring/application-insights-istio-adapter/application-insights-istio-mixer-adapter-deployment.yaml) file:
- ISTIO_MIXER_PLUGIN_AI_INSTRUMENTATIONKEY

The instrumentation key can be retrieved by running the following:
```bash
az resource show -g $CACHE_MANAGEMENT_RESOURCE_GROUP_NAME -n $APP_INSIGHTS_RESOURCE_NAME --resource-type "Microsoft.Insights/components" --query properties.InstrumentationKey
```

You may also want to change the ISTIO_MIXER_PLUGIN_LOG_LEVEL.
```bash
kubectl apply -f ./monitoring/application-insights-istio-adapter/.
```

## Application Insights Custom Metrics Adapter
To scale based on Application Insights custom metrics, the [azure-k8s-metrics-adapter](https://github.com/Azure/azure-k8s-metrics-adapter) must be set up in the AKS cluster.

```bash
# Deploy the adapter.
kubectl apply -f https://raw.githubusercontent.com/Azure/azure-k8s-metrics-adapter/master/deploy/adapter.yaml

# Create a service principal and secret.
sp_password=$(az ad sp create-for-rbac -n "azure-k8s-metric-adapter-sp-test5" --role "Monitoring Reader" --scopes /subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AKS_RESOURCE_GROUP_NAME --query password --output tsv)

# Get the appId, tenantId, and secret of the service principal.
app_id=$(az ad sp list --display-name "azure-k8s-metric-adapter-sp-test5" --query '[].{appId:appId}' --output tsv)
tenant_id=$(az ad sp show --id $app_id --query appOwnerTenantId --output tsv)

# Use values from service principle created above to create secret.
kubectl create secret generic azure-k8s-metrics-adapter -n custom-metrics --from-literal=azure-tenant-id=$tenant_id --from-literal=azure-client-id=$app_id --from-literal=azure-client-secret=$sp_password
```