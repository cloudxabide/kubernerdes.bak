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

docker run hello-world

# Install EKS 
mkdir $HOME/eksa; cd $_
curl -o hardware.csv https://raw.githubusercontent.com/cloudxabide/kubernerdes/main/Files/hardware_with_bmc.csv

export EKSA_AWS_ACCESS_KEY_ID=""
export EKSA_AWS_SECRET_ACCESS_KEY=""
export EKSA_AWS_REGION="us-east-2" 

export CLUSTER_NAME=kubernerdes-eksa
export TINKERBELL_HOST_IP=10.10.21.201

# The following is how you create a vanilla clusterconfig
# eksctl anywhere generate clusterconfig $CLUSTER_NAME --provider tinkerbell > $CLUSTER_NAME.yaml

# However, I have one that I have already modified for my needs
mv $CLUSTER_NAME.yaml $CLUSTER_NAME.yaml.vanilla 
curl -o  $CLUSTER_NAME.yaml https://raw.githubusercontent.com/cloudxabide/kubernerdes/main/Files/example-clusterconfig-1.27.yaml

echo "Check out the following Doc"
echo "https://anywhere.eks.amazonaws.com/docs/getting-started/baremetal/bare-spec/"

# NOTE:  I recommend connecting with another ssh session and running the following and waiting for the "boots" container to be running and then grabbing the container id and running the 2nd command
watch docker ps -a 

# Then run...
eksctl anywhere create cluster \
   --hardware-csv hardware.csv \
   -f $CLUSTER_NAME.yaml \
   --install-packages packages.yaml
# You will watch the logs of the last command until you see "Creating new workload cluster"
# Go back to the window where the "watch" command was running and kill the watch.  Then run
docker logs -f <container id of "boots" container>

# You can then start powering on your NUC and boot from the network and watch the Docker logs

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
