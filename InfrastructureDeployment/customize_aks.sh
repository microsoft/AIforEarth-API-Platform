#!/bin/bash

source ./InfrastructureDeployment/setup_env.sh

# Create Kubernetes Dashboard Account
echo "Applying dashboard admin account."
kubectl apply -f ./Cluster/policy/dashboard-admin.yaml
if [ $? -ne 0 ]
then
    echo "Could not apply the dashboard policy for the $AKS_CLUSTER_NAME AKS cluster."
    exit $?
fi

if "$INSTALL_ISTIO" = "true"
then
    echo "Installing Istio."
    # Download Istio.
    curl -sL "https://github.com/istio/istio/releases/download/$ISTIO_VERSION/istio-$ISTIO_VERSION-osx.tar.gz" | tar xz

    if [ $? -ne 0 ]
    then
        echo "Could not download Istio version $ISTIO_VERSION."
        exit $?
    fi

    chmod +x ./istio-$ISTIO_VERSION/bin/istioctl

    # Create a namespace for the Istio services.
    kubectl create namespace istio-system --save-config
    if [ $? -ne 0 ]
    then
        echo "Could not create the istio-system namespace."
        exit $?
    fi

    ./istio-$ISTIO_VERSION/bin/istioctl manifest apply --set values.global.mtls.enabled=true --set values.global.controlPlaneSecurityEnabled=true --logtostderr
    if [ $? -ne 0 ]
    then
        echo "Could not apply the Istio manifest."
        exit $?
    fi

    kubectl label namespace default istio-injection=enabled

    echo "Adding base routing rules."
    kubectl apply -f ../Cluster/networking/routing_base.yml
    if [ $? -ne 0 ]
    then
        echo "Could not apply the base routing rules to Istio."
        exit $?
    fi
fi

# Create ACR role.
echo "Creating ACR role."
client_id=$(az aks show --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME --query "servicePrincipalProfile.clientId" --output tsv)
if [ $? -ne 0 ]
then
    echo "Could not get the client id for $AKS_CLUSTER_NAME."
    exit $?
fi

# Get the ACR registry resource id
acr_id=$(az acr show --name $CONTAINER_REGISTRY_NAME --resource-group $CONTAINER_REGISTRY_RESOURCE_GROUP --query "id" --output tsv)
if [ $? -ne 0 ]
then
    echo "Could not get the client id for $AKS_CLUSTER_NAME."
    exit $?
fi

# Create role assignment
az role assignment create --assignee $client_id --role acrpull --scope $acr_id
if [ $? -ne 0 ]
then
    echo "Could not create an ACR role in the AKS cluster."
    exit $?
fi