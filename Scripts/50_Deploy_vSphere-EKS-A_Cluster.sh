#!/bin/bash

Purpose:  Build a vSphere hosted cluster 
Status:   Work In Progress

install_utilities() {
# Interesting tool necessary to retrieve artifacts
curl https://sh.rustup.rs -sSf | sh
(which cargo) || { echo "Installing Cargo"; sudo apt -y install cargo; }
CARGO_NET_GIT_FETCH_WITH_CLI=true cargo install --force tuftool
export PATH=$PATH:/home/mansible/.cargo/bin

# Install GOVC
curl -o govc_$(uname -s)_$(uname -m).tar.gz -L  "https://github.com/vmware/govmomi/releases/latest/download/govc_$(uname -s)_$(uname -m).tar.gz"
tar -xvzf govc_$(uname -s)_$(uname -m).tar.gz
sudo install -m 0755 govc /usr/local/bin 
}

download_OVA() {
EKSA_RELEASE_VERSION=$(curl -sL https://anywhere-assets.eks.amazonaws.com/releases/eks-a/manifest.yaml | yq ".spec.latestVersion")

BUNDLE_MANIFEST_URL=$(curl -sL https://anywhere-assets.eks.amazonaws.com/releases/eks-a/manifest.yaml | yq ".spec.releases[] | select(.version==\"$EKSA_RELEASE_VERSION\").bundleManifestUrl")
curl -s $BUNDLE_MANIFEST_URL | yq ".spec.versionsBundles[].eksD.ova.bottlerocket.uri"

curl -O "https://cache.bottlerocket.aws/root.json"
sha512sum -c <<<"a3c58bc73999264f6f28f3ed9bfcb325a5be943a782852c7d53e803881968e0a4698bd54c2f125493f4669610a9da83a1787eb58a8303b2ee488fa2a3f7d802f  root.json"
 
export KUBEVERSION="1.29"
EKSA_RELEASE_VERSION=$(curl -sL https://anywhere-assets.eks.amazonaws.com/releases/eks-a/manifest.yaml | yq ".spec.latestVersion")

export BOTTLEROCKET_IMAGE_FORMAT="ova"
BUNDLE_MANIFEST_URL=$(curl -sL https://anywhere-assets.eks.amazonaws.com/releases/eks-a/manifest.yaml | yq ".spec.releases[] | select(.version==\"$EKSA_RELEASE_VERSION\").bundleManifestUrl")
BUILD_TOOLING_COMMIT=$(curl -s $BUNDLE_MANIFEST_URL | yq ".spec.versionsBundles[0].eksD.gitCommit")
export BOTTLEROCKET_VERSION=$(curl -sL https://raw.githubusercontent.com/aws/eks-anywhere-build-tooling/$BUILD_TOOLING_COMMIT/projects/kubernetes-sigs/image-builder/BOTTLEROCKET_RELEASES | yq ".$(echo $KUBEVERSION | tr '.' '-').$BOTTLEROCKET_IMAGE_FORMAT-release-version")

OVA="bottlerocket-vmware-k8s-${KUBEVERSION}-x86_64-${BOTTLEROCKET_VERSION}.ova"
tuftool download ${TMPDIR:-/tmp/bottlerocket-ovas} --target-name "${OVA}" \
   --root ./root.json \
   --metadata-url "https://updates.bottlerocket.aws/2020-07-07/vmware-k8s-${KUBEVERSION}/x86_64/" \
   --targets-url "https://updates.bottlerocket.aws/targets/"
}

#############
## START HERE
#############
# Source your VMware info file
. ~/.vsphere-eksa

## Cleanup existing Docker Containers
[ -z $EKSA_AWS_ACCESS_KEY_ID ] && { echo "Whoa there.... you need to set your EKSA_AWS_ACCESS_KEY_ID and associated variables"; sleep 4; exit; }
cd
docker kill $(docker ps -a | egrep 'boots|eks' | awk '{ print $1 }' | grep -v CONTAINER)
docker rm $(docker ps -a | egrep 'boots|eks' | awk '{ print $1 }' | grep -v CONTAINER)

govc datacenter.info; echo
for TOPIC in network vm host datastore vm/Templates
do
  echo "# $TOPIC"
  govc ls $TOPIC
  echo
done
echo "# Resource Pool"
govc find / -type p

# RETRIEVE vSphere THUMBPRINT
export VSPHERE_THUMBPRINT=$(govc about.cert -k -json | jq -r '.thumbprintSHA1')

# Cluster-Specific Variables
OS=bottlerocket
HYPERVISOR=vsphere
NODE_LAYOUT="3_3_2"
export KUBE_VERSION="1.29"
[ -z $CLUSTER_NAME ] && export CLUSTER_NAME=vsphere-eksa
export CLUSTER_CONFIG=${CLUSTER_NAME}.yaml
export CLUSTER_CONFIG_SOURCE="example-clusterconfig-${HYPERVISOR}-${OS}-${KUBE_VERSION}-${NODE_LAYOUT}.yaml" # Name of file in Git Repo

# NEED TO MAKE THIS MOVE THE DIR TO AN ARCHIVE OR SOMETHING
TODAY=`date +%F`
EKS_BASE=$HOME/eksa/$CLUSTER_NAME
EKS_DIR=$EKS_BASE/${TODAY}
[ -d ${EKS_DIR}  ] && { mv ${EKS_DIR} ${EKS_DIR}-01; }
mkdir -p $EKS_DIR
cd ${EKS_BASE}/
rm latest
ln -s $EKS_DIR ${EKS_BASE}/latest
cd ${EKS_DIR}
mkdir $CLUSTER_NAME

# The following is how you create a default clusterconfig
eksctl anywhere generate clusterconfig $CLUSTER_NAME --provider vsphere > $CLUSTER_CONFIG.generated
curl -o $CLUSTER_CONFIG.vanilla https://raw.githubusercontent.com/cloudxabide/kubernerdes.bak/main/Files/$CLUSTER_CONFIG_SOURCE

# Retrieve the pub key for the "kubernedes.lab" domain
export MY_SSH_KEY=$(cat ~/.ssh/*kubernerdes.lab.pub)
envsubst <  $CLUSTER_CONFIG.vanilla > $CLUSTER_CONFIG
cat $CLUSTER_CONFIG
#sdiff $CLUSTER_CONFIG.vanilla $CLUSTER_CONFIG | egrep '\|'
sdiff $CLUSTER_CONFIG.generated $CLUSTER_CONFIG | egrep '\|'

# Create the Cluster
sudo systemctl start isc-dhcp-server.service
unset KUBECONFIG
eksctl anywhere create cluster \
   -f  $CLUSTER_CONFIG

exit 0

# Update Certificates for host (status: still broken - ugh)
curl -o certs.zip -L https://vmw-vcenter7.matrix.lab/certs/download.zip
unzip certs.zip
openssl x509 -in certs/lin/9e242a2b.0 -noout -text | grep Subject:
sudo mkdir /usr/share/ca-certificates/extra
sudo cp certs/lin/9e242a2b.0 /usr/share/ca-certificates/extra/
sudo update-ca-certificates

rm -rf /home/mansible/eksa/vsphere-eksa/2024-03-26/eksa-cli-logs/*
rm -rf ./vsphere-eksa/generated/*
