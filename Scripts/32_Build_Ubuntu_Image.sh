#!/bin/bash

#     Purpose: To build an EKS Image - in this case based on Ubuntu
#        Date:
#      Status: In-Progress
# Assumptions: That you actually **need** a custom-built Ubuntu image to run your containers
#              You are using the user: image-builder
#   Reference: https://anywhere.eks.amazonaws.com/docs/osmgmt/artifacts/#building-node-images

## Create and manage User: image-builder
id -u image-builder &>/dev/null || {

OS_RELEASE=`grep ^NAME /etc/os-release | awk -F\" '{ print $2 }'`
case $OS_RELEASE in
  "Red Hat Enterprise Linux"|"openSUSE Tumbleweed")
    SECONDARY_GROUP="wheel"
  ;;
  "Ubuntu")
    SECONDARY_GROUP="sudo"
  ;;
  *)
    SECONDARY_GROUP="admin"
  ;;
esac

sudo useradd -m -G${SECONDARY_GROUP} -u1002 -c "Image Builder" -d /home/image-builder -s /bin/bash -p '$6$KG59tNcZse1h.baM$qaZadrH8Tajdc6LnBzcmCnIMOnCQxy8tD6mhBq8IdH9cjuWySZ6BSBLXkJl/ypsRqpDtbu95fquBeVp/rP2rb/' image-builder 

# A new approach to managing sudo for Image Builder (image-builder) user
echo "image-builder ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/image-builder-nopasswd-all
restorecon -RFvv /etc/sudoers.d/image-builder-nopasswd-all
}

##
sudo su - image-builder
# Check whether you are the correct user
[ `id -u -n` == "image-builder" ] || { echo "ERROR: you should run this as user: image-builder."; echo "  sudo su - image-builder"; sleep 3; exit 0; }
[ ! -f ${HOME}/.ssh/id_rsa ] && { echo | ssh-keygen -trsa -b2048 -N ''; }

sudo apt update -y
sudo apt upgrade -y
sudo apt install jq make qemu-kvm libvirt-daemon-system libvirt-clients virtinst cpu-checker libguestfs-tools libosinfo-bin unzip -y
sudo snap install yq
sudo usermod -a -G kvm $USER
grep HostKeyAlgorithms /home/$USER/.ssh/config || { echo "HostKeyAlgorithms +ssh-rsa" >> /home/$USER/.ssh/config; }
grep PubkeyAcceptedKeyTypes /home/$USER/.ssh/config || { echo "PubkeyAcceptedKeyTypes +ssh-rsa" >> /home/$USER/.ssh/config; } 
chmod 0600 ${HOME}/.ssh/config

echo "If you just created the user - you need to logout/login to recognize being added to the kvm group"

[ ! -f /usr/bin/make ] && sudo apt-get install make
[ ! -f /usr/bin/jq ] && sudo apt install -y jq
[ `python --version` != "3.9.0" ] && { sudo apt -y install python3.9; }
sudo apt install -y python3-pip
python3 -m pip install --user ansible

# If using Ubuntu 20.04 - you need to set python3.9 as the default
# sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1

#export EKSA_RELEASE_VERSION=v0.19.0 # Manually define version
export EKSA_RELEASE_VERSION=$(curl -sL https://anywhere-assets.eks.amazonaws.com/releases/eks-a/manifest.yaml | yq ".spec.latestVersion")
# Install Image Builder 
[ ! -f /usr/local/bin/image-builder ] && {
  cd /tmp
  BUNDLE_MANIFEST_URL=$(curl -s https://anywhere-assets.eks.amazonaws.com/releases/eks-a/manifest.yaml | yq ".spec.releases[] | select(.version==\"$EKSA_RELEASE_VERSION\").bundleManifestUrl")
  IMAGEBUILDER_TARBALL_URI=$(curl -s $BUNDLE_MANIFEST_URL | yq ".spec.versionsBundles[0].eksD.imagebuilder.uri")
  curl -s $IMAGEBUILDER_TARBALL_URI | tar xz ./image-builder
  sudo install -m 0755 ./image-builder /usr/local/bin/image-builder
  cd -
}

# Add Bash Completion (optional)
mkdir ~/.bashrc.d
image-builder completion bash > ~/.bashrc.d/image-builder

## REPEATABLE SECTION HERE
### Cleanup
# rm -rf ${HOME}/eks-anywhere-build-tooling

manual_versioning() {
export EKSA_RELEASE_VERSION=v0.19.0 # Manually define version
EKSA_RELEASE_VERSION=v0.18.0; RELEASE_CHANNEL="1-28"
EKSA_RELEASE_VERSION=v0.19.0; RELEASE_CHANNEL="1-29"
}

# Set some params
export OS=ubuntu
export OS_VERSION=22.04
export HYPERVISOR=baremetal
export RELEASE_CHANNEL="1-29"
export EKSA_RELEASE_VERSION=$(curl -sL https://anywhere-assets.eks.amazonaws.com/releases/eks-a/manifest.yaml | yq ".spec.latestVersion")
# export BUILD_TOOLING_COMMIT=$(curl -s $BUNDLE_MANIFEST_URL | yq ".spec.versionsBundles[0].eksD.gitCommit")

echo "EKSA_RELEASE_VERSION: $EKSA_RELEASE_VERSION"
[ ! -z $BUILD_TOOLING_COMMIT ] && echo "BUILD_TOOLING_COMMIT: $BUILD_TOOLING_COMMIT"

echo "image-builder build --os $OS --os-version $OS_VERSION --hypervisor $HYPERVISOR --release-channel $RELEASE_CHANNEL --eksa-release $EKSA_RELEASE_VERSION"
image-builder build --os $OS --os-version $OS_VERSION --hypervisor $HYPERVISOR --release-channel $RELEASE_CHANNEL --eksa-release $EKSA_RELEASE_VERSION

exit 0
