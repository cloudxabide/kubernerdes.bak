#!/bin/bash

# Status:  Blocked
#   Note:  Leaving this here in case I decide to revisit this. Kind of crazy how involved all this is.
# 

# https://docs.vmware.com/en/VMware-vSphere-Container-Storage-Plug-in/3.0/vmware-vsphere-csp-getting-started/GUID-0AB6E692-AA47-4B6A-8CEA-38B754E16567.html
# https://docs.vmware.com/en/VMware-vSphere-Container-Storage-Plug-in/3.0/vmware-vsphere-csp-getting-started/GUID-0AB6E692-AA47-4B6A-8CEA-38B754E16567.html#GUID-0AB6E692-AA47-4B6A-8CEA-38B754E16567



kubectl get nodes -o json | jq '.items[].spec.taints'
for NODE in $(kubectl get nodes | grep -v NAME | awk '{ print $1 }') 
do 
  kubectl taint node $NODE node.cloudprovider.kubernetes.io/uninitialized=true:NoSchedule
done
kubectl get nodes -o json | jq '.items[].spec.taints'

VERSION=1.28
VERSION=$(kubectl version -o json | jq -rj '.serverVersion|.major,".",.minor')
curl -o vsphere-cloud-controller-manager.yaml.default https://raw.githubusercontent.com/kubernetes/cloud-provider-vsphere/release-$VERSION/releases/v$VERSION/vsphere-cloud-controller-manager.yaml
curl -o vsphere-cloud-controller-manager.yaml.vanilla https://raw.githubusercontent.com/cloudxabide/kubernerdes/main/Files/vsphere-cloud-controller-manager.yaml
envsubst < vsphere-cloud-controller-manager.yaml.vanilla > vsphere-cloud-controller-manager.yaml
sdiff vsphere-cloud-controller-manager.yaml.vanilla vsphere-cloud-controller-manager.yaml | grep \|
kubectl apply -f vsphere-cloud-controller-manager.yaml




# https://docs.vmware.com/en/VMware-vSphere-Container-Storage-Plug-in/3.0/vmware-vsphere-csp-getting-started/GUID-A1982536-F741-4614-A6F2-ADEE21AA4588.html

kubectl create namespace vmware-system-csi
kubectl config set-context --current --namespace=vmware-system-csi

cat << EOF1 | tee  vsphere-secret.conf
[Global]
cluster-id = "HomeLab"
cluster-distribution = "native"

[VirtualCenter "10.10.10.132"]
insecure-flag = "true"
user = "user@domain"
password = "mypwd"
port = "443"
datacenters = "PisgahForest"
EOF1
kubectl create secret generic vsphere-config-secret --from-file=./vsphere-secret.conf --namespace=vmware-system-csi

kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/vsphere-csi-driver/v3.0.0/manifests/vanilla/vsphere-csi-driver.yaml

kubectl get deployment --namespace=vmware-system-csi
kubectl get daemonsets vsphere-csi-node --namespace=vmware-system-csi
# kubectl -n  vmware-system-csi patch deployment vsphere-csi-controller -p '{"spec": {"template": {"spec": {"Repliacs": "2" }}}}'
kubectl scale deployment vsphere-csi-controller --replicas=2
kubectl describe csidrivers
kubectl get configmap

exit 0

for NODE in $(kubectl get nodes | grep "control-plane" | awk '{ print $1 }'); do kubectl get node $NODE -o jsonpath='{.spec.taints}{"\n"}'; done
kubectl describe nodes | egrep "Taints:|Name:"

# kubectl delete namespace vmware-system-csi
