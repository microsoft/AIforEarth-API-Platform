#!/bin/bash
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

source ./InfrastructureDeployment/setup_env.sh

az account set --subscription $AZURE_SUBSCRIPTION_ID
if [ $? -ne 0 ]
then
    echo "Could not set subscription $AZURE_SUBSCRIPTION_ID."
    echo "deploy_aks.sh failed"
    exit $?
fi

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
    echo "Unable to create service principal for AKS."
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

# Give service principal pull rights to the container registry
echo "Granting ACR pull rights."
acr_id=$(az acr show --name $CONTAINER_REGISTRY_NAME --query id --output tsv)

az role assignment create --assignee $appId --scope $acr_id --role AcrPull
iteration=1
while [ $? -ne 0 ]
do
    if [ $iteration -ge 10 ]
    then
        echo "Unable to grant ACR pull rights."
        echo "deploy_aks.sh failed"
        exit $?
    fi

    echo "Unable to grant ACR pull rights. Retrying in 10 seconds."
    iteration=$(($iteration+1))
    echo "Try $iteration of 10"
    sleep 10
    az role assignment create --assignee $appId --scope $acr_id --role AcrPull
done



# Create the cluster.
add_managed_identity=""
if "$ENABLE_AKS_MANAGED_IDENTITY" = "true"
then
    add_managed_identity="--enable-managed-identity"
fi

create="true"
for pool in "${pool_order[@]}"
do
    sku="${node_skus[$pool]}"
    start_count=${node_start_count[$pool]}
    min_count=${node_min_count[$pool]}
    max_count=${node_max_count[$pool]}

    echo "Processing pool: $pool"

    if "$create" = "true"
    then
        echo "Creating AKS cluster with base pool: $pool."        
        az aks create --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME --nodepool-name $pool --node-count $start_count --node-vm-size $sku --kubernetes-version $KUBERNETES_VERSION --dns-name-prefix $DNS_NAME_PREFIX --service-principal $appId --client-secret $password --generate-ssh-keys --enable-cluster-autoscaler --min-count $min_count --max-count $max_count --enable-addons monitoring --subscription $AZURE_SUBSCRIPTION_ID $add_managed_identity
        create="false"
    else
        echo "Adding pool to cluster: $pool."
        taints=""

        if [ ${node_taints[$pool]+_} ]
        then
            taints="--node-taints ${node_taints[$pool]}"
        fi
        az aks nodepool add --resource-group $AKS_RESOURCE_GROUP_NAME --cluster-name $AKS_CLUSTER_NAME --name $pool --node-count $start_count --node-vm-size $sku --kubernetes-version $KUBERNETES_VERSION --enable-cluster-autoscaler --min-count $min_count --max-count $max_count $taints $add_managed_identity
    fi

    if [ $? -ne 0 ]
    then
        echo "Unable to create $AKS_CLUSTER_NAME AKS cluster."
        echo "deploy_aks.sh failed"
        exit $?
    fi

done

# Get the cluster login credentials.  This updates your ~/.kube/config file and allows access via kubectl and Helm.
az aks get-credentials --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME
if [ $? -ne 0 ]
then
    echo "Unable to get credentials for $AKS_CLUSTER_NAME AKS cluster."
    echo "deploy_aks.sh failed"
    exit $?
fi

# GPU ONLY
if "$INSTALL_NVIDIA_DEVICE_PLUGIN" = "true"
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

# Create role to allow AKS to read logs for cluster health reporting.
echo "Applying containerHealth-log-reader cluster role."
kubectl apply -f ./Cluster/policy/containerHealth-log-reader.yaml
if [ $? -ne 0 ]
then
    echo "Could not apply the containerHealth-log-reader cluster role for the $AKS_CLUSTER_NAME AKS cluster."
    echo "deploy_aks.sh failed"
    exit $?
fi