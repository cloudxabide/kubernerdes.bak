#!/bin/bash

# Note:  I separate out some of the commands in their own stanza (i.e. I run a for-loop to install, then another for-loop to check status)
#         This allows me to cut-and-paste sections of code while I am testing.  (in case my code looks ineffecient ;-)
# Assumptions: This script assumes that you have a dummy/disposable cluster, created using 3-nodes which 
#                are both control-plane and worker nodes (basically my lab setup).

HOSTS="eks-host01
eks-host02
eks-host03"

# Install the iSCSI components on the worker nodes
# NOTE:  If openEBS was something to be used in "production", you would want to include these steps in your host build
#          that would be used to deploy your worker nodes.
for HOST in $HOSTS
do
  ssh -i ~/.ssh/id_ecdsa-kubernerdes.lab ec2-user@$HOST "uptime"
done

##
# Install iSCSI
##

for HOST in $HOSTS
do
  ssh -i ~/.ssh/id_ecdsa-kubernerdes.lab ec2-user@$HOST " 
    sudo apt-get update
    sudo apt-get install -y open-iscsi
    sudo systemctl enable --now iscsid"
done

for HOST in $HOSTS
do
  ssh -i ~/.ssh/id_ecdsa-kubernerdes.lab ec2-user@$HOST "
    uname -n
    sudo systemctl status iscsid"
done

## 
# Create a fileystem on spare disk (specific to my lab)
## 
export EBS_DEVICE="/dev/sda"
for HOST in $HOSTS
do
  ssh -i ~/.ssh/id_ecdsa-kubernerdes.lab ec2-user@$HOST "
    parted -s $EBS_DEVICE mklabel gpt mkpart pri ext4 2048s 100%FREE set 1 lvm on
    partprobe $EBS_DEVICE
    pvcreate -f ${EBS_DEVICE}1
    vgcreate vg_localstorage ${EBS_DEVICE}1
    lvcreate -L100G -nlv_openebs vg_localstorage
    mkfs.ext4 /dev/mapper/vg_localstorage-lv_openebs 
    mkdir /var/openebs
    echo '/dev/mapper/vg_localstorage-lv_openebs /var/openebs ext4 defaults 0 0' >> /etc/fstab
    mount -a
    #sudo wipefs -a $EBS_DEVICE"
done


##
##
# Install OpenEBS via helm
##
helm repo add openebs https://openebs.github.io/charts
helm repo update

helm upgrade openebs openebs/openebs \
--install \
--namespace openebs \
--create-namespace \
--set jiva.enabled=true

kubectl get ns
kubectl get pods -n openebs

kubectl patch storageclass openebs-jiva-csi-default -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

##
# Deploy a Test App
##
kubectl create namespace openebstest
kubectl config set-context --current --namespace=openebstest
curl -o busybox_example_app_persisent_storage.yaml https://raw.githubusercontent.com/cloudxabide/kubernerdes/main/Files/busybox_example_app_persisent_storage.yaml
kubectl apply -f busybox_example_app_persisent_storage.yaml

for HOST in $HOSTS
do
  ssh -i ~/.ssh/id_ecdsa-kubernerdes.lab ec2-user@$HOST "
    sudo iscsiadm -m session -o show
    find  /var/openebs/local -name 'volume-head*.img' -exec ls -lh {} \; "
done

kubectl apply -f busybox_example_app_persisent_storage.yaml

for HOST in $HOSTS
do
  ssh -i ~/.ssh/id_ecdsa-kubernerdes.lab ec2-user@$HOST "
    sudo iscsiadm -m session -o show
    find  /var/openebs/local -name 'volume-head*.img' -exec ls -lh {} \; "
done


