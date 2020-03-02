#!/bin/bash

source ./InfrastructureDeployment/setup_env.sh

# Create Resource Group for AKS
az group create --name $AKS_RESOURCE_GROUP_NAME --location $INFRASTRUCTURE_LOCATION

if [ $? -ne 0 ]
then
    echo "Unable to create $AKS_RESOURCE_GROUP_NAME Resource Group for AKS."
    exit $?
fi

# Create service principal for use with AKS
echo "Creating service principal"

sp_data=$(az ad sp create-for-rbac --skip-assignment)
appId=$(echo $sp_data | jq '.appId' | sed -e 's/^"//' -e 's/"$//')
password=$(echo $sp_data | jq '.password' | sed -e 's/^"//' -e 's/"$//')

# The service principal can take up to 4 minutes to propagate
echo "The service principal can take up to 5 minutes to propagate... sleeping."
sleep 300

# Create the cluster.
if [ $CLUSTER_GPU_NODE_COUNT -gt 0 ] && [ $CLUSTER_CPU_NODE_COUNT -gt 0 ]
then
    echo "Creating AKS cluster."
    az aks create --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME --node-count $CLUSTER_CPU_NODE_COUNT --node-vm-size $CLUSTER_CPU_NODE_VM_SKU --kubernetes-version $KUBERNETES_VERSION --dns-name-prefix $DNS_NAME_PREFIX --service-principal $appId --client-secret $password --generate-ssh-keys --enable-cluster-autoscaler --min-count $CPU_SCALE_MIN_NODE_COUNT --max-count $CPU_SCALE_MAX_NODE_COUNT --enable-addons monitoring --subscription $AZURE_SUBSCRIPTION_ID

    if [ $? -ne 0 ]
    then
        echo "Unable to create $AKS_CLUSTER_NAME AKS cluster."
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
            exit $?
        fi
    fi

    az aks wait --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME --interval 15 --created --updated
 
    if [ $? -ne 0 ]
    then
        echo "Waiting for $AKS_CLUSTER_NAME AKS cluster failed."
        exit $?
    fi

elif [ $CLUSTER_CPU_NODE_COUNT -gt 0 ]
then
        echo "Creating AKS cluster with a single CPU node pool."
        az aks create --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME --vm-set-type VirtualMachineScaleSets --node-count $CLUSTER_CPU_NODE_COUNT --node-vm-size $CLUSTER_CPU_NODE_VM_SKU --kubernetes-version $KUBERNETES_VERSION --dns-name-prefix $DNS_NAME_PREFIX --generate-ssh-keys --enable-cluster-autoscaler --min-count $CPU_SCALE_MIN_NODE_COUNT --max-count $CPU_SCALE_MAX_NODE_COUNT --enable-addons monitoring
        if [ $? -ne 0 ]
        then
            echo "Unable to create $AKS_CLUSTER_NAME AKS cluster."
            exit $?
        fi

        az aks wait --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME --interval 15 --created --updated
        if [ $? -ne 0 ]
        then
            echo "Waiting for $AKS_CLUSTER_NAME AKS cluster failed."
            exit $?
        fi
else
        echo "Creating AKS cluster with a single GPU node pool."
        az aks create --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME --vm-set-type VirtualMachineScaleSets --node-count $CLUSTER_GPU_NODE_COUNT --node-vm-size $CLUSTER_GPU_NODE_VM_SKU --kubernetes-version $KUBERNETES_VERSION --dns-name-prefix $DNS_NAME_PREFIX --generate-ssh-keys --enable-cluster-autoscaler --min-count $GPU_SCALE_MIN_NODE_COUNT --max-count $GPU_SCALE_MAX_NODE_COUNT --enable-addons monitoring
        if [ $? -ne 0 ]
        then
            echo "Unable to create $AKS_CLUSTER_NAME AKS cluster."
            exit $?
        fi

        az aks wait --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME --interval 15 --created --updated
        if [ $? -ne 0 ]
        then
            echo "Waiting for $AKS_CLUSTER_NAME AKS cluster failed."
            exit $?
        fi
fi

# Get the cluster login credentials.  This updates your ~/.kube/config file and allows access via kubectl and Helm.
az aks get-credentials --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME
if [ $? -ne 0 ]
then
    echo "Unable to get credentials for $AKS_CLUSTER_NAME AKS cluster."
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
        exit $?
    fi
fi