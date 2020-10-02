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

az aks get-credentials --resource-group $AKS_RESOURCE_GROUP_NAME --name $AKS_CLUSTER_NAME

if "$INSTALL_ISTIO" = "true"
then
    echo "Installing Istio."
    # Download Istio.
    # Change link for arch type
    # https://github.com/istio/istio/releases/tag/1.4.5
    curl -sL "https://github.com/istio/istio/releases/download/$ISTIO_VERSION/istio-$ISTIO_VERSION-osx.tar.gz" | tar xz

    if [ $? -ne 0 ]
    then
        echo "Could not download Istio version $ISTIO_VERSION."
        echo "customize_aks.sh failed"
        exit $?
    fi

    chmod +x ./istio-$ISTIO_VERSION/bin/istioctl

    ./istio-$ISTIO_VERSION/bin/istioctl manifest apply --set values.global.controlPlaneSecurityEnabled=true
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
        ./istio-$ISTIO_VERSION/bin/istioctl manifest apply --set values.global.controlPlaneSecurityEnabled=true
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
        ./istio-$ISTIO_VERSION/bin/istioctl manifest apply --set values.global.controlPlaneSecurityEnabled=true
        kubectl apply -f ./Cluster/networking/routing_base.yml
    done
fi

kubectl label namespace default istio-injection=enabled
