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
          - 10.220.0.93/32
          - 10.10.13.1-10.10.13.255
    L2Advertisements:
      - ipAddressPools:
        - default  
EOF1
kubectl create namespace metallb-system
eksctl anywhere create packages -f metallb-config.yaml
eksctl anywhere get packages --cluster $CLUSTER_NAME
exit 0
