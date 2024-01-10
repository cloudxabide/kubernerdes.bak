#!/bin/bash

#     Purpose:
#        Date:
#      Status: Incomplete - probably move this to ~/Foo
# Assumptions: Some sort of persistent storage exists (openEBS, in my case)

#############################
## Check Cluster Status
kubectl get pod -A -l control-plane=controller-manager
echo
kubectl get kubeadmcontrolplanes.controlplane.cluster.x-k8s.io -n eksa-system
echo
kubectl get clusters.cluster.x-k8s.io -A -o=custom-columns=NAME:.metadata.name,CONTROLPLANE-READY:.status.controlPlaneReady,INFRASTRUCTURE-READY:.status.infrastructureReady,MANAGED-EXTERNAL-ETCD-INITIALIZED:.status.managedExternalEtcdInitialized,MANAGED-EXTERNAL-ETCD-READY:.status.managedExternalEtcdReady
echo

## EKS Connector

AmazonEKSConnectorAgentRoleARN=$(aws iam get-role --role-name AmazonEKSConnectorAgentRole  --query Role.Arn --output text)
EKSA_Cluster_Name=$(kubectl config view --minify -o jsonpath='{.clusters[].name}')
MY_AWS_REGION=us-east-2

aws eks register-cluster \
     --name $EKSA_Cluster_Name \
     --connector-config roleArn=$AmazonEKSConnectorAgentRoleARN,provider="OTHER" \
     --region $MY_AWS_REGION

aws eks describe-cluster --name kubernerdes-eksa

kubectl create namespace eks-connector
helm install eks-connector \
  --namespace eks-connector \
  oci://public.ecr.aws/eks-connector/eks-connector-chart \
  --set eks.activationCode= \
  --set eks.activationId= \
  --set eks.agentRegion=us-east-2

Pulled: public.ecr.aws/eks-connector/eks-connector-chart:0.0.9
Digest: sha256:5a6d13f2e09215a89cd44b800813e35f61c11b67b0c1ae82b722b90d93e8c8f8
NAME: eks-connector
LAST DEPLOYED: Tue Jan  2 20:59:41 2024
NAMESPACE: eks-connector
STATUS: deployed
REVISION: 1
TEST SUITE: None

kubectl config set-context --current --namespace=eks-connector
kubectl get events -w

## CLEANUP
helm delete eks-connector
