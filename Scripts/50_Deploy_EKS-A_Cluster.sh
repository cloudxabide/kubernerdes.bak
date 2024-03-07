#!/bin/bash

#     Purpose: deploy an EKS Cluster
#        Date: 2024-01-02
#      Status: WIP
# Assumptions:

#############
## EKS Anywhere
#############
# AWS Info file for Curated Packages
# I made this in to a routine as it should not be run as part of a script (ie you need to provide the details (below))
configure_AWS_credentials() {
cat << EOF > ./.eksainfo
export EKSA_AWS_ACCESS_KEY_ID=""
export EKSA_AWS_SECRET_ACCESS_KEY=""
export EKSA_AWS_REGION="us-east-1"
EOF
.  ./.eksainfo
}

#############
## START HERE
#############
# Install EKS Anywhere
echo "Check out the following Doc"
echo "https://anywhere.eks.amazonaws.com/docs/getting-started/baremetal/bare-spec/"

## Cleanup existing Docker Containers 
cd
docker kill $(docker ps -a | egrep 'boots|eks' | awk '{ print $1 }' | grep -v CONTAINER)
docker rm $(docker ps -a | egrep 'boots|eks' | awk '{ print $1 }' | grep -v CONTAINER)

TODAY=`date +%F`
EKS_BASE=$HOME/DevOps/eksa
EKS_DIR=$EKS_BASE/${TODAY}
[ -d ${EKS_DIR}  ] || { mkdir -p $EKS_DIR;} 
cd ${EKS_BASE}
rm latest
ln -s $EKS_DIR ${EKS_BASE}/latest
cd ${EKS_DIR}
 
OS=ubuntu
NODE_LAYOUT="3_0"
KUBE_VERSION="1.28"
export CLUSTER_NAME=kubernerdes-eksa
export CLUSTER_CONFIG=${CLUSTER_NAME}.yaml
export CLUSTER_CONFIG_SOURCE="example-clusterconfig-${OS}-${KUBE_VERSION}-${NODE_LAYOUT}.yaml" # Name of file in Git Repo
export TINKERBELL_HOST_IP=10.10.21.101
mkdir $CLUSTER_NAME 

# The following is how you create a default clusterconfig
eksctl anywhere generate clusterconfig $CLUSTER_NAME --provider tinkerbell > $CLUSTER_CONFIG.default

# Retrieve the hardware inventory csv file
curl -o hardware.csv https://raw.githubusercontent.com/cloudxabide/kubernerdes/main/Files/hardware-${NODE_LAYOUT}.csv

# However, I have one that I have already modified for my needs
curl -o $CLUSTER_CONFIG.vanilla https://raw.githubusercontent.com/cloudxabide/kubernerdes/main/Files/$CLUSTER_CONFIG_SOURCE

# Retrieve the pub key for the "kubernedes.lab" domain
# THIS NEEDS TO BE TESTED
export MY_SSH_KEY=$(cat ~/.ssh/*kubernerdes.lab.pub)
envsubst <  $CLUSTER_CONFIG.vanilla > $CLUSTER_CONFIG
cat $CLUSTER_CONFIG
sdiff $CLUSTER_CONFIG.vanilla $CLUSTER_CONFIG | egrep '\|'

## Let's build our cluster
eksctl anywhere create cluster \
   --hardware-csv hardware.csv \
   -f $CLUSTER_CONFIG 

alt_install() {
eksctl anywhere create cluster \
   --hardware-csv hardware.csv \
   -f $CLUSTER_CONFIG \
   --install-packages packages.yaml
}
# Watch the pods until the busybox pod is "Running", then exit
while sleep 2; do echo -n "Waiting for 'Running'.... "; date; docker ps -a | grep boots && break ; done
echo "You will need to hit CTRL-C to exit the log follow"; sleep 1
echo "You should now start to power on your NUC, one at a time, and hit F12 until the network boot starts."
echo "  After about 5 seconds move to the next node"; sleep 3
docker logs -f $(docker ps -a | grep boots | awk '{ print $1 }')

exit 0
