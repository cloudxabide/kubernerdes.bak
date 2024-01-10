#!/bin/bash

#     Purpose:
#        Date:
#      Status: Incomplete/In-Progress
# Assumptions:

# Status:  just started this
mkdir ~/DevOps/eksa/metallb; cd $_
eksctl anywhere generate package metallb --cluster $CLUSTER_NAME > metallb.yaml

exit 0
