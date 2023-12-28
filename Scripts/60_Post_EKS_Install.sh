#!/bin/bash

#     Purpose:
#        Date:
#      Status: Incomplete - probably move this to ~/Foo
# Assumptions:

#############################
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
kubectl get events -n kube-system
# Disable TLS for my metrics on my cluster
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Curated Packages List (work in progress)
eksctl anywhere list packages --kube-version $(kubectl version -o json | jq -rj '.serverVersion|.major,".",.minor')

# ADOT
eksctl anywhere generate package adot --cluster $( kubectl config view --minify -o jsonpath='{.clusters[].name}') > adot.yaml
