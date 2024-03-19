#!/bin/bash

#     Purpose: Install/Configure Emissary
#        Date:
#      Status: Incomplete/In-Progress
# Assumptions:

# Status:  just started this

## Deploy Emissary
eksa-packages-emissary() {
mkdir ~/DevOps/eksa/latest/emissary; cd $_
eksctl anywhere generate package emissary --cluster $CLUSTER_NAME > generated-emissary.yaml
kubectl create namespace emissary-system
cat << EOF1 | tee emissary.yaml
---
apiVersion: packages.eks.amazonaws.com/v1alpha1
kind: Package
metadata:
  name: emissary
  namespace: eksa-packages-$CLUSTER_NAME
spec:
  packageName: emissary
EOF1

eksctl anywhere create packages -f emissary.yaml 
eksctl anywhere get packages --cluster $CLUSTER_NAME | grep emiss

# eksctl anywhere delete package emissary --cluster $CLUSTER_NAME
# eksctl anywhere delete package emissary-crds --cluster $CLUSTER_NAME
}

emissary_OSS() {

helm repo add datawire https://app.getambassador.io
helm repo update
 
# Create Namespace and Install:
kubectl create namespace emissary && \
kubectl apply -f https://app.getambassador.io/yaml/emissary/3.9.1/emissary-crds.yaml
 
kubectl wait --timeout=90s --for=condition=available deployment emissary-apiext -n emissary-system
 
helm install emissary-ingress --namespace emissary datawire/emissary-ingress && \
kubectl -n emissary wait --for condition=available --timeout=90s deploy -lapp.kubernetes.io/instance=emissary-ingress

kubectl get svc -w  --namespace emissary emissary-ingress

# https://www.getambassador.io/docs/emissary/latest/topics/running/host-crd
cat << EOF1 | tee wildcard-apps-domain.yaml
---
apiVersion: getambassador.io/v3alpha1
kind: Host
metadata:
  name: wildcard-apps-domain
spec:
  hostname: *.apps.kubernerdes.lab
EOF1

# Create the Listener
cat << EOF1 | tee emissary-listener.yaml
---
apiVersion: getambassador.io/v3alpha1
kind: Listener
metadata:
  name: emissary-ingress-listener-8080
  namespace: emissary
spec:
  port: 8080
  protocol: HTTP
  securityModel: XFP
  hostBinding:
    namespace:
      from: ALL
EOF1
kubectl apply -f emissary-listener.yaml

cat << EOF1 | tee wildcard-apps-domain.yaml
---
apiVersion: getambassador.io/v3alpha1
kind: Host
metadata:
  name: wildcard-apps-domain
spec:
  hostname: *.apps.kubernerdes.lab
EOF1
kubectl apply -f wildcard-apps-domain.yaml
}
