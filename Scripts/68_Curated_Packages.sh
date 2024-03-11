#!/bin/bash

# Curated Packages 

kubectl get pods -n eksa-packages | grep "eks-anywhere-packages"
kubectl get events -n eksa-packages --sort-by=.lastTimestamp

aws ecr get-login-password --region $EKSA_AWS_REGION | docker login --username AWS --password-stdin 783794618700.dkr.ecr.us-west-2.amazonaws.com
docker pull 783794618700.dkr.ecr.us-west-2.amazonaws.com/emissary-ingress/emissary:v3.5.1-bf70150bcdfe3a5383ec8ad9cd7eea801a0cb074

kubectl get secret -n eksa-packages aws-secret -o jsonpath='{.data.AWS_ACCESS_KEY_ID}'  | base64 --decode; echo
kubectl get secret -n eksa-packages aws-secret -o jsonpath='{.data.AWS_SECRET_ACCESS_KEY}'  | base64 --decode; echo
kubectl get secret -n eksa-packages aws-secret -o jsonpath='{.data.REGION}'  | base64 --decode ; echo

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
# (remove comment to run - should already be present) eksctl anywhere generate package cert-manager --cluster ${CLUSTER_NAME} > cert-manager.yaml

## Enable Metrics Server (using curated pacakges)
#eksctl anywhere generate package metrics-server --cluster $CLUSTER_NAME > metrics-server.yaml
cat << EOF1 | tee metrics-server.yaml
apiVersion: packages.eks.amazonaws.com/v1alpha1
kind: Package
metadata:
  creationTimestamp: null
  name: generated-metrics-server
  namespace: eksa-packages-kubernerdes-eksa
spec:
  packageName: metrics-server
  targetNamespace: kube-system
  config: |-
    args:
      - "--kubelet-insecure-tls"

---

EOF1
eksctl anywhere create packages -f metrics-server.yaml
kubectl get all -n kube-system 
kubectl get events -n kube-system 

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

## ADOT
eksctl anywhere generate package adot --cluster $( kubectl config view --minify -o jsonpath='{.clusters[].name}') > adot.yaml

exit 0
# EKS-A Packages
You can browse the Public ECR repo here
https://gallery.ecr.aws/eks-anywhere/eks-anywhere-packages
https://public.ecr.aws/eks-anywhere/eks-anywhere-packages:v0.0.0-e69e0b978465571a9f462524b9dc3d2e31f0aae0


# Troubleshooting on 2024-03-8
kubectl set image daemonset ecr-credential-provider-package *=public.ecr.aws/eks-anywhere/credential-provider-package:v0.3.13-828e7d186ded23e54f6bd95a5ce1319150f7e325

# https://jamesdefabia.github.io/docs/user-guide/kubectl/kubectl_patch/
kubectl patch ds -n eksa-packages --type='json' -p='[{"op": "update", "path": "/spec/template/spec/containers/image", "value": {"public.ecr.aws/eks-anywhere/credential-provider-package:v0.3.13-828e7d186ded23e54f6bd95a5ce1319150f7e325"}]'
public.ecr.aws/eks-anywhere/credential-provider-package:v0.3.13-828e7d186ded23e54f6bd95a5ce1319150f7e325
