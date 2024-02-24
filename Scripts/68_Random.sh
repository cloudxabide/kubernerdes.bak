#!/bin/bash

## 
# make sure package controller is present
kubectl get pods -n eksa-packages | grep "eks-anywhere-packages"
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 783794618700.dkr.ecr.us-west-2.amazonaws.com

## Curated Packages List (work in progress)
eksctl anywhere list packages --kube-version $(kubectl version -o json | jq -rj '.serverVersion|.major,".",.minor')

## Enable Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl get deployment metrics-server -n kube-system
kubectl get events -n kube-system

### Disable TLS for my metrics on my cluster
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
while sleep 2; do kubectl get pods -n kube-system | grep ^metrics-server | grep "0/1" || break; done

## Enable Prometheus
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 783794618700.dkr.ecr.us-west-2.amazonaws.com
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 297090588151.dkr.ecr.us-west-2.amazonaws.com

kubectl delete secret -n eksa-packages aws-secret
echo "kubectl create secret -n eksa-packages generic aws-secret \
  --from-literal=AWS_ACCESS_KEY_ID=${EKSA_AWS_ACCESS_KEY_ID} \
  --from-literal=AWS_SECRET_ACCESS_KEY=${EKSA_AWS_SECRET_ACCESS_KEY}  \
  --from-literal=REGION=${EKSA_AWS_REGION}"

kubectl create secret -n eksa-packages generic aws-secret \
  --from-literal=AWS_ACCESS_KEY_ID=${EKSA_AWS_ACCESS_KEY_ID} \
  --from-literal=AWS_SECRET_ACCESS_KEY=${EKSA_AWS_SECRET_ACCESS_KEY}  \
  --from-literal=REGION=${EKSA_AWS_REGION}

eksctl anywhere generate package harbor --cluster $CLUSTER_NAME --kube-version $(kubectl version -o json | jq -rj '.serverVersion|.major,".",.minor') > harbor-spec.yaml

eksctl anywhere generate package prometheus --cluster $CLUSTER_NAME > prometheus.yaml

# eksctl anywhere create packages -f prometheus.yaml
cat << EOF1 | tee  prometheus-rep2-statefuleset.yaml
---
 apiVersion: packages.eks.amazonaws.com/v1alpha1
 kind: Package
 metadata:
   name: generated-prometheus
   namespace: eksa-packages-${CLUSTER_NAME}
 spec:
   packageName: prometheus
   targetNamespace: observability
   config: |
     server:
       replicaCount: 2
       statefulSet:
         enabled: true
     serverFiles:
       prometheus.yml:
         scrape_configs:
           - job_name: prometheus
             static_configs:
               - targets:
                 - localhost:9090     
EOF1
kubectl create namespace observability
kubectl config set-context --current --namespace=observability
eksctl anywhere create packages -f prometheus-rep2-statefuleset.yaml
eksctl anywhere get packages --cluster $CLUSTER_NAME

kubectl config set-context --current --namespace=default

export PROM_SERVER_POD_NAME=$(kubectl get pods --namespace observability -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name")
kubectl port-forward $PROM_SERVER_POD_NAME -n observability 9090

## ADOT
eksctl anywhere generate package adot --cluster $( kubectl config view --minify -o jsonpath='{.clusters[].name}') > adot.yaml
