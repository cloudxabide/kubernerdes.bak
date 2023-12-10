#!/bin/bash

# Purpose: this script will grab a bunch of files from my "myapp" directory in my repo and then update them and apply them to my cluster
#   NOTES: it may not be obvious, but the files have to exist and be available in the repo
#    TODO: Update this to download example files, but then deploy resources that have any name desired (and configured)

export MYAPP_NAME="myapp"
export EXAMPLE_APP="example_app" # Name of the source directory and files

FILES="namespace.yaml	
deployment.yaml	
service.yaml"

for FILE in $FILES
do
  echo "curl -o ${EXAMPLE_APP}-$FILE https://raw.githubusercontent.com/cloudxabide/kubernerdes/main/Files/${EXAMPLE_APP}/${EXAMPLE_APP}-$FILE"
  curl -o  ${EXAMPLE_APP}-$FILE https://raw.githubusercontent.com/cloudxabide/kubernerdes/main/Files/${EXAMPLE_APP}/${EXAMPLE_APP}-$FILE
  echo 

  echo "envsubst < ${EXAMPLE_APP}-$FILE > $MYAPP_NAME-$FILE"
  envsubst < ${EXAMPLE_APP}-$FILE > $MYAPP_NAME-$FILE
  echo "rm ${EXAMPLE_APP}-${FILE}"
  rm ${EXAMPLE_APP}-${FILE}
  echo 

  echo "kubectl apply -f ${EXAMPLE_APP}-${FILE}"
  #kubectl apply -f ${EXAMPLE_APP}-${FILE}
  echo 
done

exit 0

# Testing

kubectl get ``endpointslices.discovery.k8s.io`` -endpoint-name -n ${MYAPP_NAME}-namespace -oyaml`

kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot --overrides='{"spec": { "nodeSelector": {"kubernetes.io/hostname":"example-node-name"}}}'  

curl ${MYAPP_NAME}-service-name:80

kubectl -n ${MYAPP_NAME}-namespace scale deployments ${MYAPP_NAME}-deployment-name --replicas=4   

