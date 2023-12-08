#!/bin/bash

CLUSTER_NAME=eksa
KUBECONFIG=$(find ~/DevOps/$CLUSTER_NAME -name '*-cluster.kubeconfig')

## Check Cluster Status
kubectl get pod -A -l control-plane=controller-manager
kubectl get kubeadmcontrolplanes.controlplane.cluster.x-k8s.io -n eksa-system
kubectl get clusters.cluster.x-k8s.io -A -o=custom-columns=NAME:.metadata.name,CONTROLPLANE-READY:.status.controlPlaneReady,INFRASTRUCTURE-READY:.status.infrastructureReady,MANAGED-EXTERNAL-ETCD-INITIALIZED:.status.managedExternalEtcdInitialized,MANAGED-EXTERNAL-ETCD-READY:.status.managedExternalEtcdReady


## Enable Metrics Server

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl get deployment metrics-server -n kube-system
