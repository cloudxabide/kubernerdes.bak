#!/bin/bash

#     Purpose: 
#        Date:
#      Status: 
# Assumptions:

# Make sure SNAP is installed
$(which yq) || sudo snap install yq

# install the AWS CLI
sudo snap install aws-cli --classic

curl "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
    --silent --location \
    | tar xz -C /tmp
sudo install -m 0755 /tmp/eksctl /usr/local/bin/eksctl

RELEASE_VERSION=$(curl https://anywhere-assets.eks.amazonaws.com/releases/eks-a/manifest.yaml --silent --location | yq ".spec.latestVersion")
EKS_ANYWHERE_TARBALL_URL=$(curl https://anywhere-assets.eks.amazonaws.com/releases/eks-a/manifest.yaml --silent --location | yq ".spec.releases[] | select(.version==\"$RELEASE_VERSION\").eksABinary.$(uname -s | tr A-Z a-z).uri")
curl $EKS_ANYWHERE_TARBALL_URL \
    --silent --location \
    | tar xz ./eksctl-anywhere
sudo install -m 0755 ./eksctl-anywhere /usr/local/bin/eksctl-anywhere

export OS="$(uname -s | tr A-Z a-z)" ARCH=$(test "$(uname -m)" = 'x86_64' && echo 'amd64' || echo 'arm64')
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/${OS}/${ARCH}/kubectl"
sudo install -m 0755 ./kubectl /usr/local/bin/kubectl

echo "Note:  these should all return a version (and not be blank)"
echo "aws-cli version: $(aws --version)"; echo
echo "eksctl version: $(eksctl version)"; echo
echo "eksctl anywhere version: $(eksctl anywhere version)"; echo
echo "kubectl version: $(kubectl version) -- Note:  this will likely throw a warning.  That is OK at this point"; echo

exit 0
