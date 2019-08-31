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

## Update the API Management Service with API Platform Scripts
There are no commands to easily import custom policies into Azure API Management. The easiest way to get started with the custom API Platform policies are to clone the default API Management repo, modify it, push the changes, and refresh the service. This is only needed if you will be responding to asynchonous (long-running) requests (eg. using the task management system). The sample API Management service demonstrates how to call a synchonous API, asynchonous API, and the task manager.

After your Azure API Management instance is created, click on the "Repository" menu item, then click "Save to repository."  You're now ready to clone and modify the instance.
1. Within the "Repository" page, copy the "Repository URL."
2. In a git command prompt or a shell, run the following command:
```bash
git clone <replace_with_your_repositiory_url>
```
3. Within the "Repository" page, click on "Access credentials."
4. Click on "Generate" to generate a password and copy it.
5. In your shell, type "apim" for the username and paste the password when requested.

Once cloned, open the newly created folder in your editor.
1. Replace the following placeholders with real values.
- [POST__detect.xml](./api-management/policies/apis/Camera_Trap_Batch_Animal_D1RIJ6XN/operations/POST__detect.xml)
- [GET__task_{taskId}.xml](./management/policies/apis/Task_Management__1[Current]/operations/GET__task_{taskId}.xml)
- [Camera_Trap_Animal_DetectiA36G2G.xml](./api-management/policies/apis/Camera_Trap_Animal_DetectiA36G2G.xml)
- [Camera_Trap_Batch_Animal_D1RIJ6XN.xml](/api-management/policies/apis/Camera_Trap_Batch_Animal_D1RIJ6XN.xml)

Values to replace:
- REPLACE_WITH_AKS_IP - replace with the result of the following:
## Target AKS Backend
```bash
# Get the IP address of the ingress gateway.
kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```
- REPLACE_WITH_GET_URL
- REPLACE_WITH_UPSERT_URL

Deploy the changes to your API Management instance.
1. Replace all of the folders with the folders located at [api-management](./api-management).
2. Commit and push the changes to your API Management Service repo.
3. Within the "Repository" page, click on "Deploy to API Management."

You should now have the sync and async examples in your instance of API Management.  Modify the examples to correspond to your APIs.  For instance, change the 


