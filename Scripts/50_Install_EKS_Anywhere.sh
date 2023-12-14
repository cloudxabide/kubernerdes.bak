#!/bin/bash

# Install Docker CE
# https://docs.docker.com/engine/install/ubuntu/

# First, remove any existing Docker packages
DOCKER_PKGS="docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc"
sudo apt-get remove -y $DOCKER_PKGS
# This is Docker's recommendation
# for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo docker run hello-world
sudo gpasswd -a mansible docker

echo "You need to logout/login to recognize group modification"
docker run hello-world || { echo "Logging out to update Group membership"; logout; }

docker kill $(docker ps -a | grep hello-world | awk '{ print $1 }')
docker rm $(docker ps -a | grep hello-world | awk '{ print $1 }')

#############
############# EKS Anywhere
#############
# Install EKS Anywhere
mkdir $HOME/eksa; cd $_

cat << EOF > ./.info
export EKSA_AWS_ACCESS_KEY_ID=""
export EKSA_AWS_SECRET_ACCESS_KEY=""
export EKSA_AWS_REGION="us-east-2" 
EOF
.  ./.info

#############
############# START HERE
#############
echo "Check out the following Doc"
echo "https://anywhere.eks.amazonaws.com/docs/getting-started/baremetal/bare-spec/"

docker kill $(docker ps -a | awk '{ print $1 }' | grep -v CONTAINER)
docker rm $(docker ps -a | awk '{ print $1 }' | grep -v CONTAINER)
sudo rm -rf kubernerdes-eksa eksa-cli-logs kuber*

cd ~/DevOps/eksa
export CLUSTER_NAME=kubernerdes-eksa
export CLUSTER_CONFIG_SOURCE="example-clusterconfig-1.28-3_0.yaml"
export CLUSTER_CONFIG_SOURCE="example-clusterconfig-ubuntu-1.28-3_0.yaml" # Name of file in Git Repo
export CLUSTER_CONFIG=${CLUSTER_NAME}.yaml
export TINKERBELL_HOST_IP=10.10.21.201
mkdir $CLUSTER_NAME

# The following is how you create a vanilla clusterconfig
eksctl anywhere generate clusterconfig $CLUSTER_NAME --provider tinkerbell > $CLUSTER_CONFIG.default

# Retrieve the hardware inventory csv file
curl -o hardware.csv https://raw.githubusercontent.com/cloudxabide/kubernerdes/main/Files/hardware-3_0.csv

# However, I have one that I have already modified for my needs
curl -o  $CLUSTER_CONFIG.vanilla https://raw.githubusercontent.com/cloudxabide/kubernerdes/main/Files/$CLUSTER_CONFIG_SOURCE 

# Retrieve the pub key for the "kubernedes.lab" domain
# THIS NEEDS TO BE TESTED
export MY_SSH_KEY=$(cat ~/.ssh/*kubernerdes.lab.pub)
envsubst <  $CLUSTER_CONFIG.vanilla > $CLUSTER_CONFIG

eksctl anywhere create cluster \
   --hardware-csv hardware.csv \
   -f $CLUSTER_CONFIG \
   --install-packages packages.yaml
# Watch the logs of the last command until you see...
#   "Creating new workload cluster", then...

# You will see 3 containers start and run (an ECR container, the KIND cluster, then "boots")
watch docker ps -a 

# Go back to the window where the "watch" command was running and kill the watch.  Then run
docker logs -f <container id of "boots" container>
docker logs -f $(docker ps -a | grep boots | awk '{ print $1 }')

# You can then start powering on your NUC and boot from the network and watch the Docker logs

# Random "shortcuts" that *I* can use to run Kubectl 
export KUBECONFIG=${PWD}/${CLUSTER_NAME}/${CLUSTER_NAME}-eks-a-cluster.kubeconfig
export KUBECONFIG=$(find ~/DevOps/eksa -name '*kind.kubeconfig')
export KUBECONFIG=$(find ~/DevOps/eksa -name '*cluster.kubeconfig')

kubectl get nodes -A -o wide --show-labels
kubectl get nodes -A -o wide --show-labels=true
kubectl get hardware -n eksa-system --show-labels 

exit 0

## Troubleshooting and Observability
Run this and wait for the boots container to come up
while true; do docker ps; sleep 5; echo; done

# Label the worker nodes as ... (wait for it .... ) workers
for NODE in $(kubectl get nodes -A -o wide | grep -v control-plane | grep "<none>" | awk '{ print $1 }'); do kubectl label node $NODE node-role.kubernetes.io/worker=worker ; done

## Options to explore later
# =======
   export TINKERBELL_HOST_IP=10.10.21.201
   export CLUSTER_NAME="mycluster"
   export TINKERBELL_PROVIDER=true
   eksctl anywhere generate clusterconfig $CLUSTER_NAME --provider tinkerbell > $CLUSTER_NAME.yaml

## Cleanup
```
docker kill $(docker ps -a | awk '{ print $1 }' | grep -v CONTAINER)
docker rm $(docker ps -a | awk '{ print $1 }' | grep -v CONTAINER)
rm -rf kubernerdes-eksa eksa-cli-logs kuber*

