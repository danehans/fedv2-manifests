# Federated Istio User Guide

##TODOs
2. Figure out why `sdsUdsPath` and `sdsRefreshDelay` had to be disabled from mesh config. Maybe b/c mutwebhookconfig?
3. Users _MUST_ clone my branch b/c `kubefed2` bin needs to get built.

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

Change to the fedv2-manifests project root directory and use `kubectl` to install the Federated Istio manifests:
```bash
kubectl apply -f istio/$ISTIO_VERSION/namespaces
kubectl apply -f istio/$ISTIO_VERSION/crds
kubectl apply -f istio/$ISTIO_VERSION/configmaps
kubectl apply -f istio/$ISTIO_VERSION/serviceaccounts
kubectl apply -f istio/$ISTIO_VERSION/clusterroles
kubectl apply -f istio/$ISTIO_VERSION/clusterrolebindings
kubectl apply -f istio/$ISTIO_VERSION/roles
kubectl apply -f istio/$ISTIO_VERSION/rolebindings
kubectl apply -f istio/$ISTIO_VERSION/services
kubectl apply -f istio/$ISTIO_VERSION/deployments
kubectl apply -f istio/$ISTIO_VERSION/jobs
kubectl apply -f istio/$ISTIO_VERSION/horizontalpodautoscalers
```

Since the sidecar-injector pod patches the client `caBundle` of the `MutatingWebhookConfiguration` resource with the
sidecar-injector secret data, it can not be federated. When the resource gets patched, the `resourceVersion` field is
updated, causing a propagated version mismatch between the federated and target resources. When the fedv2 sync
controller sees the mismatch, it will re-propagate the `MutatingWebhookConfiguration` resource which contains the empty
`caBundle`. For the time being, deploy the `MutatingWebhookConfiguration` resource to clusters individually:
```bash
$ kubectl apply -f istio/$ISTIO_VERSION/src/mutating-webhook-configuration.yaml --context cluster1
$ kubectl apply -f istio/$ISTIO_VERSION/src/mutating-webhook-configuration.yaml --context cluster2
```

## Istio Deployment Verification
Verify Istio CRDs have been propagated to `cluster1`:
```bash
$ kubectl get crds --context cluster1 | grep istio
apikeys.config.istio.io                                                   2018-10-24T15:17:48Z
attributemanifests.config.istio.io                                        2018-10-24T15:17:52Z
authorizations.config.istio.io                                            2018-10-24T15:17:56Z
checknothings.config.istio.io                                             2018-10-24T15:17:57Z
circonuses.config.istio.io                                                2018-10-24T15:17:57Z
deniers.config.istio.io                                                   2018-10-24T15:17:57Z
destinationpolicies.config.istio.io                                       2018-10-24T15:17:58Z
destinationrules.networking.istio.io                                      2018-10-24T15:17:59Z
egressrules.config.istio.io                                               2018-10-24T15:17:59Z
fluentds.config.istio.io                                                  2018-10-24T15:18:00Z
gateways.networking.istio.io                                              2018-10-24T15:18:00Z
httpapispecbindings.config.istio.io                                       2018-10-24T15:18:01Z
httpapispecs.config.istio.io                                              2018-10-24T15:18:02Z
kubernetesenvs.config.istio.io                                            2018-10-24T15:18:02Z
kuberneteses.config.istio.io                                              2018-10-24T15:18:03Z
listcheckers.config.istio.io                                              2018-10-24T15:18:04Z
listentries.config.istio.io                                               2018-10-24T15:18:04Z
logentries.config.istio.io                                                2018-10-24T15:18:05Z
memquotas.config.istio.io                                                 2018-10-24T15:18:06Z
metrics.config.istio.io                                                   2018-10-24T15:18:06Z
noops.config.istio.io                                                     2018-10-24T15:18:07Z
opas.config.istio.io                                                      2018-10-24T15:18:08Z
policies.authentication.istio.io                                          2018-10-24T15:18:08Z
prometheuses.config.istio.io                                              2018-10-24T15:18:09Z
quotas.config.istio.io                                                    2018-10-24T15:18:10Z
quotaspecbindings.config.istio.io                                         2018-10-24T15:18:10Z
quotaspecs.config.istio.io                                                2018-10-24T15:18:11Z
rbacs.config.istio.io                                                     2018-10-24T15:18:12Z
reportnothings.config.istio.io                                            2018-10-24T15:18:12Z
routerules.config.istio.io                                                2018-10-24T15:18:13Z
rules.config.istio.io                                                     2018-10-24T15:18:14Z
servicecontrolreports.config.istio.io                                     2018-10-24T15:18:14Z
servicecontrols.config.istio.io                                           2018-10-24T15:18:15Z
serviceentries.networking.istio.io                                        2018-10-24T15:18:15Z
servicerolebindings.config.istio.io                                       2018-10-24T15:18:16Z
serviceroles.config.istio.io                                              2018-10-24T15:18:17Z
solarwindses.config.istio.io                                              2018-10-24T15:18:18Z
stackdrivers.config.istio.io                                              2018-10-24T15:18:18Z
statsds.config.istio.io                                                   2018-10-24T15:18:19Z
stdios.config.istio.io                                                    2018-10-24T15:18:20Z
tracespans.config.istio.io                                                2018-10-24T15:18:20Z
virtualservices.networking.istio.io                                       2018-10-24T15:18:21Z
```

