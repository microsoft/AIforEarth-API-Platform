# AI for Earth API Platform Supporting Services
Unless alternatives are specified, the following services are required by the API Platform.

## Configuration Variables
To make the process smoother, set up some configuration variables.
```bash
CACHE_MANAGEMENT_RESOURCE_GROUP_NAME="api-backend-cache-rg"     # Azure Resource Group
APP_INSIGHTS_RESOURCE_NAME="api-backend-app-svc"                # Application Services name
```

## Resource Group
The resource group will contain all of the platform supporting services.

### Create Resource Group
Create an Azure Resource Group to house the cache backend.
```bash
az group create --name $CACHE_MANAGEMENT_RESOURCE_GROUP_NAME --location eastus
```

## Azure Application Insights
Application Insights is the telemetry and logging store that is used for all system components.  It is also used to provide dynamic API service scaling based on any custom telemetry value.

### Create the Application Insights resource
```bash
az resource create \
		--resource-group $CACHE_MANAGEMENT_RESOURCE_GROUP_NAME \
		--resource-type "Microsoft.Insights/components" \
		--name $APP_INSIGHTS_RESOURCE_NAME \
		--location eastus
```