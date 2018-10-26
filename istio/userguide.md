# Federated Istio User Guide

This is an early access preview of Federated Istio.

##TODOs
1. Cut a release that includes the kubefed2 bin.

## Introduction

__TODO__: Add Intro to fedv2 and istio.

This guide uses branch [danehans/marun_combined](https://github.com/danehans/federation-v2/tree/marun_combined) of the
federation-v2 project which contains commits yet to merge upstream.

https://github.com/kubernetes-sigs/federation-v2/blob/master/docs/development.md#automated-deployment


## Kubernetes Clusters
You need 2 or more Kubernetes v1.11 or greater clusters. Follow the fed-v2
[user guide](https://github.com/kubernetes-sigs/federation-v2/blob/master/docs/userguide.md)
for deploying k8s clusters/fed-v2 control-plane. The [fedv2-manifests](https://github.com/danehans/fedv2-manifests)
project contains manifests for installing Federated Istio.

## Federation v2 Deployment
__TODOs__:
- Cut a release of fedv2-manifests that includes kubefed2 bin, install.yaml that references danehans:test
controller-manager image. Update docs accordingly.
- Simple installer script that can be curl'd.

Follow the fed-v2 [user guide](https://github.com/kubernetes-sigs/federation-v2/blob/master/docs/userguide.md)
for deploying k8s clusters/fed-v2 control-plane. The [fedv2-manifests](https://github.com/danehans/fedv2-manifests)
project contains manifests for installing Federated Istio.

Fed-v2 includes `core` federated resources such as `FederatedDeployment`, `FederatedConfigMap`, etc.. Use
`kubectl get federatedtypeconfigs -n federation-system` to view the list of federated type configs deployed by default.
Use the `kubefed2 federate` command to federate additional resources required for Istio. For example:

__TODO__: Steps for downlaoding fedv2-manifests release, extracting tarball and copying kubefedv2 bin to /use/local/bin
and chmod+x
```bash
kubefed2 federate --namespaced=false --group=apiextensions.k8s.io \
--version=v1beta1 --kind=CustomResourceDefinition
kubefed2 federate --namespaced=false --group=rbac.authorization.k8s.io \
--version=v1beta1 --kind=ClusterRole
kubefed2 federate --namespaced=false --group=rbac.authorization.k8s.io \
--version=v1beta1 --kind=ClusterRoleBinding
kubefed2 federate --namespaced=true --group=rbac.authorization.k8s.io \
--version=v1beta1 --kind=Role
kubefed2 federate --namespaced=true --group=rbac.authorization.k8s.io \
--version=v1beta1 --kind=RoleBinding
kubefed2 federate --namespaced=true --group=autoscaling --version=v2beta1 \
--kind=HorizontalPodAutoscaler
kubefed2 federate --namespaced=false --group=admissionregistration.k8s.io \
--version=v1beta1 --kind=MutatingWebhookConfiguration
kubefed2 federate --namespaced=true --group=extensions --version=v1beta1 \
--kind=Deployment
```
__Note__: Istio v.0.8.0 uses version `v1beta1` of the `Deployment` resource, while the Federation-v2 `core` group API
includes `v1` of this type. Use `kubectl get federateddeployments.generated -n istio-system` to view version `v1beta1`
of the `FederatedDeployment` resource.

You must update the fedv2 service account clusterrole for each target cluster due to
[issue #354](https://github.com/kubernetes-sigs/federation-v2/issues/354):
```bash
$ kubectl patch clusterrole/federation-controller-manager:cluster1-cluster1 \
-p='{"rules":[{"apiGroups":["*"],"resources":["*"],"verbs":["*"]},{"nonResourceURLs":["/metrics"],"verbs":["get"]}]}' \
--context cluster1
$ kubectl patch clusterrole/federation-controller-manager:cluster2-cluster1 \
-p='{"rules":[{"apiGroups":["*"],"resources":["*"],"verbs":["*"]},{"nonResourceURLs":["/metrics"],"verbs":["get"]}]}' \
--context cluster2
```

Set the version of Federated Istio manifests to use:
```bash
export ISTIO_VERSION=v0.8.0
```

Change to the fedv2-manifests project root directory and use `kubectl` to install the Federated Istio manifests.

__Note__: The `istio/$ISTIO_VERSION0/services/federatedservice-ingress-gateway-template.yaml` manifest uses
`type: LoadBalancer`. If you intend on deploying Federated Istio to clusters that use another type to expose
services, you must change this field. An override manifest can be used to accomplish this once
([issue #367](https://github.com/kubernetes-sigs/federation-v2/issues/367)) is implemented.
```bash
kubectl create -f istio/$ISTIO_VERSION/namespaces
kubectl create -f istio/$ISTIO_VERSION/crds
kubectl create -f istio/$ISTIO_VERSION/configmaps
kubectl create -f istio/$ISTIO_VERSION/serviceaccounts
kubectl create -f istio/$ISTIO_VERSION/clusterroles
kubectl create -f istio/$ISTIO_VERSION/clusterrolebindings
kubectl create -f istio/$ISTIO_VERSION/roles
kubectl create -f istio/$ISTIO_VERSION/rolebindings
kubectl create -f istio/$ISTIO_VERSION/services
kubectl create -f istio/$ISTIO_VERSION/deployments
kubectl create -f istio/$ISTIO_VERSION/jobs
kubectl create -f istio/$ISTIO_VERSION/horizontalpodautoscalers
```

Since the sidecar-injector pod patches the client `caBundle` of the `MutatingWebhookConfiguration` resource with the
sidecar-injector secret data, it can not be federated. When the resource gets patched, the `resourceVersion` field is
updated, causing a propagated version mismatch between the federated and target resources. When the fedv2 sync
controller sees the mismatch, it will re-propagate the `MutatingWebhookConfiguration` resource which contains the empty
`caBundle`. For the time being, deploy the `MutatingWebhookConfiguration` resource to clusters individually:
```bash
$ kubectl create -f istio/$ISTIO_VERSION/src/mutating-webhook-configuration.yaml --context cluster1
$ kubectl create -f istio/$ISTIO_VERSION/src/mutating-webhook-configuration.yaml --context cluster2
```

## Istio Deployment Verification

```bash
$ kubectl get pods -n istio-system --context cluster1
NAME                                      READY     STATUS      RESTARTS   AGE
istio-citadel-6f875b9fdb-fg6n8            1/1       Running     0          2m
istio-cleanup-old-ca-xxspl                0/1       Completed   0          2m
istio-egressgateway-8b98f49f6-mfsxb       1/1       Running     0          2m
istio-ingress-69c65cc9dd-dwk7x            1/1       Running     0          2m
istio-ingressgateway-657d7c54fb-qv4j6     1/1       Running     0          2m
istio-mixer-post-install-bmwtl            0/1       Error       0          2m
istio-mixer-post-install-bqxqs            0/1       Completed   0          2m
istio-mixer-post-install-xsbkg            0/1       Error       0          2m
istio-pilot-7cfb4cc676-nfhs5              2/2       Running     0          2m
istio-policy-7c4448ccf6-btj85             2/2       Running     0          2m
istio-sidecar-injector-fc9dd55f7-t7dp9    1/1       Running     0          2m
istio-statsd-prom-bridge-9c78dbbc-gzwsz   1/1       Running     0          2m
istio-telemetry-785947f8c8-smbcr          2/2       Running     0          2m
prometheus-9c994b8db-zj7n8                1/1       Running     0          2m
```
__Note__: You may see pods with the prefix `istio-mixer-post-install` in an error state. This is common and you only
need 1 of these pods to be in a `Completed` state.

Your Federated Istio meshes are now ready to run applications. You can now proceed to the Bookinfo Deployment
section. You can view other details of the Istio installation by replacing `pods` with the correct resource
name (i.e. `configmaps`) or the federated equivalent (i.e. federatedconfigmaps).

## Bookinfo Deployment
Label the default namespace with `istio-injection=enabled`:
```bash
$ kubectl label namespace default istio-injection=enabled
$ kubectl get namespace -L istio-injection --context cluster1
NAME                       STATUS    AGE       ISTIO-INJECTION
default                    Active    1h        enabled
federation-system          Active    1h
istio-system               Active    1h
kube-multicluster-public   Active    1h
kube-public                Active    1h
kube-system                Active    1h
```

Install the [bookinfo](https://istio.io/docs/examples/bookinfo/) sample application to verify Istio is operating
properly:
```bash
$ kubectl create -f istio/$ISTIO_VERSION/samples/bookinfo/bookinfo.yaml
```

Verify the bookinfo pods have been propagated to both clusters.
```bash
$ kubectl get pod --context cluster1
NAME                             READY     STATUS    RESTARTS   AGE
NAME                             READY     STATUS    RESTARTS   AGE
details-v1-fd75f896d-72x4l       2/2       Running   0          13s
productpage-v1-57f4d6b98-f7dkz   2/2       Running   0          9s
ratings-v1-6ff8679f7b-kphr4      2/2       Running   0          13s
reviews-v1-5b66f78dc9-kr2jw      2/2       Running   0          11s
reviews-v2-5d6d58488c-tr982      2/2       Running   0          10s
reviews-v3-5469468cff-5f9fk      2/2       Running   0          9s
```

Repeat the above command, replacing `cluster1` with `cluster2`, to verify resource propagation to `cluster2`.

Federate the Istio `Gateway and `VirtualService` resources:
```bash
$ kubefed2 federate --namespaced=true --group=networking.istio.io \
--version=v1alpha3 --kind=Gateway
$ kubefed2 federate --namespaced=true --group=networking.istio.io \
--version=v1alpha3 --kind=VirtualService
```

Define the Istio ingress gateway for the bookinfo application:
```bash
$ kubectl create -f istio/$ISTIO_VERSION/samples/bookinfo/bookinfo-gateway.yaml
```

You can verify the status of the Istio `Gateway` and `VirtualService resources with:
```bash
$ kubectl get gateways --context cluster1
NAME               AGE
bookinfo-gateway   17s

$ kubectl get virtualservices --context cluster1
NAME       AGE
bookinfo   26s
```
Repeat the above command, replacing `cluster1` with `cluster2`, to verify resource propagation to `cluster2`.

Follow the official Istio
[bookinfo documentation](https://archive.istio.io/v0.8/docs/guides/bookinfo/#determining-the-ingress-ip-and-port) for
determining the Ingress IP address and port for testing.

## Cleanup

Uninstall the bookinfo ingress gateway:
```bash
$ kubectl delete -f istio/$ISTIO_VERSION/samples/bookinfo/bookinfo-gateway.yaml

```
Uninstall the bookinfo sample application:
```bash
$ kubectl delete -f istio/$ISTIO_VERSION/samples/bookinfo/bookinfo.yaml

```
Uninstall Federated Istio:
```bash
kubectl delete -f istio/$ISTIO_VERSION/horizontalpodautoscalers
kubectl delete -f istio/$ISTIO_VERSION/jobs
kubectl delete -f istio/$ISTIO_VERSION/deployments
kubectl delete -f istio/$ISTIO_VERSION/services
kubectl delete -f istio/$ISTIO_VERSION/rolebindings
kubectl delete -f istio/$ISTIO_VERSION/roles
kubectl delete -f istio/$ISTIO_VERSION/clusterrolebindings
kubectl delete -f istio/$ISTIO_VERSION/clusterroles
kubectl delete -f istio/$ISTIO_VERSION/serviceaccounts
kubectl delete -f istio/$ISTIO_VERSION/configmaps
kubectl delete -f istio/$ISTIO_VERSION/crds
kubectl delete -f istio/$ISTIO_VERSION/namespaces
kubectl delete -f istio/$ISTIO_VERSION/src/mutating-webhook-configuration.yaml --context cluster1
kubectl delete -f istio/$ISTIO_VERSION/src/mutating-webhook-configuration.yaml --context cluster2
```

Uninstall the federation-v2 control-plane by changing to the federation-v2 project root directory and run:
```bash
cd $GOPATH/src/github.com/kubernetes-sigs/federation-v2
./scripts/delete-federation.sh
```
