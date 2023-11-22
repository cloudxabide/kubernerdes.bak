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

export EKSA_AWS_ACCESS_KEY_ID="your*access*id"
export EKSA_AWS_SECRET_ACCESS_KEY="your*secret*key"
export EKSA_AWS_REGION="us-west-2" 


export CLUSTER_NAME=kubernerdes-eksa
export TINKERBELL_HOST_IP=10.10.21.201
eksctl anywhere generate clusterconfig $CLUSTER_NAME --provider tinkerbell > $CLUSTER_NAME.yaml

echo "Check out the following Doc"
echo "https://anywhere.eks.amazonaws.com/docs/getting-started/baremetal/bare-spec/"

eksctl anywhere create cluster \
   --hardware-csv hardware.csv \
   -f $CLUSTER_NAME.yaml \
   --install-packages packages.yaml

# =======
   export TINKERBELL_HOST_IP=10.10.21.201
   export CLUSTER_NAME="mycluster"
   export TINKERBELL_PROVIDER=true
   eksctl anywhere generate clusterconfig $CLUSTER_NAME --provider tinkerbell > $CLUSTER_NAME.yaml
