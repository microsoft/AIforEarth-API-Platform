# AI for Earth Engineering and Data Science
After developing an algorithm or machine learning model, researchers face the problem of deploying their model for others to consume, integrating it with data sources, securing its access, and keeping it current.  Due to these complexities, the vast majority of this work is  confined to the researcher’s private device, limiting the model’s application. Microsoft's AI for Earth team has built tools to democratize a researcher’s product through the use of containerized APIs that allow scientists to “drop in” their models and deploy to the cloud for world-wide consumption.  Further, AI for Earth’s API Platform is a portable, distributed serving system that provides a scalable and extensible way to integrate the model with Azure resources, which unlocks composition of discrete APIs via pipelining.

## AI for Earth API Framework
The API Framework represents the published container images, API library, the custom Application Insights library, Azure Blob libraries, the task management library, all container code, a number of examples, and extensive documentation.

Several AI for Earth container images exist, featuring Python and R, and contain:
- Libraries for API hosting
- Azure Blob SDK (SAS and AAD)
- Application Insights – modified for possible dual sink (Grantee + AI4E)
- Distributed tracing
- AI4E task manager for long-running ML inference
- AI4E API service library – decorate existing functions to turn into APIs

The API Framework is a complete, in-depth resource for turning a model or generic algorithm into an API for use in Azure.  The [API Framework GitHub repository](https://github.com/Microsoft/AIforEarth-API-Development) contains the library, container code, documentation, and examples.

## AI for Earth API Platform
The API Platform, comprised of a number of Azure components, provides a long-running, scalable, secure, and extensible hosting environment for model inference.  The core system is backed by Istio-routed Kubernetes clusters.  Azure API Management is used as a gateway and provides security, documentation, product grouping, and custom processing.  Azure Functions provide the light, on-demand compute needed to interact with the task database (Azure Redis) and to push requests to an eventing framework (Azure Event Grid).  All telemetry and logging is sent to Application Insights, also used for monitoring and alerting.

The API Platform has been built to directly accept any containers built with the API Framework.  Build scripts replace the default task library with a distributed task library and publishes the container into the production platform.

### Pipelining
When used in conjunction with the API Framework, the API Platform is capable of creating pipelines of APIs.  This provides ensemble capabilities, which can produce new, composite API pipelines, which are exposed as new APIs.  Using this method, one can drastically lower the cost of running dozens of concurrent pipelines.  Due to the nature of Kubernetes and the pipelining capability, instances of redundant services can be minimized and scaled only when they are needed.

### High-level Architecture
![High-level architecture](Assets/platform_diagram.jpeg "Architecture")

### Feature Overview
![Platform features](Assets/platform_featureset.jpeg "Featureset")


# API Platform Orientation
The API Platform consists of a number of components. Some of these components are only required for certain uses.

| Component     | Use           |
| ------------- |---------------|
| [AKS Cluster](Cluster/README.md)              | Core Kubernetes system |
| [Cache Management](CacheManagement/README.md) | Async/long-running inference |
| [API Management](APIManagement/Readme.md)     | API security, documentation, etc. |

# Alternatives
Development on the AI for Earth API Platform began in the Spring of 2018. Recently, there have been a number of improvements to the [Azure Machine Learning Service](https://docs.microsoft.com/en-us/azure/machine-learning/service/how-to-deploy-azure-kubernetes-service) and [MLOps](https://docs.microsoft.com/en-us/azure/machine-learning/service/concept-model-management-and-deployment) that have greatly bridged the inference service gaps that we had initially identified.

# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
