#!/bin/bash

cd ~/DevOps/eksa/latest/ 
kubectl get secret -n eksa-system ${CLUSTER_NAME}-ca -o yaml | yq '.data."tls.crt"' | base64 -d > $CLUSTER_NAME.pem
openssl x509 -in $CLUSTER_NAME.pem -text


