#!/usr/bin/env bash

C1=cluster1
C2=cluster2

echo "### I have 2 Kubernetes clusters, with $C1 running the federation control-plane."
echo "### From a federation standpoint, $C1 is considered my \"host cluster\" and $C2 is my \"target cluster\"."
echo "### Since this is a demo $C1 is also a target cluster."
gcloud container clusters list

read -n1 -r -p "Press space to continue..." key
if [ "$key" = '' ]; then
    echo ""
    echo "### Configuring kubectl to use context $C1"
    kubectl config use-context $C1
else
    sleep
fi

read -n1 -r -p "Press space to continue..." key
if [ "$key" = '' ]; then
    echo ""
    echo "### The federation control-plane runs in the federation-system namespace"
    kubectl --context=${C1} get ns/federation-system
else
    sleep
fi

read -n1 -r -p "Press space to continue..." key
if [ "$key" = '' ]; then
    echo ""
    echo "### The federation control-plane is deployed as a statefulset and runs as a pod"
    kubectl --context=${C1} get statefulsets -n federation-system
    kubectl --context=${C1} get pods -n federation-system
else
    sleep
fi

read -n1 -r -p "Press space to continue..." key
if [ "$key" = '' ]; then
    echo ""
    echo "### \"kubefed2\" is a commandline client for managing federation."
    kubefed2 --help
else
    sleep
fi

read -n1 -r -p "Press space to continue..." key
if [ "$key" = '' ]; then
    echo ""
    echo "### The federation control-plane API is implemented as Kubernetes API extensions using CRDs"
    kubectl --context=${C1} get crds | grep fed
else
    sleep
fi

read -n1 -r -p "Press space to continue..." key
if [ "$key" = '' ]; then
    echo ""
    echo "### Federated Type Configuration declares which API types federation should handle"
    kubectl --context=${C1} -n federation-system get federatedtypeconfigs
else
    sleep
fi

read -n1 -r -p "Press space to continue..." key
if [ "$key" = '' ]; then
    echo ""
    kubectl --context=${C1} -n federation-system get federatedtypeconfig/configmaps -o yaml
    echo "### ^ is a \"configmaps\" Federated Type Configuration."
    #echo "### Template types define the representation of a resource common across clusters"
    #echo "### Placement types define which clusters the resource is intended to appear in"
    #echo "### Override types optionally define per-cluster field-level variation to apply to the template"
else
    sleep
fi

read -n1 -r -p "Press space to continue..." key
if [ "$key" = '' ]; then
    echo ""
    echo "### The cluster configuration declares which clusters federation should target"
    kubectl --context=${C1} -n federation-system get federatedclusters
else
    sleep
fi

echo "That's a high-level overview of Federation."