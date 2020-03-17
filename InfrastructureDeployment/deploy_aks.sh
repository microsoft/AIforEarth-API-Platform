#!/bin/bash

source ./InfrastructureDeployment/setup_env.sh

# Create Resource Group for AKS
az group create --name $AKS_RESOURCE_GROUP_NAME --location $INFRASTRUCTURE_LOCATION

if [ $? -ne 0 ]
then
    echo "Unable to create $AKS_RESOURCE_GROUP_NAME Resource Group for AKS."
    echo "deploy_aks.sh failed"
    exit $?
fi

# Create service principal for use with AKS
echo "Creating service principal."
sp_data=$(az ad sp create-for-rbac --skip-assignment -n http://$AKS_CLUSTER_NAME-sp)
if [ $? -ne 0 ]
then
    echo "Unable to create $AKS_CLUSTER_NAME-sp service principal for AKS."
    echo "deploy_aks.sh failed"
    exit $?
fi

echo "-----------------------------------------------------------"
echo "SERVICE PRINCIPAL DETAILS - SAVE!"
echo $sp_data
echo "-----------------------------------------------------------"
read -p "Press enter to continue"

appId=$(echo $sp_data | jq '.appId' | sed -e 's/^"//' -e 's/"$//')
password=$(echo $sp_data | jq '.password' | sed -e 's/^"//' -e 's/"$//')

sp_created=$(az ad sp list --spn http://$AKS_CLUSTER_NAME-sp)
sp_created_len=${#sp_created}
while [ $sp_created_len -le 2 ]
do
    echo $sp_created_len
    echo "Service principal is not yet created. Waiting for 10 seconds."
    sleep 10
    sp_created=$(az ad sp list --spn http://$AKS_CLUSTER_NAME-sp)
    sp_created_len=${#sp_created}
done

# Give AKS' service principal pull rights to the container registry
echo "Granting AKS ACR pull rights."
acr_id=$(az acr show --name $CONTAINER_REGISTRY_NAME --query id --output tsv)

az role assignment create --assignee $appId --scope $acr_id --role AcrPull
iteration=1
while [ $? -ne 0 ]
do
    if [ $iteration -ge 10 ]
    then
        echo "Unable to grant AKS ACR pull rights."
        echo "deploy_aks.sh failed"
        exit $?
    fi

    echo "Unable to grant AKS ACR pull rights. Retrying in 10 seconds."
    iteration=$(($iteration+1))
    echo "Try $iteration of 10"
    sleep 10
    az role assignment create --assignee $appId --scope $acr_id --role AcrPull
done

# The service principal can take up to 4 minutes to propagate
#echo "The service principal can take up to 4 minutes to propagate... sleeping."
#sleep 240

# Create the cluster.
if [ $CLUSTER_GPU_NODE_COUNT -gt 0 ] && [ $CLUSTER_CPU_NODE_COUNT -gt 0 ]
then
    echo "Creating AKS cluster."
    az aks create --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME --node-count $CLUSTER_CPU_NODE_COUNT --node-vm-size $CLUSTER_CPU_NODE_VM_SKU --kubernetes-version $KUBERNETES_VERSION --dns-name-prefix $DNS_NAME_PREFIX --service-principal $appId --client-secret $password --generate-ssh-keys --enable-cluster-autoscaler --min-count $CPU_SCALE_MIN_NODE_COUNT --max-count $CPU_SCALE_MAX_NODE_COUNT --enable-addons monitoring --subscription $AZURE_SUBSCRIPTION_ID
    #az aks create --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME --node-count $CLUSTER_CPU_NODE_COUNT --node-vm-size $CLUSTER_CPU_NODE_VM_SKU --kubernetes-version $KUBERNETES_VERSION --dns-name-prefix $DNS_NAME_PREFIX --generate-ssh-keys --enable-cluster-autoscaler --min-count $CPU_SCALE_MIN_NODE_COUNT --max-count $CPU_SCALE_MAX_NODE_COUNT --enable-addons monitoring --subscription $AZURE_SUBSCRIPTION_ID


    if [ $? -ne 0 ]
    then
        echo "Unable to create $AKS_CLUSTER_NAME AKS cluster."
        echo "deploy_aks.sh failed"
        exit $?
    fi

    echo "Creating two nodepools."
    pools=$(az aks nodepool list -g $AKS_RESOURCE_GROUP_NAME --cluster-name $AKS_CLUSTER_NAME --out table --query '[].[name]')

    if [[ $pools != *"gpupool"* ]]
    then
        echo "Creating GPU node pool."
        az aks nodepool add --resource-group $AKS_RESOURCE_GROUP_NAME --cluster-name $AKS_CLUSTER_NAME --name gpupool --node-count $CLUSTER_GPU_NODE_COUNT --node-vm-size $CLUSTER_GPU_NODE_VM_SKU --kubernetes-version $KUBERNETES_VERSION --enable-cluster-autoscaler --min-count $GPU_SCALE_MIN_NODE_COUNT --max-count $GPU_SCALE_MAX_NODE_COUNT --node-taints sku=gpu:NoSchedule

        if [ $? -ne 0 ]
        then
            echo "Unable to create GPU node pool in the $AKS_CLUSTER_NAME AKS cluster."
            echo "deploy_aks.sh failed"
            exit $?
        fi
    fi

    az aks wait --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME --interval 15 --created --updated
 
    if [ $? -ne 0 ]
    then
        echo "Waiting for $AKS_CLUSTER_NAME AKS cluster failed."
        echo "deploy_aks.sh failed"
        exit $?
    fi

elif [ $CLUSTER_CPU_NODE_COUNT -gt 0 ]
then
        echo "Creating AKS cluster with a single CPU node pool."
        az aks create --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME --vm-set-type VirtualMachineScaleSets --node-count $CLUSTER_CPU_NODE_COUNT --node-vm-size $CLUSTER_CPU_NODE_VM_SKU --kubernetes-version $KUBERNETES_VERSION --dns-name-prefix $DNS_NAME_PREFIX --generate-ssh-keys --enable-cluster-autoscaler --min-count $CPU_SCALE_MIN_NODE_COUNT --max-count $CPU_SCALE_MAX_NODE_COUNT --enable-addons monitoring
        if [ $? -ne 0 ]
        then
            echo "Unable to create $AKS_CLUSTER_NAME AKS cluster."
            echo "deploy_aks.sh failed"
            exit $?
        fi

        az aks wait --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME --interval 15 --created --updated
        if [ $? -ne 0 ]
        then
            echo "Waiting for $AKS_CLUSTER_NAME AKS cluster failed."
            echo "deploy_aks.sh failed"
            exit $?
        fi
else
        echo "Creating AKS cluster with a single GPU node pool."
        az aks create --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME --vm-set-type VirtualMachineScaleSets --node-count $CLUSTER_GPU_NODE_COUNT --node-vm-size $CLUSTER_GPU_NODE_VM_SKU --kubernetes-version $KUBERNETES_VERSION --dns-name-prefix $DNS_NAME_PREFIX --generate-ssh-keys --enable-cluster-autoscaler --min-count $GPU_SCALE_MIN_NODE_COUNT --max-count $GPU_SCALE_MAX_NODE_COUNT --enable-addons monitoring
        if [ $? -ne 0 ]
        then
            echo "Unable to create $AKS_CLUSTER_NAME AKS cluster."
            echo "deploy_aks.sh failed"
            exit $?
        fi

        az aks wait --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME --interval 15 --created --updated
        if [ $? -ne 0 ]
        then
            echo "Waiting for $AKS_CLUSTER_NAME AKS cluster failed."
            echo "deploy_aks.sh failed"
            exit $?
        fi
fi

# Get the cluster login credentials.  This updates your ~/.kube/config file and allows access via kubectl and Helm.
az aks get-credentials --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME
if [ $? -ne 0 ]
then
    echo "Unable to get credentials for $AKS_CLUSTER_NAME AKS cluster."
    echo "deploy_aks.sh failed"
    exit $?
fi

# GPU ONLY
if [ $CLUSTER_GPU_NODE_COUNT -gt 0 ]
then
    # Enable GPU Plugin
    echo "Applying nvidia device plugin."
    kubectl apply -f ./Cluster/config/nvidia-device-plugin-ds.yaml
    if [ $? -ne 0 ]
    then
        echo "Could not apply the NVidia device plugin for the $AKS_CLUSTER_NAME AKS cluster."
        echo "deploy_aks.sh failed"
        exit $?
    fi
fi