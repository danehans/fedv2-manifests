__TODOs:__

1. Figure out why statsd deployment is not being propagated.
2. Figure out why `sdsUdsPath` and `sdsRefreshDelay` had to be disabled from mesh config. Maybe b/c mutwebhookconfig?
3. Users _MUST_ clone my branch b/c `kubefed2` bin needs to get built.

This guide uses branch [danehans/marun_combined](https://github.com/danehans/federation-v2/tree/marun_combined) of the
federation-v2 project which contains commits yet to merge upstream.

https://github.com/kubernetes-sigs/federation-v2/blob/master/docs/development.md#automated-deployment


Follow the fed-v2 [user guide](https://github.com/kubernetes-sigs/federation-v2/blob/master/docs/userguide.md)
for deploying k8s clusters/fed-v2 control-plane. The [fedv2-manifests](https://github.com/danehans/fedv2-manifests) project contains manifests for installing Federated Istio.

Fed-v2 includes `core` federated resources such as `FederatedDeployment`, `FederatedConfigMap`, etc.. Use
`kubectl get federatedtypeconfigs -n federation-system` to view the list of federated type configs deployed by default. Use
the `kubefed2 federate` command to federate additional resources required for Istio. For example:
```
./bin/kubefed2 federate --namespaced=false --group=apiextensions.k8s.io \
--version=v1beta1 --kind=CustomResourceDefinition
./bin/kubefed2 federate --namespaced=false --group=rbac.authorization.k8s.io \
--version=v1beta1 --kind=ClusterRole
./bin/kubefed2 federate --namespaced=false --group=rbac.authorization.k8s.io \
--version=v1beta1 --kind=ClusterRoleBinding
./bin/kubefed2 federate --namespaced=true --group=rbac.authorization.k8s.io \
--version=v1beta1 --kind=RoleBinding
./bin/kubefed2 federate --namespaced=true --group=autoscaling --version=v2beta1 \
--kind=HorizontalPodAutoscaler
./bin/kubefed2 federate --namespaced=false --group=admissionregistration.k8s.io \
--version=v1beta1 --kind=MutatingWebhookConfiguration
# Deployment v1beta1 must ve created b/c core includes v1
# To view: $ kubectl get federateddeployments.generated -n istio-system
./bin/kubefed2 federate --namespaced=true --group=extensions --version=v1beta1 \
--kind=Deployment
```

The Kubernetes [API Overview](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.11) is a good resource for
supplying the correct values for federating resources.

You must update the fedv2 service account cluster role for each target cluster due to [issue #354](https://github.com/kubernetes-sigs/federation-v2/issues/354):
```
kubectl patch clusterrole/federation-controller-manager:cluster1-cluster1 \
-p='{"rules":[{"apiGroups":["*"],"resources":["*"],"verbs":["*"]},{"nonResourceURLs":["/metrics"],"verbs":["get"]}]}'
kubectl patch clusterrole/federation-controller-manager:cluster2-cluster1 \
-p='{"rules":[{"apiGroups":["*"],"resources":["*"],"verbs":["*"]},{"nonResourceURLs":["/metrics"],"verbs":["get"]}]}' \
--context cluster2
```

???Create namespace `istio-system` in the host cluster. __Note__: The fed-v2 controller-manager will automatically propagate the namespace to target clusters.
```
kubectl create ns istio-system --context cluster1
```

Verify namespace `istio-system` has been propagated to `cluster2`:
```
$ kubectl get ns --context cluster2
NAME                       STATUS    AGE
default                    Active    9m
federation-system          Active    6m
istio-system               Active    14s
kube-multicluster-public   Active    5m
kube-public                Active    9m
kube-system                Active    9m
```

Set the version of Federated Istio manifests to use:
```
export ISTIO_VERSION=v0.8
```

Change to the danehans/fedv2-manifests root directory and use `kubectl` to install the Federated Istio manifests:
```
kubectl apply -f istio/$ISTIO_VERSION/crds
kubectl apply -f istio/$ISTIO_VERSION/configmaps
kubectl apply -f istio/$ISTIO_VERSION/serviceaccounts
kubectl apply -f istio/$ISTIO_VERSION/clusterroles
kubectl apply -f istio/$ISTIO_VERSION/clusterrolebindings
kubectl apply -f istio/$ISTIO_VERSION/rolebindings
kubectl apply -f istio/$ISTIO_VERSION/services
kubectl apply -f istio/$ISTIO_VERSION/deployments
kubectl apply -f istio/$ISTIO_VERSION/jobs
kubectl apply -f istio/$ISTIO_VERSION/horizontalpodautoscalers
kubectl apply -f istio/$ISTIO_VERSION/mutatingwebhookconfigurations

```
