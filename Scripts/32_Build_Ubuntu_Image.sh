#!/bin/bash

#     Purpose: To build an EKS Image - in this case based on Ubuntu
#        Date:
#      Status: In-Progress
# Assumptions: That you actually **need** a custom-built Ubuntu image to run your containers
#   Reference: https://anywhere.eks.amazonaws.com/docs/osmgmt/artifacts/#building-node-images

# Check whether you are the correct user
# NOTE: need to create logic to have this su if currently wrong user)
[ `id -u -n` == "image-builder" ] || { echo "ERROR: you should run this as user: image-builder."; echo "  sudo su - image-builder"; sleep 3; exit 0; }

sudo apt update -y
sudo apt install jq make qemu-kvm libvirt-daemon-system libvirt-clients virtinst cpu-checker libguestfs-tools libosinfo-bin unzip -y
sudo snap install yq
sudo usermod -a -G kvm $USER
# TODO: does this **need** to work this way?
sudo chmod 666 /dev/kvm
sudo chown root:kvm /dev/kvm
mkdir -p /home/$USER/.ssh
echo | ssh-keygen -trsa -b2048 -N ''
echo "HostKeyAlgorithms +ssh-rsa" >> /home/$USER/.ssh/config
echo "PubkeyAcceptedKeyTypes +ssh-rsa" >> /home/$USER/.ssh/config

# TEST (this should alleviate the need for the current user to logout/login to recognize the new group
newgrp kvm   

[ ! -f /usr/bin/make ] && sudo apt-get install make
[ ! -f /usr/bin/jq ] && sudo apt install -y jq
sudo apt install -y python3-pip
python3 -m pip install --user ansible

# Install Image Builder 
#export EKSA_RELEASE_VERSION=v0.19.0 # Manually define version
export EKSA_RELEASE_VERSION=$(curl -sL https://anywhere-assets.eks.amazonaws.com/releases/eks-a/manifest.yaml | yq ".spec.latestVersion")
cd /tmp
BUNDLE_MANIFEST_URL=$(curl -s https://anywhere-assets.eks.amazonaws.com/releases/eks-a/manifest.yaml | yq ".spec.releases[] | select(.version==\"$EKSA_RELEASE_VERSION\").bundleManifestUrl")
IMAGEBUILDER_TARBALL_URI=$(curl -s $BUNDLE_MANIFEST_URL | yq ".spec.versionsBundles[0].eksD.imagebuilder.uri")
curl -s $IMAGEBUILDER_TARBALL_URI | tar xz ./image-builder
sudo install -m 0755 ./image-builder /usr/local/bin/image-builder
cd -

# Add Bash Completion (optional)
image-builder completion bash > ~/.bashrc.d/image-builder

# Set some params
export OS=ubuntu
export OS_VERSION=22.04
export HYPERVISOR=baremetal
export RELEASE_CHANNEL="1-28"

echo EKSA_RELEASE_VERSION= $EKSA_RELEASE_VERSION
#image-builder build --os ubuntu --hypervisor baremetal --release-channel 1-28
image-builder build --os $OS --os-version $OS_VERSION --hypervisor $HYPERVISOR --release-channel $RELEASE_CHANNEL

## Cleanup
rm -rf ${HOME}/eks-anywhere-build-tooling

exit 0
