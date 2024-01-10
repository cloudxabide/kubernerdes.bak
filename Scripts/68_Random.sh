#!/bin/bash




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
# NEED TO TEST THIS - IT *SHOULD* REPEAT UNTIL NO "0/1" IS FOUND
while sleep 1; do kubectl get pods -n kube-system | grep ^metrics-server | grep "0/1" || break; done


# Curated Packages List (work in progress)
eksctl anywhere list packages --kube-version $(kubectl version -o json | jq -rj '.serverVersion|.major,".",.minor')

# ADOT
eksctl anywhere generate package adot --cluster $( kubectl config view --minify -o jsonpath='{.clusters[].name}') > adot.yaml
