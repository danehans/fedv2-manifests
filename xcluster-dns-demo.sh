#!/usr/bin/env bash
#
# TO run demo: $ ./mcdns-demo.sh  cluster1  cluster1  cluster2

C1=cluster1
C2=cluster2

kubectl config use-context $C1

kubectl apply -f ./multicluster-dns/examples/fs1.yaml

kubectl --context=${C1} get pods
while [ "2" != "$(kubectl --context=${C1} get rs fr1 -o jsonpath="{.status.availableReplicas}")" ]; do
    sleep 3;
done
kubectl --context=${C1} get ep

kubectl --context=${C2} get pods
while [ "2" != "$(kubectl --context=${C2} get rs fr1 -o jsonpath="{.status.availableReplicas}")" ]; do
    sleep 3;
done
kubectl --context=${C2} get ep

kubectl run dnstools --rm --restart=Never -i --image=infoblox/dnstools --command -- curl -s fs1.default.prod

kubectl patch federatedreplicasetplacements fr1 --type merge -p '{\"spec\":{\"clusterNames\":[\"${C2}\"]}}'

kubectl run dnstools --rm --restart=Never -i --image=infoblox/dnstools --command -- curl -s fs1.default.prod
