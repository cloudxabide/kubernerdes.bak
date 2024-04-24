#!/bin/bash

#     Purpose: To show cluster status, then register to AWS EKS Service
#        Date: 2024-04-24
#      Status: Still seeems to have an issue when run non-interactive
#              Incomplete - needs more troubleshooting
# Assumptions: 


cd $HOME/eksa/$CLUSTER_NAME/latest/
aws sts get-caller-identity | grep eksa-curated-packages-user || { echo "ERROR: Wrong User"; exit 0; }

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

export AmazonEKSConnectorAgentRoleARN=$(aws iam get-role --role-name AmazonEKSConnectorAgentRole  --query Role.Arn --output text)
export EKSA_Cluster_Name=$(kubectl config view --minify -o jsonpath='{.clusters[].name}')
export MY_AWS_REGION=us-west-2

CLUSTER_REGISTRATION_OUTPUT=${EKSA_Cluster_Name}-ClusterRegistrationOutput 
aws eks register-cluster \ 
     --name $EKSA_Cluster_Name \
     --connector-config roleArn=$AmazonEKSConnectorAgentRoleARN,provider="OTHER" \
     --region $MY_AWS_REGION | tee $CLUSTER_REGISTRATION_OUTPUT
export EKSA_ACTIVATION_ID=$(cat $CLUSTER_REGISTRATION_OUTPUT | jq -r '.[].connectorConfig.activationId')
export EKSA_ACTIVATION_CODE=$(cat $CLUSTER_REGISTRATION_OUTPUT | jq -r '.[].connectorConfig.activationCode')

echo "EKSA_ACTIVATION_ID: $EKSA_ACTIVATION_ID"
echo "EKSA_ACTIVATION_CODE: $EKSA_ACTIVATION_CODE"
aws eks describe-cluster --name $EKSA_Cluster_Name

kubectl create namespace eks-connector
helm install eks-connector \
  --namespace eks-connector \
  oci://public.ecr.aws/eks-connector/eks-connector-chart \
  --set eks.activationCode=${EKSA_ACTIVATION_CODE} \
  --set eks.activationId=${EKSA_ACTIVATION_ID} \
  --set eks.agentRegion=$EKSA_AWS_REGION

kubectl get events -n eks-connector
echo "Watch the pods until they are Running"
while sleep 1; do echo "Watching for 'Running'... (to indicate it has deployed) `date`"; kubectl get pods -n eks-connector | grep Running && break; done

# Switch context back to default namespace
kubectl config set-context --current --namespace=default

exit 0

## CLEANUP
# Run the following without the "#"
# helm delete eks-connector
