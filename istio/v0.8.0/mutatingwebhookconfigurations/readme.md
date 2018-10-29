Since the sidecar-injector pod patches the client `caBundle` of the `MutatingWebhookConfiguration` resource with the
sidecar-injector secret data, it can not be federated. When the resource gets patched, the `resourceVersion` field is
updated, causing a propagated version mismatch between the federated and target resources. When the fedv2 sync
controller sees the mismatch, it will re-propagate the `MutatingWebhookConfiguration` resource which contains the empty
`caBundle`. For the time being, deploy the `MutatingWebhookConfiguration` resource to clusters individually:
```bash
$ kubectl create -f istio/$ISTIO_VERSION/src/mutating-webhook-configuration.yaml --context cluster1
$ kubectl create -f istio/$ISTIO_VERSION/src/mutating-webhook-configuration.yaml --cont
```