Verify Istio configmaps have been propagated to `cluster1`:
```bash
$ kubectl get configmaps -n istio-system --context cluster1
NAME                              DATA      AGE
istio                             1         20s
istio-galley-configuration        1         20s
istio-grafana-custom-resources    2         20s
istio-mixer-custom-resources      1         19s
istio-security-custom-resources   2         19s
istio-sidecar-injector            1         19s
istio-statsd-prom-bridge          1         18s
prometheus                        1         19s
```

Verify Istio serviceaccounts have been propagated to `cluster1`:
```bash
$ kubectl get serviceaccounts -n istio-system --context cluster1
NAME                                     SECRETS   AGE
default                                  1         18m
istio-citadel-service-account            1         10s
istio-cleanup-old-ca-service-account     1         10s
istio-egressgateway-service-account      1         10s
istio-ingress-service-account            1         10s
istio-ingressgateway-service-account     1         10s
istio-mixer-post-install-account         1         9s
istio-mixer-service-account              1         10s
istio-pilot-service-account              1         9s
istio-sidecar-injector-service-account   1         8s
prometheus                               1         9s
```

Verify Istio clusterroles have been propagated to `cluster1`:
```bash
$ kubectl get clusterroles --context cluster1 | grep istio
istio-citadel-istio-system                                             5m
istio-cleanup-old-ca-istio-system                                      5m
istio-ingress-istio-system                                             5m
istio-mixer-istio-system                                               5m
istio-mixer-post-install-istio-system                                  5m
istio-pilot-istio-system                                               5m
istio-sidecar-injector-istio-system                                    5m
prometheus-istio-system                                                5m
```

Verify Istio clusterrolebindings have been propagated to `cluster1`:
```bash
$ kubectl get clusterrolebinding --context cluster1 | grep istio
istio-citadel-istio-system                               44s
istio-ingress-istio-system                               43s
istio-mixer-admin-role-binding-istio-system              43s
istio-mixer-post-install-role-binding-istio-system       43s
istio-pilot-istio-system                                 43s
istio-sidecar-injector-admin-role-binding-istio-system   42s
prometheus-istio-system                                  43s
```

Verify Istio roles have been propagated to `cluster1`:
```bash
$ kubectl -n istio-system get roles --context cluster1
NAME                                AGE
istio-cleanup-old-ca-istio-system   27s
```

Verify Istio rolebindings have been propagated to `cluster1`:
```bash
$ kubectl -n istio-system get rolebindings --context cluster1
NAME                                AGE
istio-cleanup-old-ca-istio-system   27s
```

