# AI for Earth - Deployment of a Production API

## Contents
  1. [Requirements](#Requirements)
  2. [Publishing to the AI for Earth API Platform](#Publishing-to-the-AI-for-Earth-API-Platform)

## Prerequsites
To facilitate the install, the following tools are required:
- [Docker](https://www.docker.com/products/docker-desktop)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Helm Client](https://helm.sh/docs/using_helm/#installing-helm)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)

## Requirements
To publish a container to the AI for Earth API Platform, the API must be built using one of the official AI for Earth [base containers](https://github.com/Microsoft/AIforEarth-API-Development/blob/master/Quickstart.md) and the [acceptance criteria](https://github.com/Microsoft/AIforEarth-API-Development/blob/master/AcceptanceCriteria.md) should be followed.

### Push to ACR
[Tag and push](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-azure-cli#push-image-to-registry) your image to your container repository. The images must be versioned. Internally, we use the following naming pattern:
```
<ACR_name>.azurecr.io/<project_moniker>/<image_version>-<api_name>:<build_number>
```

## Production Preparation
### Create a production AI for Earth dockerfile for your API
For all of the following steps, please reference the camera-trap example, located in the [camera-trap directory](Projects/camera-trap/detection-sync.dockerfile).
1. In the [APIs/Projects](./Projects/) folder, you will notice separate folders for each project.  Create a new folder for your project.
2. Create a new <api_name>.dockerfile and place it in your folder (pay close attention to the tech stack - Python or R; be sure to use the correct one).
3. Modify the FROM clause to point to your registry and <project_moniker> (where you pushed your image in the "Push to ACR" step).  The version and tag arguments are required.

### Create a Helm chart, etc. for your API
For all of the following steps, please reference the camera-trap example, located in the [camera-trap directory](APIs/Charts/camera-trap/detection-sync).
1. In the charts/ folder, create a new folder for your project.
2. Copy and existing chart project/api folder and place it under your project folder.
3. Modify the [Chart.yaml](./Charts/camera-trap/detection-sync/Chart.yaml) by changing the description, name, and keywords fields.  The name should be of the format <project_moniker>-<api_name>.
4. Modify the [autoscaler.yaml](./Charts/camera-trap/detection-sync/autoscaler.yaml) by changing both name fields.  The name should be of the format <project_moniker>-<api_name>-autoscaler and <project_moniker>-<api_name>, respectfully.  Modify the maxReplicas to the maximum number of instances of your service that should be run and modify the targetCPUUtilizationPercentage to indicate when a new instance should be created.  The API Platform supports [auto-scaling on custom Application Insights metrics](https://github.com/Azure/azure-k8s-metrics-adapter).  The camera-trap example uses one such metric that tracks the number of requests that are being processed.
5. Modify the [prod-values.yaml](./Charts/camera-trap/detection-sync/prod-values.yaml) by changing the image.repository to <your_registry>/<project_moniker>/<major_version>-ai4e-api-<api_name>, the name to <project_moniker>-<api_name>, a port that is not taken by ANY other chart by ANY other project API, the resources, and the env variables.
6. Modify the [routing.yml](./Charts/camera-trap/detection-sync/routing.yml). The VirtualService name should be of the format <project_moniker>-<api_name>. Modify the uri.prefix to indicate the incoming path to match, modify the destination.host to a name that reflects <project_moniker>-<api_name>.default.svc.cluster.local, destination.port to reflect the port that is to be used, and destination.subset to the version of the release.  Change the DestinationRule to a unique name for your API, modify the host to the destination.host value from above, and esure that the name and label version match the path version of the release.  To read more about Istio routing, please see the [docs](https://istio.io/docs/tasks/traffic-management/request-routing/).

## Building and Deploying a Production API

### Build Distributed-capable Image
The distributed image must be built from this (APIs) directory.  The following illustrates how to build the camera-trap example.
```bash
docker build . -f Projects/camera-trap/detection-sync.dockerfile -t ai4eapibackendv2gpu3registry.azurecr.io/camera-trap/1.0-ai4e-api-detection-sync:4
```

Once complete, push the new image to your container registry:
```bash
# Log into your ACR instance.
az acr login -n <acr_name>

# Push your image to your ACR.
docker push ai4eapibackendv2gpu3registry.azurecr.io/camera-trap/1.0-ai4e-api-detection-sync:4
```

You now have a distributed-capable image stored in your container registry that is ready to be hosted on the API Platform.

### Configure API Variables
Before deploying to the cluster, edit the chart's prod-values.yaml file.  This contains all configuration values to be used by your service. The Azure Function URLs can be retrieved by issuing the following command:
 ```bash
 func azure functionapp list-functions $FUNCTION_APP_NAME --show-keys
 ```

Azure Function URLs are mapped to variables according to the following table:
| Chart Variable                | Function Name           |
| ----------------------------- | ----------------------- |
| CACHE_CONNECTOR_UPSERT_URI    | cache-connector-upsert  |
| CACHE_CONNECTOR_GET_URI       | cache-connector-get     |
| CURRENT_PROCESSING_UPSERT_URI | CurrentProcessingUpsert |

### Deploy the API to Production
```bash
# Deploy instance.
helm install --values ./Charts/camera-trap/detection-sync/prod-values.yaml --name camera-trap-detection-sync ./Charts/camera-trap/detection-sync

# Apply auto-scaling.
kubectl apply -f ./Charts/camera-trap/detection-sync/autoscaler.yaml

# Apply service routing.
kubectl apply -f ./Charts/camera-trap/detection-sync/routing.yaml

# Apply optional Application Insights custom scaling metric.
kubectl apply -f ./Charts/camera-trap/detection-sync/appinsights-metric.yaml
```