#!/bin/bash

#     Purpose: Install Docker to provide environment to run EKS Installer (and kind cluster)
#        Date: 2024-02-11
#      Status: Complete
# Assumptions:

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

exit 0
