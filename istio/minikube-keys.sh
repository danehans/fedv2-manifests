#!/usr/bin/env bash
#
# Run after minikube is complete on dev/dev2 gce vm's

echo "## SCP'ing certs/key from dev2 vm"
for i in ca.crt client.crt client.key; do gcloud compute scp root@dev2:/root/.minikube/$i .; done

echo "## SCP'ing certs/key to dev vm"
for i in ca.crt client.crt client.key; do gcloud compute scp $i root@dev:/root/.minikube/cluster2/; done

echo "## Removing certs/key from local machine"
for i in ca.crt client.crt client.key; do rm -rf $i; done

echo "## Minikube certs/key setup complete!"
