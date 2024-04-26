#!/bin/bash

#     Purpose: To install Prometheus/Grafana
#        Date: 2024-04-24
#      Status: Unknown - believed to be GTG
# Assumptions:
#        Todo:

# Standard Prometheus creation process
# eksctl anywhere generate package prometheus --cluster $CLUSTER_NAME > prometheus.yaml
# eksctl anywhere create packages -f prometheus.yaml

### CHOOSE ONE OF THE FOLLOWING IMPLEMENTATION PATTERNS
### I PUT THE "SIMPLE" PATTERN LAST (BECAUSE IT WORKS) - that way, if this is run non-interactively
###   the working method will be utilized
# Rep2 statefulset prometheus (currently not producing output (2024-03-16))
PROMETHEUS_PACKAGE_CONFIG=prometheus-rep2-statefuleset.yaml
cat << EOF1 | tee $PROMETHEUS_PACKAGE_CONFIG
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
     global:
       evaluation_interval: "30s"
       scrape_interval: "30s"
       scrape_timeout: "15s"  
     serverFiles:
       prometheus.yml:
         scrape_configs:
           - job_name: prometheus
             static_configs:
               - targets:
                 - localhost:9090

EOF1

# Simple Prometheus with modified scrape intervals
PROMETHEUS_PACKAGE_CONFIG=prometheus.yaml
cat << EOF1 | tee $PROMETHEUS_PACKAGE_CONFIG
apiVersion: packages.eks.amazonaws.com/v1alpha1
kind: Package
metadata:
  name: generated-prometheus
  namespace: eksa-packages-${CLUSTER_NAME}
spec:
  packageName: prometheus
  config: |
    server:
      global:
        evaluation_interval: "30s"
        scrape_interval: "30s"
        scrape_timeout: "15s"
EOF1

### PROCEED
kubectl create namespace observability
kubectl config set-context --current --namespace=observability
eksctl anywhere create packages -f $PROMETHEUS_PACKAGE_CONFIG
eksctl anywhere get packages --cluster $CLUSTER_NAME
echo "NOTE:  It may take a few minutes to get Prometheus up and running - be patient."
while sleep 2; do echo "Waiting for pods..."; kubectl get pods | egrep '0/1' || break; done

kubectl get events -n observability --sort-by=.lastTimestamp
echo "URL: (to add to Grafan)  http://generated-prometheus-server.observability:9090"

kubectl config set-context --current --namespace=default

## Grafana
### NOTE:  I would like to update this to install in it's own namespace and not "default"
###        Also - to make it persistent
GRAFANA_NAMESPACE=monitoring
kubectl create namespace $GRAFANA_NAMESPACE 
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install my-grafana grafana/grafana --namespace  $GRAFANA_NAMESPACE
kubectl get secret --namespace $GRAFANA_NAMESPACE my-grafana -o jsonpath="{.data.admin-password}" | base64 --decode > $GRAFANA_NAMESPACE-secret.txt

DEFAULT_STORAGE_CLASS=$(kubectl get sc| grep "(default)" | awk '{ print $1 }')
cat << EOF1 | tee my-grafana-storage.yaml
---
persistence:
  type: pvc
  enabled: true
  storageClassName:  $DEFAULT_STORAGE_CLASS 
EOF1
helm upgrade my-grafana grafana/grafana -f my-grafana-storage.yaml -n $GRAFANA_NAMESPACE 

## Metrics Server
mkdir ~/eksa/$CLUSTER_NAME/latest/metrics-server/; cd $_
cat << EOF1 | tee metrics-server.yaml
apiVersion: packages.eks.amazonaws.com/v1alpha1
kind: Package
metadata:
  creationTimestamp: null
  name: generated-metrics-server
  namespace: eksa-packages-${CLUSTER_NAME}
spec:
  packageName: metrics-server
  targetNamespace: kube-system
  config: |-
    args:
      - "--kubelet-insecure-tls"

---

EOF1
eksctl anywhere create packages -f metrics-server.yaml
while sleep 2; do echo "Waiting for pods to deploy..."; kubectl get pods -n kube-system | egrep '0/1' || break; done
kubectl get all -n kube-system
kubectl get events -n kube-system

exit 0

## Enable UI  (to localhost)
export PROM_SERVER_POD_NAME=$(kubectl get pods --namespace observability -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name"})
kubectl port-forward $PROM_SERVER_POD_NAME -n observability 9090

export POD_NAME=$(kubectl get pods --namespace $GRAFANA_NAMESPACE -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=my-grafana" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace $GRAFANA_NAMESPACE port-forward $POD_NAME 3000
# Import Dashboard 315 and 1860 

## Troubeshooting
kubectl set image statefulset.apps/generated-prometheus-server  *=783794618700.dkr.ecr.us-west-2.amazonaws.com/prometheus/prometheus:latest

### Cleanup
eksctl anywhere delete packages generated-prometheus --cluster $CLUSTER_NAME
