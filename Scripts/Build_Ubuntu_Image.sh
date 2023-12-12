#!/bin/bash


[ ! -f /usr/bin/make ] && sudo apt-get install make
[ ! -f /usr/bin/jq ] && sudo apt install -y jq
sudo apt install -y python3-pip
python3 -m pip install --user ansible

# Install Image Builder 
cd /tmp
BUNDLE_MANIFEST_URL=$(curl -s https://anywhere-assets.eks.amazonaws.com/releases/eks-a/manifest.yaml | yq ".spec.releases[] | select(.version==\"$EKSA_RELEASE_VERSION\").bundleManifestUrl")
IMAGEBUILDER_TARBALL_URI=$(curl -s $BUNDLE_MANIFEST_URL | yq ".spec.versionsBundles[0].eksD.imagebuilder.uri")
curl -s $IMAGEBUILDER_TARBALL_URI | tar xz ./image-builder
sudo install -m 0755 ./image-builder /usr/local/bin/image-builder
cd -

# Set some params
#EKSA_RELEASE_VERSION=v0.18.0
export EKSA_RELEASE_VERSION=$(curl -sL https://anywhere-assets.eks.amazonaws.com/releases/eks-a/manifest.yaml | yq ".spec.latestVersion")
export OS=ubuntu
export OS_VERSION=22.04
export HYPERVISOR=baremetal
export RELEASE_CHANNEL="1-28"

#image-builder build --os ubuntu --hypervisor baremetal --release-channel 1-28
image-builder build --os $OS --os-version $OS_VERSION --hypervisor $HYPERVISOR --release-channel $RELEASE_CHANNEL


## Cleanup
rm -rf ${HOME}/eks-anywhere-build-tooling


