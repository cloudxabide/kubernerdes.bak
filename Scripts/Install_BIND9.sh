#!/bin/bash

#  Status: Complete/Done
# Purpose:

NEEDRESTART_MODE=a

sudo apt install -y bind9 bind9utils bind9-doc
sudo sed -i -e 's/bind/bind -4/g' /etc/default/named

sudo cp /etc/bind/named.conf.options /etc/bind/named.conf.options.bak
curl https://raw.githubusercontent.com/cloudxabide/kubernerdes/main/Files/etc_bind_named.conf.options | sudo tee /etc/bind/named.conf.options
sudo systemctl restart bind9  # You now have a caching nameserver using Google DNS as forwarders

# Add all of the zone files to the BIND config
sudo cp /etc/bind/named.conf.local /etc/bind/named.conf.local.bak
curl https://raw.githubusercontent.com/cloudxabide/kubernerdes/main/Files/etc_bind_named.conf.local | sudo tee /etc/bind/named.conf.local

sudo mkdir -p /etc/bind/zones
for ZONE in 12 13 14 15
do 
  curl https://raw.githubusercontent.com/cloudxabide/kubernerdes/main/Files/etc_bind_zones_db.$ZONE.10.10.in-addr.arpa | sudo tee /etc/bind/zones/db.$ZONE.10.10.in-addr.arpa
done 
curl https://raw.githubusercontent.com/cloudxabide/kubernerdes/main/Files/etc_bind_zones_db.kubernerdes.lab | sudo tee /etc/bind/zones/db.kubernerdes.lab
sudo systemctl restart bind9  # You now have a nameserver for your subnet(s)

cd /etc/bind/zones
named-checkzone kubernerdes.lab db.kubernerdes.lab
for FILE in `ls *arpa`; do named-checkzone $(echo $FILE | sed 's/db.//g'; ) $FILE; done
cd -

sudo systemctl restart systemd-resolved.service

exit 0

sudo resolvectl flush-caches

references() {
echo "https://www.digitalocean.com/community/tutorials/how-to-configure-bind-as-a-private-network-dns-server-on-ubuntu-22-04"
echo "Who knows how old this is?  https://help.ubuntu.com/community/BIND9ServerHowto"
}
