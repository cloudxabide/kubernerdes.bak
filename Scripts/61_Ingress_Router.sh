#!/bin/bash

#     Purpose:
#        Date:
#      Status: Incomplete/In-Progress
# Assumptions:

# Status:  just started this
mkdir ~/DevOps/eksa/latest/metallb; cd $_

kubectl apply -f "https://anywhere.eks.amazonaws.com/manifests/hello-eks-a.yaml"

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
eksctl anywhere get packages --cluster $CLUSTER_NAME

kubectl create namespace hello-world
kubectl apply -f "https://raw.githubusercontent.com/cloudxabide/kubernerdes/main/Files/hello-world/hello-world-eks-a-with-lb.yaml" -n hello-world
sleep 2
kubectl get pods -l app=hello-eks-a -n hello-world
kubectl logs -l app=hello-eks-a
kubectl get all -n hello-world
kubectl delete ns hello-world

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

exit dd the Repo:
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
cat << EOF1 | tee hello-world.yaml
---
apiVersion: getambassador.io/v3alpha1
kind: Host
metadata:
  name: hello-world
spec:
  hostname: *.apps.kubernerdes.lab
EOF1


}
