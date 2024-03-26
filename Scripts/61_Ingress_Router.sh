#!/bin/bash

#     Purpose:
#        Date:
#      Status: Incomplete/In-Progress
# Assumptions:
# Status:  just started this

mkdir ~/eksa/$CLUSTER_NAME/latest/metallb; cd $_

eksctl anywhere generate package metallb --cluster $CLUSTER_NAME > metallb-generated.yaml

cat << EOF1 | tee metallb-config.yaml
---
apiVersion: packages.eks.amazonaws.com/v1alpha1
kind: Package
metadata:
  creationTimestamp: null
  name: generated-metallb-custom
  namespace: eksa-packages-kubernerdes-eksa
spec:
  packageName: metallb
  config: |
    IPAddressPools:
      - name: default
        addresses:
          - 10.10.13.1-10.10.13.255
    L2Advertisements:
      - ipAddressPools:
        - default  
EOF1
kubectl create namespace metallb-system
eksctl anywhere create packages -f metallb-config.yaml
while sleep 5; do echo "Checking every 5 seconds for success...."; eksctl anywhere get packages --cluster $CLUSTER_NAME | grep installing || break; done

kubectl create namespace hello-world
kubectl apply -f "https://raw.githubusercontent.com/cloudxabide/kubernerdes/main/Files/hello-world/hello-world-eks-a-with-lb.yaml" -n hello-world
sleep 2
kubectl get pods -l app=hello-eks-a -n hello-world
kubectl logs -l app=hello-eks-a -n hello-world
kubectl get all -n hello-world
kubectl delete ns hello-world

## Deploy Emissary (this seems to be broken at the moment (use the OSS version)
eksa-packages-emissary() {
mkdir ~/eksa/${CLUSTER_NAME}/latest/emissary; cd $_
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
while sleep 5; do echo "Checking every 5 seconds for success...."; eksctl anywhere get packages --cluster $CLUSTER_NAME | grep installing || break; done

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

kubectl get svc  --namespace emissary emissary-ingress

# https://www.getambassador.io/docs/emissary/latest/topics/running/host-crd

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
