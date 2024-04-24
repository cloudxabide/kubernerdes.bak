#!/bin/bash

#     Purpose:
#        Date:
#      Status:
# Assumptions:
#        Todo: 

cd ~/eksa/
export CLUSTER_NAME=kubernerdes-eksa
export KUBECONFIG=${CLUSTER_NAME}/${CLUSTER_NAME}-eks-a-cluster.kubeconfig
export MANAGEMENT_KUBECONFIG=$(find ~/eksa/$CLUSTER_NAME -name '*kubeconfig')

#eksctl anywhere delete cluster ${CLUSTER_NAME} --kubeconfig ${MANAGEMENT_KUBECONFIG}
eksctl anywhere delete cluster ${CLUSTER_NAME} -f $(find ~/eksa/$CLUSTER_NAME -name $CLUSTER_NAME-eks-a-cluster.yaml) --kubeconfig $(find ~/eksa/$CLUSTER_NAME -name "*kubeconfig")

exit 0
