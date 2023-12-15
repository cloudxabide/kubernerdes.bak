#!/bin/bash

## Install Helm
sudo snap install  helm --classic
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh

#############################3
## Add NFS Storage Class (DON'T USE - HERE AS AN EXAMPLE)
# https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/blob/master/charts/nfs-subdir-external-provisioner/README.md
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=10.10.12.10 \
    --set nfs.path=/mnt/nfs_shares/eksa
kubectl rollout status deployment/nfs-subdir-external-provisioner

## Linux Command
showmount -e 10.10.12.10
### CleanUp
#  helm delete nfs-subdir-external-provisioner

kubectl rollout restart deployment.apps/nfs-subdir-external-provisioner
#############################3

## Check Cluster Status
kubectl get pod -A -l control-plane=controller-manager
kubectl get kubeadmcontrolplanes.controlplane.cluster.x-k8s.io -n eksa-system
kubectl get clusters.cluster.x-k8s.io -A -o=custom-columns=NAME:.metadata.name,CONTROLPLANE-READY:.status.controlPlaneReady,INFRASTRUCTURE-READY:.status.infrastructureReady,MANAGED-EXTERNAL-ETCD-INITIALIZED:.status.managedExternalEtcdInitialized,MANAGED-EXTERNAL-ETCD-READY:.status.managedExternalEtcdReady

## Deploy test workload
kubectl apply -f "https://anywhere.eks.amazonaws.com/manifests/hello-eks-a.yaml"
kubectl get pods -l app=hello-eks-a
sleep 5
kubectl logs -l app=hello-eks-a

## Enable Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl get deployment metrics-server -n kube-system
kubectl get events -w -n kube-system
# Disable TLS for my metrics on my cluster
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

