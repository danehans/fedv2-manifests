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

Use the correct environment:
https://github.com/kubernetes-sigs/federation-v2/tree/master/docs/environments


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

## Federated Istio Deployment

__TODO__: Steps for downloading fedv2-manifests release, extracting tarball and copying kubefedv2 bin to /use/local/bin
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
includes `v1`. Use `kubectl get federateddeployments.generated -n istio-system` to view version `v1beta1`
of the `FederatedDeployment` resource.

You must update the fedv2 service account clusterrole for each target cluster due to
[issue #354](https://github.com/kubernetes-sigs/federation-v2/issues/354):
```bash
$ for i in 1 2; do kubectl patch clusterrole/federation-controller-manager:cluster$i-cluster1 \
-p='{"rules":[{"apiGroups":["*"],"resources":["*"],"verbs":["*"]},{"nonResourceURLs":["/metrics"],"verbs":["get"]}]}' \
--context cluster$i; done
```

Set the version of Federated Istio manifests to use:
```bash
export ISTIO_VERSION=v0.8.0
```

Change to the fedv2-manifests project root directory and use `kubectl` to install the Federated Istio manifests.

__Note__: The `istio/$ISTIO_VERSION/services/federatedservice-ingress-gateway-template.yaml` manifest uses
`type: LoadBalancer`. If you intend on deploying Federated Istio to clusters that use another type to expose
services, you must change this field. An override manifest can be used to accomplish this once
([issue #367](https://github.com/kubernetes-sigs/federation-v2/issues/367)) is resolved.
```bash
$ kubectl create -R -f istio/$ISTIO_VERSION/install/
```

Since the sidecar-injector pod patches the client `caBundle` of the `MutatingWebhookConfiguration` resource with the
sidecar-injector secret data, it can not be federated. When the resource gets patched, the `resourceVersion` field is
updated, causing a propagated version mismatch between the federated and target resources. When the fedv2 sync
controller sees the mismatch, it will re-propagate the `MutatingWebhookConfiguration` resource which contains the empty
`caBundle`. For the time being, deploy the `MutatingWebhookConfiguration` resource to clusters individually:
```bash
$ for i in 1 2; do kubectl create -f istio/$ISTIO_VERSION/src/mutating-webhook-configuration.yaml \
    --context cluster$i; done
```

## Istio Deployment Verification
Verify that all the Istio control-plane pods are running in the clusters.
```bash
$ for i in 1 2; do kubectl get pods -n istio-system --context cluster$i; done
NAME                                      READY     STATUS      RESTARTS   AGE
istio-citadel-6f875b9fdb-kn8nr            1/1       Running     0          1m
istio-cleanup-old-ca-29w6x                0/1       Completed   0          1m
istio-egressgateway-8b98f49f6-kp2jq       1/1       Running     0          1m
istio-ingress-69c65cc9dd-dvhnj            1/1       Running     0          1m
istio-ingressgateway-657d7c54fb-c2mpq     1/1       Running     0          1m
istio-mixer-post-install-6kqwk            0/1       Completed   0          1m
istio-pilot-7cfb4cc676-zn995              2/2       Running     0          1m
istio-policy-7c4448ccf6-ncgzc             2/2       Running     0          1m
istio-sidecar-injector-fc9dd55f7-jt4xc    1/1       Running     1          1m
istio-statsd-prom-bridge-9c78dbbc-9xxss   1/1       Running     0          1m
istio-telemetry-785947f8c8-2sw6r          2/2       Running     0          1m
prometheus-9c994b8db-2r2tp                1/1       Running     0          1m
NAME                                      READY     STATUS      RESTARTS   AGE
istio-citadel-6f875b9fdb-7kskr            1/1       Running     0          1m
istio-cleanup-old-ca-fc6n2                0/1       Completed   0          1m
istio-egressgateway-8b98f49f6-x58p2       1/1       Running     0          1m
istio-ingress-69c65cc9dd-cmb57            1/1       Running     0          1m
istio-ingressgateway-657d7c54fb-pvt5b     1/1       Running     0          1m
istio-mixer-post-install-vz675            0/1       Completed   0          1m
istio-pilot-7cfb4cc676-rvkz6              2/2       Running     0          1m
istio-policy-7c4448ccf6-fkbjr             2/2       Running     0          1m
istio-sidecar-injector-fc9dd55f7-nncrx    1/1       Running     1          1m
istio-statsd-prom-bridge-9c78dbbc-bcjqs   1/1       Running     0          1m
istio-telemetry-785947f8c8-s8sqq          2/2       Running     0          1m
prometheus-9c994b8db-965q9                1/1       Running     0          1m
```

Verify the the `MutatingWebhookConfiguration` resources.
```bash
$ for i in 1 2; do kubectl get mutatingwebhookconfigurations --context cluster$i; done
NAME                     CREATED AT
istio-sidecar-injector   2018-10-29T16:28:16Z
NAME                     CREATED AT
istio-sidecar-injector   2018-10-29T16:28:16Z

```
Your Federated Istio meshes are now ready to run applications. You can now proceed to the Bookinfo Deployment
section. You can view other details of the Istio installation by replacing `pods` with the correct resource
name (i.e. `configmaps`) or the federated equivalent (i.e. federatedconfigmaps).

## Bookinfo Deployment
Label the default namespace with `istio-injection=enabled`.
```bash
$ kubectl label namespace default istio-injection=enabled
```

Verify the label is applied to namespace `default` in both clusters.
```bash
$ for i in 1 2; do kubectl get namespace -L istio-injection --context cluster$i; done
NAME                       STATUS    AGE       ISTIO-INJECTION
default                    Active    1h        enabled
<SNIP>
```

Install the [bookinfo](https://istio.io/docs/examples/bookinfo/) sample application to verify Istio is operating
properly.
```bash
$ kubectl create -f istio/$ISTIO_VERSION/samples/bookinfo/bookinfo.yaml
```

Verify the bookinfo pods have been propagated to both clusters.
```bash
$ for i in 1 2; do kubectl get pod --context cluster$i; done
NAME                             READY     STATUS    RESTARTS   AGE
details-v1-fd75f896d-vjmh2       2/2       Running   0          30s
productpage-v1-57f4d6b98-qb96g   2/2       Running   0          28s
ratings-v1-6ff8679f7b-nfhkh      2/2       Running   0          29s
reviews-v1-5b66f78dc9-vsj9q      2/2       Running   0          29s
reviews-v2-5d6d58488c-vw4vh      2/2       Running   0          29s
reviews-v3-5469468cff-9tp8r      2/2       Running   0          29s
NAME                             READY     STATUS    RESTARTS   AGE
details-v1-fd75f896d-ttkgw       2/2       Running   0          30s
productpage-v1-57f4d6b98-j4bxv   2/2       Running   0          28s
ratings-v1-6ff8679f7b-mgnzk      2/2       Running   0          30s
reviews-v1-5b66f78dc9-nts9j      2/2       Running   0          29s
reviews-v2-5d6d58488c-mk27n      2/2       Running   0          29s
reviews-v3-5469468cff-bdvjn      2/2       Running   0          29s
```

Federate the Istio `Gateway` and `VirtualService` resources:
```bash
$ kubefed2 federate --namespaced=true --group=networking.istio.io \
--version=v1alpha3 --kind=Gateway
$ kubefed2 federate --namespaced=true --group=networking.istio.io \
--version=v1alpha3 --kind=VirtualService
```

Create the Istio ingress gateway for the bookinfo application:
```bash
$ kubectl create -f istio/$ISTIO_VERSION/samples/bookinfo/bookinfo-gateway.yaml
```

You can verify the status of the Istio `Gateway` and `VirtualService resources with:
```bash
$ for i in 1 2; do kubectl get gateways --context cluster$i; done
NAME               AGE
bookinfo-gateway   17s

$ for i in 1 2; do kubectl get virtualservices --context cluster$i; done
NAME       AGE
bookinfo   26s
```

Follow the official Istio
[bookinfo documentation](https://archive.istio.io/v0.8/docs/guides/bookinfo/#determining-the-ingress-ip-and-port) for
determining the Ingress IP address and port for testing.

## Federated DNS

Follow the steps in the Federated DNS
[Multi-Cluster Service DNS with ExternalDNS Guide](https://github.com/danehans/federation-v2/blob/svc_dns_docs/docs/servicedns-with-externaldns.md)
to deploy external-dns.

Create the bookinfo `MultiClusterServiceDNSRecord`.
```bash
$ kubectl create -f istio/v0.8.0/samples/bookinfo/bookinfo-dns.yaml
```

Verify the resource records have been propagated to your DNS provider. This example uses
[Google Cloud DNS](https://cloud.google.com/dns/).
```bash
$ gcloud dns record-sets list --zone "example"
NAME                                                                                               TYPE  TTL    DATA
example.com.                                                                                       NS    21600  ns-cloud-c1.googledomains.com.,ns-cloud-c2.googledomains.com.,ns-cloud-c3.googledomains.com.,ns-cloud-c4.googledomains.com.
example.com.                                                                                       SOA   21600  ns-cloud-c1.googledomains.com. cloud-dns-hostmaster.google.com. 1 21600 3600 259200 300
cnameistio-ingressgateway.istio-system.federation-system.svc.asia-east1-a.asia-east1.example.com.  TXT   300    "heritage=external-dns,external-dns/owner=your_id"
istio-ingressgateway.istio-system.federation-system.svc.asia-east1-a.asia-east1.example.com.       A     300    $CLUSTER2_ISTIO_INGRESSGATEWAY
cnameistio-ingressgateway.istio-system.federation-system.svc.asia-east1.example.com.               TXT   300    "heritage=external-dns,external-dns/owner=your_id"
istio-ingressgateway.istio-system.federation-system.svc.asia-east1.example.com.                    A     300    $CLUSTER2_ISTIO_INGRESSGATEWAY
cnameistio-ingressgateway.istio-system.federation-system.svc.example.com.                          TXT   300    "heritage=external-dns,external-dns/owner=your_id"
istio-ingressgateway.istio-system.federation-system.svc.example.com.                               A     300    $CLUSTER2_ISTIO_INGRESSGATEWAY,$CLUSTER1_ISTIO_INGRESSGATEWAY
cnameistio-ingressgateway.istio-system.federation-system.svc.us-west1.example.com.                 TXT   300    "heritage=external-dns,external-dns/owner=your_id"
istio-ingressgateway.istio-system.federation-system.svc.us-west1.example.com.                      A     300    $CLUSTER1_ISTIO_INGRESSGATEWAY
cnameistio-ingressgateway.istio-system.federation-system.svc.us-west1-b.us-west1.example.com.      TXT   300    "heritage=external-dns,external-dns/owner=your_id"
istio-ingressgateway.istio-system.federation-system.svc.us-west1-b.us-west1.example.com.           A     300    $CLUSTER1_ISTIO_INGRESSGATEWAY
```

`istio-ingressgateway.istio-system.federation-system.svc.example.com.` represents the vanity domain name that is backed
by the productpage virtual service running in `cluster1` and `cluster2`. Verify name resolution of the vanity domain
name using `dig`.
```bash
$ dig +short @ns-cloud-c1.googledomains.com. istio-ingressgateway.istio-system.federation-system.svc.example.com.
$CLUSTER1_ISTIO_INGRESSGATEWAY
$CLUSTER2_ISTIO_INGRESSGATEWAY
```

It takes time for the resource records to be propagated to non-authoritative name servers. You should be able to
immediately test access using `curl` if you set your client's name servers to one of the above
(i.e. ns-cloud-c1.googledomains.com) and expect a `200` http response code.
```bash
$ export GATEWAY_URL=istio-ingressgateway.istio-system.federation-system.svc.example.com
$ curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage
200
```
You can also test access to domain names of the individual productpage virtual services using the name of the other `A` records.
```bash
$ export GATEWAY_URL=istio-ingressgateway.istio-system.federation-system.svc.us-west1.example.com
$ curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage
200
```

## Federated Istio Traffic Management
Federation-v2 provides consistency of Istio policies, security, traffic management, etc.. across multiple Istio meshes.
Reference the official Istio [Traffic Management](https://archive.istio.io/v0.8/docs/tasks/traffic-management/)
documentation for additional details. The following provides an example of federating Istio route rules across
`cluster1` and `cluster2`.

Federate the Istio `DestinationRule` resource:
```bash
$ kubefed2 federate --namespaced=true --group=networking.istio.io --version=v1alpha3 --kind=DestinationRule
```
__Note__: The Istio `VirtualService` resource required for route rules did not get federated in the above example since
it was accomplished in the Bookinfo Deployment section of this document.

Create the Istio destination rules for the bookinfo services to use only `v1`:
```bash
$ kubectl create -f istio/$ISTIO_VERSION/samples/bookinfo/routing/route-rule-all-v1.yaml
```

Verify route rule resource propagation to `cluster1`.
```bash
$ kubectl get destinationrules --context cluster1 -o yaml
$ kubectl get destinationrules --context cluster2 -o yaml
```

Confirm v1 is the active version of the reviews service by opening `http://$GATEWAY_URL/productpage` in your browser.
You should see the Bookinfo application productpage displayed. Notice that the productpage is displayed with no rating
stars since reviews:v1 does not access the ratings service.

## Management Scenarios

It's time to upgrade the bookinfo application in `cluster2`. Update the Istio ingress gateway
`FederatedServicePlacement` resource of the bookinfo `FederatedService` resource only exists in `cluster1`.
```bash
$ kubectl patch -n istio-system federatedserviceplacement/istio-ingressgateway \
--type=merge -p '{"spec":{"clusterNames":["cluster1"]}}'
```

The zone should no longer container `A` records for the $CLUSTER2_ISTIO_INGRESSGATEWAY. __Note__: It may take a few
minutes for the external-dns controller to update the zone records.
```bash
$ gcloud dns record-sets list --zone "example"
NAME                                                                                               TYPE  TTL    DATA
example.com.                                                                                       NS    21600  ns-cloud-c1.googledomains.com.,ns-cloud-c2.googledomains.com.,ns-cloud-c3.googledomains.com.,ns-cloud-c4.googledomains.com.
example.com.                                                                                       SOA   21600  ns-cloud-c1.googledomains.com. cloud-dns-hostmaster.google.com. 1 21600 3600 259200 300
cnameistio-ingressgateway.istio-system.federation-system.svc.asia-east1-a.asia-east1.example.com.  TXT   300    "heritage=external-dns,external-dns/owner=your_id"
istio-ingressgateway.istio-system.federation-system.svc.asia-east1-a.asia-east1.example.com.       A     300    130.211.253.102
cnameistio-ingressgateway.istio-system.federation-system.svc.asia-east1.example.com.               TXT   300    "heritage=external-dns,external-dns/owner=your_id"
istio-ingressgateway.istio-system.federation-system.svc.asia-east1.example.com.                    A     300    130.211.253.102
cnameistio-ingressgateway.istio-system.federation-system.svc.example.com.                          TXT   300    "heritage=external-dns,external-dns/owner=your_id"
istio-ingressgateway.istio-system.federation-system.svc.example.com.                               A     300    130.211.253.102,35.233.207.14
cnameistio-ingressgateway.istio-system.federation-system.svc.us-west1.example.com.                 TXT   300    "heritage=external-dns,external-dns/owner=your_id"
istio-ingressgateway.istio-system.federation-system.svc.us-west1.example.com.                      A     300    35.233.207.14
cnameistio-ingressgateway.istio-system.federation-system.svc.us-west1-b.us-west1.example.com.      TXT   300    "heritage=external-dns,external-dns/owner=your_id"
istio-ingressgateway.istio-system.federation-system.svc.us-west1-b.us-west1.example.com.           A     300    35.233.207.14
```

You should still be able to access the `istio-ingressgateway.istio-system.federation-system.svc.example.com.` vanity
domain even though the productpage virtual in `cluster2` has been taken deleted.
```bash
$ export GATEWAY_URL=istio-ingressgateway.istio-system.federation-system.svc.example.com
$ curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage
200
```

Upgrade the bookinfo application and patch `FederatedServicePlacement` so the productpage virtual service is created in
cluster2.
```bash
$ kubectl patch -n istio-system federatedserviceplacement/istio-ingressgateway \
--type=merge -p '{"spec":{"clusterNames":["cluster1","cluster2"]}}'
```

Repeat the verification steps from above. Then repeat the same process for the bookinfo virtual service in `cluster1`.

### Istio Hitless Upgrades

1. Update bookinfo placement resources to use only `cluster1` using `kubectl patch` command.
2. Update istio placement resources to use only `cluster1` using `kubectl patch` command. CRDs should be in both
clusters.
3. Federate the newer versions of Istio API types. `kubectl api-resources` is a good command:

```bash
$ kubefed2 federate --namespaced=true --group=config.istio.io --version=v1alpha2 --kind=attributemanifest
$ kubefed2 federate --namespaced=true --group=config.istio.io --version=v1alpha2 --kind=rule
```

Due to a pluralization [issue](https://github.com/kubernetes-sigs/federation-v2/pull/340#issuecomment-434524669).
Skip this resource for now
```bash
$ kubefed2 federate --namespaced=true --group=config.istio.io --version=v1alpha2 --kind=stdios
$ kubefed2 federate --namespaced=true --group=config.istio.io --version=v1alpha2 --kind=logentry
$ kubefed2 federate --namespaced=true --group=config.istio.io --version=v1alpha2 --kind=metric
$ kubefed2 federate --namespaced=true --group=config.istio.io --version=v1alpha2 --kind=prometheus
$ kubefed2 federate --namespaced=true --group=config.istio.io --version=v1alpha2 --kind=kubernetesenv
$ kubefed2 federate --namespaced=true --group=config.istio.io --version=v1alpha2 --kind=kubernetes
```

Create the Federated Istio resources:
```bash
$ kubectl create -f istio/v1.0.3/install/istio-types.yaml
```
__Note:__ `istio-types-issue.yaml` > `istio-types.yaml` after fixing pluralization
[issue](https://github.com/kubernetes-sigs/federation-v2/pull/340#issuecomment-434524669)

4. Deploy Istio v1.0.3 CRD's to `cluster2`:
```bash
$ kubectl create --validate=false -f istio/v1.0.3/install/crds_upgrade_from_v0.8.yaml
```
__Note:__ Disregard any `Error from server (AlreadyExists)` messages.
__Note:__ `crds_upgrade_from_v0.8.yaml` only contains new CRDs since v0.8 CRDs exist.

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
$ kubectl delete -R -f istio/$ISTIO_VERSION/install/
```

Uninstall the mutatingwebhookconfiguration for `cluster1` and cluster2`.
```bash
$ for i in 1 2; do kubectl delete -f istio/$ISTIO_VERSION/src/mutating-webhook-configuration.yaml \
  --context cluster$i; done
```

Uninstall the federation-v2 control-plane by changing to the federation-v2 project root directory and run:
```bash
cd $GOPATH/src/github.com/kubernetes-sigs/federation-v2
./scripts/delete-federation.sh
```

## References
- [Setting up ExternalDNS on Google Container Engine](https://github.com/kubernetes-incubator/external-dns/blob/master/docs/tutorials/gke.md)