Verify Istio services have been propagated to `cluster1`. __Note:__: `istio-ingress` uses service type `LoadBalancer`.
It may take several minutes for the EXTERNAL-IP field to be populated. This type of service requires cloud load-balancer
support. Reference the [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer)
documentation to learn more.
```bash
$ kubectl -n istio-system get services --context cluster1
NAME                       TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                               AGE
istio-citadel              ClusterIP      10.109.179.4     <none>        8060/TCP,9093/TCP                                                     20s
istio-egressgateway        ClusterIP      10.107.231.74    <none>        80/TCP,443/TCP                                                        19s
istio-ingress              LoadBalancer   10.110.46.69     <pending>     80:32000/TCP,443:30495/TCP                                            19s
istio-ingressgateway       NodePort       10.109.163.96    <none>        80:31380/TCP,443:31390/TCP,31400:31400/TCP                            19s
istio-pilot                ClusterIP      10.111.223.75    <none>        15003/TCP,15005/TCP,15007/TCP,15010/TCP,15011/TCP,8080/TCP,9093/TCP   19s
istio-policy               ClusterIP      10.106.1.236     <none>        9091/TCP,15004/TCP,9093/TCP                                           19s
istio-sidecar-injector     ClusterIP      10.108.206.133   <none>        443/TCP                                                               18s
istio-statsd-prom-bridge   ClusterIP      10.97.122.243    <none>        9102/TCP,9125/UDP                                                     18s
istio-telemetry            ClusterIP      10.101.57.160    <none>        9091/TCP,15004/TCP,9093/TCP,42422/TCP                                 17s
prometheus                 ClusterIP      10.109.35.241    <none>        9090/TCP                                                              18s
```

Verify Istio mutatingwebhookconfigurations have been propagated to `cluster1`:
```bash
$ kubectl get mutatingwebhookconfigurations --context cluster1
NAME                     CREATED AT
istio-sidecar-injector   2018-10-24T16:11:55Z
```

Verify Istio deployments have been propagated to `cluster1`. Make sure each deployment show the 1 under the AVAILABLE
column:
```bash
$ kubectl -n istio-system get deployments --context cluster1
NAME                     DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
istio-citadel            1         1         1            1           5m
istio-egressgateway      1         1         1            1           5m
istio-ingress            1         1         1            1           5m
istio-ingressgateway     1         1         1            1           5m
istio-pilot              1         1         1            1           5m
istio-policy             1         1         1            1           5m
istio-sidecar-injector   1         1         1            1           5m
istio-statsd-prom-bridge 1         1         1            1           5m
istio-telemetry          1         1         1            1           5m
prometheus               1         1         1            1           5m
```

Verify Istio jobs have been propagated to `cluster1`:
```bash
$ kubectl get jobs -n istio-system --context cluster1
NAME                       DESIRED   SUCCESSFUL   AGE
istio-cleanup-old-ca       1         1            10s
istio-mixer-post-install   1         1            10s
```

Verify Istio horizontalpodautoscalers have been propagated to `cluster1`:
```bash
$ kubectl get horizontalpodautoscalers -n istio-system --context cluster1
NAME                   REFERENCE                         TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
istio-egressgateway    Deployment/istio-egressgateway    <unknown>/80%   1         1         0          17s
istio-ingress          Deployment/istio-ingress          <unknown>/80%   1         1         0          16s
istio-ingressgateway   Deployment/istio-ingressgateway   <unknown>/80%   1         1         0          16s
```
Repeat the above commands, replacing `cluster1` with `cluster2`, to verify resource propagation to `cluster2`.

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
$ kubectl apply -f istio/$ISTIO_VERSION/samples/bookinfo/bookinfo.yaml
```

Verify the bookinfo deployments have been propagated to both clusters.
```bash
$ kubectl get deployments --context cluster1
NAME             DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
details-v1       1         1         1            1           4m
productpage-v1   1         1         1            1           4m
reviews-v1       1         1         1            1           4m
reviews-v2       1         1         1            1           4m
reviews-v3       1         1         1            1           4m
```

Verify the bookinfo services have been propagated to both clusters.
```bash
$ kubectl get services --context cluster1
NAME          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
details       ClusterIP   10.107.10.36     <none>        9080/TCP   5m
kubernetes    ClusterIP   10.96.0.1        <none>        443/TCP    1h
productpage   ClusterIP   10.111.161.112   <none>        9080/TCP   5m
reviews       ClusterIP   10.96.84.246     <none>        9080/TCP   5m
```
Repeat the above commands, replacing `cluster1` with `cluster2`, to verify resource propagation to `cluster2`.

## Cleanup

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
```

Uninstall the federation-v2 control-plane by changing to the federation-v2 project root directory and run:
```bash
./scripts/delete-federation.sh
```
