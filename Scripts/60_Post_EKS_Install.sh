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
# Note this gets kind of "cludgy" as I need to get the activation* which is only available as output when the cluster is registered (from what I can tell)

AmazonEKSConnectorAgentRoleARN=$(aws iam get-role --role-name AmazonEKSConnectorAgentRole  --query Role.Arn --output text)
EKSA_Cluster_Name=$(kubectl config view --minify -o jsonpath='{.clusters[].name}')
MY_AWS_REGION=us-east-2

CLUSTER_REGISTRATION_OUTPUT=${EKSA_Cluster_Name}-ClusterRegistrationOutput 
aws eks register-cluster \ 
     --name $EKSA_Cluster_Name \
     --connector-config roleArn=$AmazonEKSConnectorAgentRoleARN,provider="OTHER" \
     --region $MY_AWS_REGION | tee $CLUSTER_REGISTRATION_OUTPUT
EKSA_ACTIVATION_ID=$(cat $CLUSTER_REGISTRATION_OUTPUT | jq -r '.[].connectorConfig.activationId')
EKSA_ACTIVATION_CODE=$(cat $CLUSTER_REGISTRATION_OUTPUT | jq -r '.[].connectorConfig.activationCode')

echo "EKSA_ACTIVATION_ID: $EKSA_ACTIVATION_ID"
echo "EKSA_ACTIVATION_CODE: $EKSA_ACTIVATION_CODE"
aws eks describe-cluster --name kubernerdes-eksa 

kubectl create namespace eks-connector
helm install eks-connector \
  --namespace eks-connector \
  oci://public.ecr.aws/eks-connector/eks-connector-chart \
  --set eks.activationCode=${EKSA_ACTIVATION_CODE} \
  --set eks.activationId=${EKSA_ACTIVATION_ID} \
  --set eks.agentRegion=$EKSA_AWS_REGION

# Switch context to eks-connector namespace
kubectl config set-context --current --namespace=eks-connector
kubectl get events 
echo "Watch the pods until they are Running"
while sleep 1; do kubectl get pods -n eks-connector | grep Running && break; done

# Switch context back to default namespace
kubectl config set-context --current --namespace=default

exit 0

## CLEANUP
# Run the following without the "#"
# helm delete eks-connector
