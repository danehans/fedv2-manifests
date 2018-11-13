#!/usr/bin/env bash
#
# Follow the federation-v2 user guide to create k8s clusters and fedv2 control-plane.
# Then run this script from the project root directory.

export ISTIO_VERSION="v1.0.3"
export DNS_PREFIX="bookinfo"
export DNS_SUFFIX="external.daneyon.com"

echo "### Federating additional Kubernetes resource types required for Istio..."
kubefed2 federate enable CustomResourceDefinition
kubefed2 federate enable ClusterRole
kubefed2 federate enable ClusterRoleBinding
kubefed2 federate enable RoleBinding
kubefed2 federate enable HorizontalPodAutoscaler
kubefed2 federate enable MutatingWebhookConfiguration --comparison-field=Generation
sleep 5

echo "### Updating the fed-v2 service accounts in target clusters due to issue #354..."
for i in 1 2; do kubectl patch clusterrole/federation-controller-manager:cluster$i-cluster1 -p='{"rules":[{"apiGroups":["*"],"resources":["*"],"verbs":["*"]},{"nonResourceURLs":["/metrics"],"verbs":["get"]}]}' --context cluster$i; done

echo "### Creating the Istio namespace..."
kubectl create ns istio-system 2> /dev/null

echo "### Installing Federated Istio..."
kubectl create -f istio/$ISTIO_VERSION/install/istio.yaml 2> /dev/null
echo "### Waiting 60-seconds for Federated Istio resource creation to complete before proceeding with the installation..."
sleep 60

echo "### Federating the Istio custom resource types..."
kubefed2 federate enable Gateway
kubefed2 federate enable DestinationRule
kubefed2 federate enable kubernetes
kubefed2 federate enable rule
kubefed2 federate enable kubernetesenv
kubefed2 federate enable prometheus
kubefed2 federate enable metric
kubefed2 federate enable attributemanifest
kubefed2 federate enable stdio
kubefed2 federate enable logentry
sleep 3

echo "### Creating the Federated Istio custom resources..."
kubectl create -f istio/$ISTIO_VERSION/install/istio-types.yaml 2> /dev/null

echo "### Waiting 30-seconds for the Istio control-plane pods to start running..."
sleep 30

for i in 1 2; do kubectl get pods -n istio-system --context cluster$i; done
sleep 5

for i in 1 2; do kubectl get mutatingwebhookconfigurations --context cluster$i; done

echo "### Labeling the default namespace used for sidecar injection..."
kubectl label namespace default istio-injection=enabled 2> /dev/null

for i in 1 2; do kubectl get namespace -L istio-injection --context cluster$i; done
sleep 3

echo "### Deploying the sample bookinfo application..."
kubectl create -f istio/$ISTIO_VERSION/samples/bookinfo/bookinfo.yaml 2> /dev/null

echo "### Waiting 30-seconds for bookinfo pods to start running..."
sleep 30

for i in 1 2; do kubectl get pod --context cluster$i; done

echo "### Federating the Istio custom resource types used by the bookinfo gateway..."
kubefed2 federate enable VirtualService
sleep 3

echo "### Creating Federated bookinfo gateway..."
kubectl create -f istio/$ISTIO_VERSION/samples/bookinfo/bookinfo-gateway.yaml 2> /dev/null
sleep 3

echo "### Creating the external dns controller..."
kubectl create -f ./multicluster-dns/ext-dns/crd-gke-deploy.yaml 2> /dev/null
sleep 5

echo "### Creating the kube-dns configmap to support cross-cluster service discovery..."
kubectl create -f ./multicluster-dns/kube-dns/federated-configmap.yaml 2> /dev/null
sleep 5

echo "### Creating Federated Domain and bookinfo ServiceDNSRecord resource..."
kubectl create -f istio/$ISTIO_VERSION/samples/bookinfo/bookinfo-dns.yaml 2> /dev/null
sleep 3

echo "### Testing bookinfo productpage:"
echo "### curl -I http://$DNS_PREFIX.$DNS_SUFFIX/productpage"
echo "### Expecting \"HTTP/1.1 200 OK\" return code."
n=0
while [ $n -le 100 ]
do
    resp1=$(curl -w %{http_code} -s -o /dev/null http://$DNS_PREFIX.$DNS_SUFFIX/productpage)
    if [ "$resp1" = "200" ] ; then
        echo "#### Bookinfo gateway test for cluster1 succeeded with \"HTTP/1.1 $resp1 OK\" return code."
        exit 0
    fi
    echo "testing ..."
    sleep 5
    n=`expr $n + 1`
done
echo "### Federated Bookinfo Gateway tests timed-out."
echo "### Expected a \"200\" http return code, received a \"$resp\" return code."
echo "### Manually test with the following:"
echo "### curl -I http://$DNS_PREFIX.$DNS_SUFFIX/productpage"
exit 1
