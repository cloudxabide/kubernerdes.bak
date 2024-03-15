#!/bin/bash

# NOTE THIS FILE SHOULD BE RENAMED

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
while sleep 2; do echo "Waiting for pods..."; kubectl get pods | egrep '0/1' || break; done

kubectl get events -n observability --sort-by=.lastTimestamp

kubectl config set-context --current --namespace=default

export PROM_SERVER_POD_NAME=$(kubectl get pods --namespace observability -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name"})
kubectl port-forward $PROM_SERVER_POD_NAME -n observability 9090

## Grafana
### NOTE:  I would like to update this to install in it's own namespace and not "default"
###        Also - to make it persistent
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install my-grafana grafana/grafana

   kubectl get secret --namespace default my-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
   export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=my-grafana" -o jsonpath="{.items[0].metadata.name}")
   kubectl --namespace default port-forward $POD_NAME 3000



## Troubeshooting
kubectl set image statefulset.apps/generated-prometheus-server  *=783794618700.dkr.ecr.us-west-2.amazonaws.com/prometheus/prometheus:latest
