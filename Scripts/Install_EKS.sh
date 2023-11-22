#!/bin/bash

# Install Docker CE
# https://docs.docker.com/engine/install/ubuntu/

# First, remove any existing Docker packages
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

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
docker run hello-world
echo "You need to logout/login to recognize group modification"

# Install EKS 
mkdir $HOME/eksa; cd $_
curl -o hardware.csv https://raw.githubusercontent.com/cloudxabide/kubernerdes/main/Files/hardware.csv

export EKSA_AWS_ACCESS_KEY_ID="
export EKSA_AWS_SECRET_ACCESS_KEY=""
export EKSA_AWS_REGION="us-east-2" 


export CLUSTER_NAME=kubernerdes-eksa
export TINKERBELL_HOST_IP=10.10.21.201
eksctl anywhere generate clusterconfig $CLUSTER_NAME --provider tinkerbell > $CLUSTER_NAME.yaml
mv $CLUSTER_NAME.yaml $CLUSTER_NAME.yaml.vanilla 
curl -o  $CLUSTER_NAME.yaml https://raw.githubusercontent.com/cloudxabide/kubernerdes/main/Files/example-clusterconfig.yaml

echo "Check out the following Doc"
echo "https://anywhere.eks.amazonaws.com/docs/getting-started/baremetal/bare-spec/"

eksctl anywhere create cluster \
   --hardware-csv hardware.csv \
   -f $CLUSTER_NAME.yaml \
   --install-packages packages.yaml

export KUBECONFIG=${PWD}/${CLUSTER_NAME}/${CLUSTER_NAME}-eks-a-cluster.kubeconfig
kubectl get nodes -A -o wide

# Label the worker nodes as ... (wait for it .... ) workers
for NODE in $(kubectl get nodes -A -o wide | grep -v control-plane | grep "<none>" | awk '{ print $1 }'); do kubectl label node $NODE node-role.kubernetes.io/worker=worker ; done
kubectl get nodes -A -o wide --show-labels=true
kubectl get hardware -n eksa-system --show-labels 

exit 0

## Troubleshooting and Observability
Run this and wait for the boots container to come up
while true; do docker ps; sleep 5; echo; done

Then
docker logs -f boots


## Options to explore later
# =======
   export TINKERBELL_HOST_IP=10.10.21.201
   export CLUSTER_NAME="mycluster"
   export TINKERBELL_PROVIDER=true
   eksctl anywhere generate clusterconfig $CLUSTER_NAME --provider tinkerbell > $CLUSTER_NAME.yaml
