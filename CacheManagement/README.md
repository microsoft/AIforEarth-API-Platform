# Cache Management
Cache Management refers to the components required to run asynchronous or long-running inference APIs.  It is comprised of four Azure services:
- Azure Cache for Redis
- Azure Functions (App Services)
- Azure Event Grid
- Custom Azure API Management scripts

## Prerequisites
To facilitate the install, the following tools are required:
- [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local#v2)

Please execute all commands from the CacheManagement/CacheManagement directory.

## Configuration Variables
To make the process smoother, set up some configuration variables.  The corresponding services must already exist).
```bash
CACHE_MANAGEMENT_RESOURCE_GROUP_NAME="ai4e-api-backend-rg"     # Azure Resource Group
APP_INSIGHTS_RESOURCE_NAME="ai4e-api-backend-app-insights"     # Application Services name
```

To make the process smoother, set up some configuration variables.  The corresponding services do not yet need to exist).
```bash
AZURE_CACHE_NAME="ai4e-api-backend-cache"                       # Azure Cache Name 
FUNCTION_STORAGE="ai4eapibackendstorage"                        # Azure Function Storage
FUNCTION_APP_NAME="ai4e-api-backend-cache-app"                  # Azure Function App Name
EVENT_GRID_TOPIC_NAME="ai4e-api-backend-grid-topic"             # Event Grid topic name
```

## Redis Cache Creation
```bash
# Create cache.
az redis create --name $AZURE_CACHE_NAME --resource-group $CACHE_MANAGEMENT_RESOURCE_GROUP_NAME --location eastus --vm-size C0 --sku Basic --query [hostName,sslPort] --output tsv
```

## Event Grid Creation
```bash
# Enable the Event Grid resource provider.
az provider register --namespace Microsoft.EventGrid

# Create an Event Grid Topic
az eventgrid topic create --name $EVENT_GRID_TOPIC_NAME -l eastus -g $CACHE_MANAGEMENT_RESOURCE_GROUP_NAME
```

## Cache Management Azure Functions
```bash
# A storage account is required for Azure Functions.
az storage account create --name $FUNCTION_STORAGE --location eastus --resource-group $CACHE_MANAGEMENT_RESOURCE_GROUP_NAME --sku Standard_LRS

# Create an Azure Function App to host the execution of the functions.
az functionapp create --resource-group $CACHE_MANAGEMENT_RESOURCE_GROUP_NAME --consumption-plan-location eastus --os-type Windows --name $FUNCTION_APP_NAME --storage-account  $FUNCTION_STORAGE --runtime dotnet

# Deploy the function to the Function App
func azure functionapp publish $FUNCTION_APP_NAME --publish-local-settings
```

### Set App Configuration Settings
```bash
# Get Event Grid Topic URI
topic_uri=$(az eventgrid topic show -n $EVENT_GRID_TOPIC_NAME -g $CACHE_MANAGEMENT_RESOURCE_GROUP_NAME --query endpoint --output tsv)

# Assign Event Grid Topic URI
az functionapp config appsettings set --name $FUNCTION_APP_NAME --resource-group $CACHE_MANAGEMENT_RESOURCE_GROUP_NAME --settings "EVENT_GRID_TOPIC_URI=${topic_uri}"

# Get Event Grid Topic key
topic_key=$(az eventgrid topic key list -n $EVENT_GRID_TOPIC_NAME -g $CACHE_MANAGEMENT_RESOURCE_GROUP_NAME --query key1 --output tsv)

# Assign Event Grid Key
az functionapp config appsettings set --name $FUNCTION_APP_NAME --resource-group $CACHE_MANAGEMENT_RESOURCE_GROUP_NAME --settings "EVENT_GRID_KEY=${topic_key}"

# Get Redis URI detail.
redis_uri_detail=($(az redis show --name $AZURE_CACHE_NAME --resource-group $CACHE_MANAGEMENT_RESOURCE_GROUP_NAME --query [hostName,sslPort] --output tsv))

# Get Redis access key.
redis_key=$(az redis list-keys --name $AZURE_CACHE_NAME --resource-group $CACHE_MANAGEMENT_RESOURCE_GROUP_NAME --query primaryKey --output tsv)

# Assign the Redis connection string to an App Setting in the Web App
az functionapp config appsettings set --name $FUNCTION_APP_NAME --resource-group $CACHE_MANAGEMENT_RESOURCE_GROUP_NAME --settings "REDIS_CONNECTION_STRING=${redis_uri_detail[0]}:${redis_uri_detail[1]},password=$redis_key,ssl=True,abortConnect=False"

# Get the App Insights instrumentation key
inst_key=$(az resource show --resource-group $CACHE_MANAGEMENT_RESOURCE_GROUP_NAME --name $APP_INSIGHTS_RESOURCE_NAME --resource-type "Microsoft.Insights/components" --query "properties.InstrumentationKey")

# Assign the App Insights instrumentation key
az functionapp config appsettings set --name $FUNCTION_APP_NAME --resource-group $CACHE_MANAGEMENT_RESOURCE_GROUP_NAME --settings "APPINSIGHTS_INSTRUMENTATIONKEY=${inst_key}"
 ```