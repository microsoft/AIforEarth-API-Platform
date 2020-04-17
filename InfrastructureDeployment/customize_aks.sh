#!/bin/bash

source ./InfrastructureDeployment/setup_env.sh

# Create Kubernetes Dashboard Account
echo "Applying dashboard admin account."
kubectl apply -f ./Cluster/policy/dashboard-admin.yaml
if [ $? -ne 0 ]
then
    echo "Could not apply the dashboard policy for the $AKS_CLUSTER_NAME AKS cluster."
    echo "customize_aks.sh failed"
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
        echo "customize_aks.sh failed"
        exit $?
    fi

    chmod +x ./istio-$ISTIO_VERSION/bin/istioctl

    ./istio-$ISTIO_VERSION/bin/istioctl manifest apply --set values.global.mtls.enabled=true --set values.global.controlPlaneSecurityEnabled=true --logtostderr
    iteration=1
    while [ $? -ne 0 ]
    do
        if [ $iteration -ge 10 ]
        then
            echo "Could not apply the Istio manifest."
            echo "customize_aks.sh failed"
            exit $?
        fi

        echo "Could not apply the Istio manifest. Retrying in 10 seconds."
        iteration=$(($iteration+1))
        echo "Try $iteration of 10"
        sleep 10
        ./istio-$ISTIO_VERSION/bin/istioctl manifest apply --set values.global.mtls.enabled=true --set values.global.controlPlaneSecurityEnabled=true --logtostderr
    done

    # Create a namespace for the Istio services.
    kubectl create namespace istio-system --save-config
    iteration=1
    while [ $? -ne 0 ]
    do
        if [ $iteration -ge 10 ]
        then
            echo "Could not create a namespace for the Istio services."
            echo "customize_aks.sh failed"
            exit $?
        fi

        echo "Could not create a namespace for the Istio services. Retrying in 10 seconds."
        iteration=$(($iteration+1))
        echo "Try $iteration of 10"
        sleep 10
        kubectl create namespace istio-system --save-config
    done

    echo "Adding base routing rules."
    kubectl apply -f ./Cluster/networking/routing_base.yml
    iteration=1
    # If this fails, it probably means that the application of the manifest failed, so try that first.
    while [ $? -ne 0 ]
    do
        if [ $iteration -ge 10 ]
        then
            echo "Could not apply the base routing rules to Istio."
            echo "customize_aks.sh failed"
            exit $?
        fi

        echo "Could not apply the base routing rules to Istio. Retrying in 10 seconds."
        iteration=$(($iteration+1))
        echo "Try $iteration of 10"
        sleep 10
        ./istio-$ISTIO_VERSION/bin/istioctl manifest apply --set values.global.mtls.enabled=true --set values.global.controlPlaneSecurityEnabled=true --logtostderr
        kubectl apply -f ./Cluster/networking/routing_base.yml
    done
fi

# Create ACR role.  This lets AKS access the container registry that holds the container images.
echo "Creating ACR role."
client_id=$(az aks show --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME --query "servicePrincipalProfile.clientId" --output tsv)
if [ $? -ne 0 ]
then
    echo "Could not get the client id for $AKS_CLUSTER_NAME."
    echo "customize_aks.sh failed"
    exit $?
fi

# Get the ACR registry resource id
acr_id=$(az acr show --name $CONTAINER_REGISTRY_NAME --resource-group $CONTAINER_REGISTRY_RESOURCE_GROUP --query "id" --output tsv)
if [ $? -ne 0 ]
then
    echo "Could not get the client id for $AKS_CLUSTER_NAME."
    echo "customize_aks.sh failed"
    exit $?
fi

# Create role assignment
az role assignment create --assignee $client_id --role AcrPull --scope $acr_id
if [ $? -ne 0 ]
then
    echo "Could not create an ACR role in the AKS cluster."
    echo "customize_aks.sh failed"
    exit $?
fi