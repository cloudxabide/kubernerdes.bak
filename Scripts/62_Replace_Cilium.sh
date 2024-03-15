#/bin/bash
# https://isovalent.com/blog/post/cilium-eks-anywhere/

# From: https://docs.cilium.io/en/v1.13/gettingstarted/k8s-install-default/#install-the-cilium-cli
helm repo add cilium https://helm.cilium.io/

# Check the default/included Cilium 
kubectl -n kube-system exec ds/cilium -- cilium version

# Install Cilium CLI
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable-v0.14.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum 
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
cilium version; echo

# Install Hubble CLI
export HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
HUBBLE_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then HUBBLE_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum
sudo tar xzvfC hubble-linux-${HUBBLE_ARCH}.tar.gz /usr/local/bin
rm hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
hubble version; echo

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
while sleep 2; do ( kubectl get daemonset -n kube-system | sed -n '1p;/cilium/p' | grep  0; ) || break; done

# Once the daemonset is running
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
}

# helm install cilium cilium/cilium --version 1.13.3 \
helm install cilium cilium/cilium --version $CILIUM_DEFAULT_VERSION \
  --namespace kube-system \
  --set eni.enabled=false \
  --set ipam.mode=kubernetes \
  --set egressMasqueradeInterfaces=eth0 \
  --set tunnel=geneve \
  --set hubble.metrics.enabled="{dns,drop,tcp,flow,icmp,http}" \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true 

### Validate the install
while sleep 2; do cilium status | egrep 'error' || break; done
kubectl get nodes -o wide # make sure all nodes are "READY"
kubectl -n kube-system exec ds/cilium -- cilium-health status
cilium connectivity test

## Test Cilium Connectivity
cilium connectivity test

exit 0

# Troubleshooting, etc...

# This cannot (easily) be scripted, I think?
## terminal 1
kubectl port-forward -n kube-system svc/hubble-relay 4245:80 # For local connectivity (if you're using Docker, maybe?)
## terminal 2
hubble status

# This generates a TON of output
hubble observe --server localhost:4245 --follow

kubectl port-forward -n kube-system svc/hubble-ui 12000:80

# kubectl get events -n kube-system
