# Azure API Management Service
Azure API Management is used to provide access to your API.  It also can provide API documentation, monetary features, and additional security.

## Deployment
Unfortunately, Azure API Management does not have an Azure CLI extension.  While PowerShell and the Azure Portal can be used to deploy, Azure Resource Template deployment options are supplied here. 

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fazure%2Fazure-quickstart-templates%2Fmaster%2F101-azure-api-management-create%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2F101-azure-api-management-create%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This template deploys an Azure API Management instance, based on the configuration values that you provide during setup.

