#/bin/bash

#     Purpose: To replace EKS-A included Cilium with Cilium OSS
#        Date: 2024-03-01
#      Status: GTG, I think
#              Ready to test (this is still a bit clunky, therefore it should be cut-and-paste and 
#                interactively installed)
#        Todo: Update process to update Cilium and Hubble CLI, if needed
# Assumptions:

# https://isovalent.com/blog/post/cilium-eks-anywhere/

# Install a test app
kubectl create namespace hello-eksa-a
kubectl apply -f "https://anywhere.eks.amazonaws.com/manifests/hello-eks-a.yaml" -n hello-eksa-a
kubectl get pods -l app=hello-eks-a -n hello-eksa-a
sleep 5
kubectl logs -l app=hello-eks-a -n hello-eksa-a
# kubectl port-forward deploy/hello-eks-a 8000:80
# curl localhost:8000

# From: https://docs.cilium.io/en/v1.13/gettingstarted/k8s-install-default/#install-the-cilium-cli
# Check the default/included Cilium 
kubectl -n kube-system exec ds/cilium -- cilium version

########################################
# Install Cilium CLI
install_Cilium_CLI() {
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable-v0.14.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum 
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
cilium version; echo
}

# Install Hubble CLI
install_Hubble_CLI() {
export HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
HUBBLE_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then HUBBLE_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum
sudo tar xzvfC hubble-linux-${HUBBLE_ARCH}.tar.gz /usr/local/bin
rm hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
hubble version; echo
}
########################################

# Add Cilium Helm Repo
helm repo add cilium https://helm.cilium.io/
helm repo update cilium

### PRE-FLIGHT CHECK
#  Replace EKS-A version of Cilium with OSS version
CILIUM_DEFAULT_VERSION=$(cilium version | grep "(default)" | awk -F\: '{ print $2 }' | sed 's/ //')
helm template cilium/cilium --version $CILIUM_DEFAULT_VERSION  \
  --namespace=kube-system \
  --set preflight.enabled=true \
  --set agent=false \
  --set operator.enabled=false \
  > cilium-preflight.yaml
kubectl create -f cilium-preflight.yaml

# Check for the daemonset status - initially will not be ready
# Then start a while loop until the first one starts (and there is no longer a '0' in the output from the command)
# NOTE:  I need to improve this logic to check for the "DESIRED" number and wait until the correct number is running
kubectl get daemonset -n kube-system | sed -n '1p;/cilium/p'
while sleep 2; do echo; ( kubectl get daemonset -n kube-system | sed -n '1p;/cilium/p' | grep  0; ) || break; done

# Once the daemonset is running
echo "Note:  delete Cilium PreFlight Check"
kubectl delete -f cilium-preflight.yaml

### Update Cilium

# NOTE - this next set of steps are a temporary workaround to clean up accounts
clean-up-accounts() {
kubectl delete serviceaccount cilium --namespace kube-system
kubectl delete serviceaccount cilium-operator --namespace kube-system
kubectl delete secret hubble-ca-secret --namespace kube-system
kubectl delete secret hubble-server-certs --namespace kube-system
kubectl delete configmap cilium-config --namespace kube-system
kubectl delete clusterrole cilium
kubectl delete clusterrolebinding cilium
kubectl delete clusterrolebinding cilium-operator
kubectl delete secret cilium-ca --namespace kube-system
kubectl delete service hubble-peer --namespace kube-system
kubectl delete daemonset cilium --namespace kube-system
kubectl delete deployment cilium-operator --namespace kube-system
kubectl delete clusterrole cilium-operator
# The following were new additions (2024-04-21)jjj
kubectl delete role cilium-config-agent -n kube-system # if you ran the pre-flight test
kubectl delete rolebinding cilium-config-agent -n kube-system
}
clean-up-accounts

# helm install cilium cilium/cilium --version 1.13.3 \
case $CLUSTER_NAME in 
  vsphere-eksa) MYINTERFACE=eth0;;
  kubernerdes-eksa) MYINTERFACE=eno1;;
esac
  
helm install cilium cilium/cilium --version $CILIUM_DEFAULT_VERSION \
  --namespace kube-system \
  --set eni.enabled=false \
  --set ipam.mode=kubernetes \
  --set egressMasqueradeInterfaces=$MYINTERFACE \
  --set tunnel=geneve \
  --set hubble.metrics.enabled="{dns,drop,tcp,flow,icmp,http}" \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true 

### Validate the install
while sleep 2; do echo; cilium status | egrep 'error' || { echo "Great - LGTM. Let's proceed..."; break; }; done
kubectl get nodes -o wide # make sure all nodes are "READY"
## I recently noticed that I was receiving "Connection timed out" - which seemed to go away after time?
while sleep 2; do { echo "Waiting for connectivity..."; kubectl -n kube-system exec ds/cilium -- cilium-health status | egrep "Connection timed out"; } || break; done 

## Test Cilium Connectivity
echo "Running Cilium Connectivity Test - This will take a few minutes."
cilium connectivity test

exit 0

# Troubleshooting, etc...

# This cannot (easily) be scripted, I think?
## terminal 1
kubectl port-forward -n kube-system svc/hubble-relay 4245:80 # For local connectivity (if you're using Docker, maybe?)
## terminal 2
hubble status 
# If hubble relay is not running, run the following:
cilium hubble enable

# This generates a TON of output
hubble observe --server localhost:4245 --follow

kubectl port-forward -n kube-system svc/hubble-ui 12000:80

# kubectl get events -n kube-system

# If you happen to have configured your Cilium (like I did) with the wrong masquerade interface...
cat << EOF1 | tee update_Cilium.yaml
---
egressMasqueradeInterfaces: eno1
EOF1
helm upgrade cilium cilium/cilium -f update_Cilium.yaml  -n kube-system
