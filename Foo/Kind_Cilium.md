# Running Kind Cluster + Cilium

## Pre-reqs

This expects the following is installed:
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/)
- [cilium CLI](https://docs.cilium.io/en/v1.13/gettingstarted/k8s-install-default/#install-the-cilium-cli)  
- [hubble CLI](

```
mkdir -p ~/DevOps/kind-cilium; cd $_

cat << EOF1 | tee kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
networking:
  disableDefaultCNI: true
EOF1
kind create cluster --config=kind-config.yaml

cat << EOF2 | tee kind-config-3_2.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: control-plane
  - role: control-plane
  - role: worker
  - role: worker
networking:
  disableDefaultCNI: true
EOF2

kind create cluster --config=kind-config-3_2.yaml

echo "Note: Nodes will be NotReady (until you install a CNI)"
kubectl get nodes

cilium version
cilium install
cilium status --wait
cilium hubble enable --ui
cilium status --wait
cilium status
cilium connectivity test --request-timeout 30s --connect-timeout 10s
```


```
kubectl get nodes
kubectl get daemonsets --all-namespaces
kubectl get deployments --all-namespaces
```

```
kubectl create -f https://raw.githubusercontent.com/cilium/cilium/HEAD/examples/minikube/http-sw-app.yaml
kubectl get services
kubectl get pods,CiliumEndpoints

kubectl exec xwing -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing
kubectl exec tiefighter -- curl -s -XPOST deathstar.default.svc.cluster.local/v1/request-landing

kubectl describe pod/xwing
kubectl describe pod/tiefighter

cilium hubble ui
```

exit 0

## Cleanup
kind delete clusters kind
