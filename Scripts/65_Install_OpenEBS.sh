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
EBS_DEVICE_NAME="nvme0n1"
export EBS_DEVICE="/dev/$EBS_DEVICE_NAME"
case $EBS_DEVICE_NAME in
  nvme0n1)
    export EBS_DEVICE_PARTITION="${EBS_DEVICE}p1"
  ;;
  sda)
    export EBS_DEVICE_PARTITION="${EBS_DEVICE}1"
esac
 
echo "Disk: $EBS_DEVICE"
echo "Partition: $EBS_DEVICE_PARTITION"

# Wipe the Disk (THIS IS DESTRUCTIVE - like, for real)
for HOST in $HOSTS
do
  ssh -i ~/.ssh/id_ecdsa-kubernerdes.lab ec2-user@$HOST "
    sudo wipefs -a $EBS_DEVICE" 
done

for HOST in $HOSTS
do
  ssh -i ~/.ssh/id_ecdsa-kubernerdes.lab ec2-user@$HOST "
    sudo parted -s $EBS_DEVICE mklabel gpt mkpart pri ext4 2048s 100%FREE set 1 lvm on
    sudo partprobe $EBS_DEVICE
    sudo pvcreate -f ${EBS_DEVICE_PARTITION}
    sudo vgcreate vg_localstorage ${EBS_DEVICE_PARTITION}
    sudo lvcreate -L100G -nlv_openebs vg_localstorage
    sudo mkfs.ext4 /dev/mapper/vg_localstorage-lv_openebs 
    sudo mkdir /var/openebs
    echo '/dev/mapper/vg_localstorage-lv_openebs /var/openebs ext4 defaults 0 0' | sudo tee -a /etc/fstab
    sudo mount -a"
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
kubectl get pods -n openebstest -w

# Review hosts for new disk image file
for HOST in $HOSTS
do
  ssh -i ~/.ssh/id_ecdsa-kubernerdes.lab ec2-user@$HOST "
    sudo iscsiadm -m session -o show
    find  /var/openebs/local -name 'volume-head*.img' -exec ls -lh {} \; "
done

# Clean up app


