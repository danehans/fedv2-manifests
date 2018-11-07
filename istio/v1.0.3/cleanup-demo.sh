#!/usr/bin/env bash
#
# TODO: The bookinfo gateway is not passing curl -I after clean and re-running demo
# even though the ingress-gw svc is getting a lb ip from gke.

export ISTIO_VERSION=v1.0.3

echo "## Deleting the federated bookinfo gateway..."
kubectl delete -f istio/$ISTIO_VERSION/samples/bookinfo/bookinfo-gateway.yaml 2> /dev/null

sleep 5

echo "## Deleting the federated Istio custom resource types used by the bookinfo gateway..."
kubefed2 federate disable VirtualService --delete-from-api

echo "## Deleting the sample bookinfo application..."
kubectl delete -f istio/$ISTIO_VERSION/samples/bookinfo/bookinfo.yaml 2> /dev/null

sleep 5

echo "## Removing default namespace label used for sidecar injection..."
kubectl label namespace default istio-injection- 2> /dev/null

echo "## Deleting MutatingWebhookConfiguration (non-federated) due to Issue #389..."
for i in 1 2; do kubectl delete -f istio/$ISTIO_VERSION/src/mutating-webhook-configuration.yaml --context cluster$i; done

sleep 3

echo "## Deleting the Federated Istio custom resources..."
kubectl delete -f istio/$ISTIO_VERSION/install/istio-types.yaml 2> /dev/null

sleep 5

echo "## Removing federated Kubernetes resource types required for Istio..."
kubefed2 federate disable CustomResourceDefinition --delete-from-api
kubefed2 federate disable ClusterRole --delete-from-api
kubefed2 federate disable ClusterRoleBinding --delete-from-api
kubefed2 federate disable RoleBinding --delete-from-api
kubefed2 federate disable HorizontalPodAutoscaler --delete-from-api
echo "## Federated Kubernetes resource types required for Istio have been removed."

sleep 5

echo "## Deleting Federated Istio..."
kubectl delete -f istio/$ISTIO_VERSION/install/istio.yaml 2> /dev/null
sleep 30

echo "## Updating the fed-v2 service accounts in target clusters due to issue #354..."
for i in 1 2; do kubectl patch clusterrole/federation-controller-manager:cluster$i-cluster1 -p='{"rules":[{"apiGroups":["*"],"resources":["*"],"verbs":["*"]}]}' --context cluster$i; done

echo "## Federated Istio Demo Cleanup Finished..."
echo "## Waiting 60 seconds while resources are fully removed from Kubernetes."
sleep 60