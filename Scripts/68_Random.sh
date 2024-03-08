#!/bin/bash

# Curated Packages 

kubectl get pods -n eksa-packages | grep "eks-anywhere-packages"

aws ecr get-login-password --region $EKSA_AWS_REGION | docker login --username AWS --password-stdin 783794618700.dkr.ecr.us-west-2.amazonaws.com
docker pull 783794618700.dkr.ecr.us-west-2.amazonaws.com/emissary-ingress/emissary:v3.5.1-bf70150bcdfe3a5383ec8ad9cd7eea801a0cb074

kubectl get secret -n eksa-packages aws-secret -o jsonpath='{.data.AWS_ACCESS_KEY_ID}'  | base64 --decode
kubectl get secret -n eksa-packages aws-secret -o jsonpath='{.data.AWS_SECRET_ACCESS_KEY}'  | base64 --decode
kubectl get secret -n eksa-packages aws-secret -o jsonpath='{.data.REGION}'  | base64 --decode

eksctl anywhere list packages --kube-version $(kubectl version -o json | jq -rj '.serverVersion|.major,".",.minor')
kubectl describe packagebundlecontroller -n eksa-packages
kubectl get packagebundles -n eksa-packages

update_package_credentials() {
kubectl delete secret -n eksa-packages aws-secret
kubectl create secret -n eksa-packages generic aws-secret \
  --from-literal=AWS_ACCESS_KEY_ID=${EKSA_AWS_ACCESS_KEY_ID} \
  --from-literal=AWS_SECRET_ACCESS_KEY=${EKSA_AWS_SECRET_ACCESS_KEY}  \
  --from-literal=REGION=${EKSA_AWS_REGION}
}

## Harbor 
eksctl anywhere generate package harbor --cluster ${CLUSTER_NAME} --kube-version  $(kubectl version -o json | jq -rj '.serverVersion|.major,".",.minor') > harbor-spec.yaml

## Enable Cert-Manager
eksctl anywhere generate package cert-manager --cluster ${CLUSTER_NAME} > cert-manager.yaml

## Enable Metrics Server (using curated pacakges)
eksctl anywhere generate package metrics-server --cluster $CLUSTER_NAME > metrics-server.yaml

eksctl anywhere create packages -f metrics-server.yaml

## Enable Metrics Server (This is the OSS method - need to do this using curated packages)
metrics_server_foss() {
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
# The metrics-server will NOT come up (until you update the certs - below)
kubectl get deployment metrics-server -n kube-system 
kubectl get events -n kube-system
### Disable TLS for my metrics on my cluster
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
while sleep 2; do kubectl get pods -n kube-system | grep ^metrics-server | grep "0/1" || break; done
}


eksctl anywhere generate package harbor --cluster $CLUSTER_NAME --kube-version $(kubectl version -o json | jq -rj '.serverVersion|.major,".",.minor') > harbor-spec.yaml

# Standard Prometheus creation process
# eksctl anywhere generate package prometheus --cluster $CLUSTER_NAME > prometheus.yaml
# eksctl anywhere create packages -f prometheus.yaml

# Rep2 statefulset prometheus
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
