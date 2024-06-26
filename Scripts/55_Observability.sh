#!/bin/bash

#     Purpose: To install Prometheus/Grafana
#        Date: 2024-04-24
#      Status: Work-In-Progress - converting to OSS
# Assumptions:
#        Todo: Update this procedure to use OSS versions of Prometheus and Grafana.  (Create helm charts?)

# https://github.com/prometheus-operator/prometheus-operator

# https://github.com/prometheus-operator/kube-prometheus


# Create the namespace and CRDs, and then wait for them to be available before creating the remaining resources
# Note that due to some CRD size we are using kubectl server-side apply feature which is generally available since kubernetes 1.22.
# If you are using previous kubernetes versions this feature may not be available and you would need to use kubectl create instead.

git clone https://github.com/prometheus-operator/kube-prometheus.git
cd kube-prometheus/
#
kubectl apply --server-side -f manifests/setup
kubectl wait \
	--for condition=Established \
	--all CustomResourceDefinition \
	--namespace=monitoring
kubectl apply -f manifests/
while sleep 2; do kubectl get all -n monitoring | egrep 'ContainerCreating|Init' || break; done





kubectl config set-context --current --namespace=default
kubectl create -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/master/bundle.yaml
kubectl get deploy -n default
mkdir operator_k8s
cd operator_k8s

cat << EOF1 | tee prom_rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroups: [""]
  resources:
  - nodes
  - nodes/metrics
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources:
  - configmaps
  verbs: ["get"]
- apiGroups:
  - networking.k8s.io
  resources:
  - ingresses
  verbs: ["get", "list", "watch"]
- nonResourceURLs: ["/metrics"]
  verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: default
EOF1
kubectl apply -f prom_rbac.yaml



clean_up() {
for n in $(kubectl get namespaces -o jsonpath={..metadata.name}); do
  kubectl delete --all --namespace=$n prometheus,servicemonitor,podmonitor,alertmanager
done
kubectl delete -f bundle.yaml
for n in $(kubectl get namespaces -o jsonpath={..metadata.name}); do
  kubectl delete --ignore-not-found --namespace=$n service prometheus-operated alertmanager-operated
done

kubectl delete --ignore-not-found customresourcedefinitions \
  prometheuses.monitoring.coreos.com \
  servicemonitors.monitoring.coreos.com \
  podmonitors.monitoring.coreos.com \
  alertmanagers.monitoring.coreos.com \
  prometheusrules.monitoring.coreos.com













NAMESPACE=monitoring
cat << EOF3 | tee ${NAMESPACE}-ns.yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
EOF3
kubectl create -f ${NAMESPACE}-ns.yaml

helm install prometheus prometheus-community/kube-prometheus-stack --namespace $NAMESPACE 

## ConfigMap
cat << EOF5 | tee $NAMESPACE-configmap.yaml
---
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: $NAMESPACE 
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      scrape_timeout: 10s
      evaluation_interval: 15s
    scrape_configs:
      - job_name: '${NAMESPACE}-service'
        scrape_interval: 5s
        static_configs:
          - targets: ['${NAMESPACE}-service:8080']
EOF5

## Service
cat << EOF6 | tee ${NAMESPACE}-service.yaml
---

EOF6

exit 0

##########
##########
### THE FOLLOWING IS FOR CURATED PACKAGES
### I have reverted to using OSS - this is here in case I need a reference.
##########
##########

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

NAMESPACE=monitoring
cat << EOF3 | tee ${NAMESPACE}-ns.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
EOF3
kubectl create -f ${NAMESPACE}-ns.yaml

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
