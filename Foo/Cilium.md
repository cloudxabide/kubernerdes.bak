# Cilium Stuff

TL;DR:
Follow this
https://isovalent.com/blog/post/cilium-eks-anywhere/


## If you're curious....
I was trying to figure out how to do all this on my own. (

## Install Cilium CLI 
-- From: https://docs.cilium.io/en/v1.13/gettingstarted/k8s-install-default/#install-the-cilium-cli
```
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable-v0.14.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
```

## Install OSS Cilium (work-in-progress)
Since EKS-A ships with Cilium, but a version that does not have all funcationality enabled, I need to re-install Cilium

```
helm repo add cilium https://helm.cilium.io/

```
CILIUM_DEFAULT_VERSION=$(cilium version | grep "(default)" | awk -F\: '{ print $2 }' | sed 's/ //')
helm template cilium/cilium --version $CILIUM_DEFAULT_VERSION  \
  --namespace=kube-system \
  --set preflight.enabled=true \
  --set agent=false \
  --set operator.enabled=false \
  > cilium-preflight.yaml
kubectl create -f cilium-preflight.yaml
```

## Check for the daemonset status - initially will not be ready
Then start a while loop until the first one starts (and there is no longer a '0' in the output from the command)
```
kubectl get daemonset -n kube-system | sed -n '1p;/cilium/p'
while sleep 2; do ( kubectl get daemonset -n kube-system | sed -n '1p;/cilium/p' | grep  0; ) || break; done
```


```
kubectl delete -f cilium-preflight.yaml
```


## Troubleshooting
```
kubectl get events -n kube-system
```
