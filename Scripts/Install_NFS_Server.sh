#!/bin/bash

# WARNING:  THIS IS AN OPINIONATED SCRIPT TO INSTALL NFS SERVER ON A SYSTEM WITH
#             A SPECIFIC CONFIGURATION.  (i.e. Don't simply run this on one of your
#             systems and hope for the best.


sudo apt-get install nfs-kernel-server
sudo systemctl enable nfs-kernel-server.service --now

export LV_SIZE=200
export LV_NAME=lv_eksa

export VG_NAME=$(sudo vgs -o vg_name | grep -v VG)
sudo lvcreate -L$LV_SIZE -n$LV_NAME $VG_NAME

# Mapper adds a hhypen '-' to the name in /dev/mapper (I'll need to figure out how to do this better later)
MAPPER_DEV=$(find /dev/mapper/ | grep ${LV_NAME})
sudo mkfs.ext4 $MAPPER_DEV

# I will use /mnt/nfs_shares following what resembles my TrueNAS host
sudo mkdir -p /mnt/nfs_shares
echo "$MAPPER_DEV /mnt/nfs_shares ext4 defaults 0 0" | sudo tee -a /etc/fstab
sudo mount -a

sudo mkdir /mnt/nfs_shares/eksa
sudo chown nobody:nogroup /mnt/nfs_shares/eksa
sudo chmod 0777 /mnt/nfs_shares/eksa
sudo chmod g+s /mnt/nfs_shares/eksa

cat << EOF | sudo tee -a /etc/exports
/mnt/nfs_shares/eksa 10.10.12.0/22(rw,sync,no_subtree_check) 
EOF 
sudo exportfs -a
sudo exportfs 

# Install NFS Client on Nodes (not sure this is necessary)
for NODE in `seq 1 3`; do ssh -i ~/.ssh/id_ecdsa-kubernerdes.lab -l ec2-user 10.10.12.10${NODE} "sudo yum -y install nfs-utils" ; done

exit 0


## Reference
https://microk8s.io/docs/how-to-nfs
https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/blob/master/charts/nfs-subdir-external-provisioner/README.md
https://github.com/kubernetes-csi/csi-driver-nfs




sudo mkdir /mnt/test
sudo mount 10.10.12.10:/mnt/nfs_shares/eksa /mnt/test
touch /mnt/nfs_shares/eksa/test
ls -l /mnt/test
mount | grep test
sudo umount /mnt/test


sudo ufw allow from 10.10.12.0/24 to 10.10.12.48 port 80
sudo ufw allow from client_ip to any port nfs
