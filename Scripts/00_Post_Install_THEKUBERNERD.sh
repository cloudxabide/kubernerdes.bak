#!/bin/bash

#  Status: Complete/Done
# Purpose:  To configure the "admin host" (aka thekubernerd) once the OS is installed and host is on the network
NEEDSRESTART=0

# Allow sudo NOPASSWD
SUDO_USER=mansible
echo "Note:  you are going to be asked the login password for $SUDO_USER"
echo "$SUDO_USER ALL=(ALL) NOPASSWD: ALL" | sudo tee  /etc/sudoers.d/$SUDO_USER-nopasswd-all

# Install/enable SSH Server
sudo apt install -y openssh-server

# Enable Firewall
enable_firewall() {
sudo ufw allow ssh
sudo ufw allow http 
sudo ufw allow tftp 
sudo ufw allow bootps
sudo ufw allow 53/udp
sudo ufw allow 53/tcp

sudo ufw enable
sudo ufw status
sudo ufw show added
}

echo "DEBIAN_FRONTEND=noninteractive" | sudo tee -a ~/.bashrc
echo "NEEDRESTART_MODE=a" | sudo tee -a ~/.bashrc

# Update the system
NEEDRESTART_MODE=a
sudo apt update -y
sudo apt upgrade -y

PKGS="etherwake net-tools curl git"
sudo apt -y install $PKGS 

# Unload problematic module at reboot via cron
sudo su - -c '
CRON_UPDATE="@reboot modprobe -r tps6598x"
(crontab -l; echo "$CRON_UPDATE") | crontab -
modprobe -r tps6598x '

# Update SSH 
[ ! -f ~/.ssh/id_ecdsa ] && { echo | ssh-keygen -C "Default Host SSH Key" -f ~/.ssh/id_ecdsa -tecdsa -b521 -N ''; } 
[ ! -f ~/.ssh/id_ecdsa-kubernerdes.lab ] && { echo | ssh-keygen -C "Lab Host SSH Key" -f ~/.ssh/id_ecdsa-kubernerdes.lab -tecdsa -b521 -N ''; } 
cat << EOF > ~/.ssh/config 
Host 10.10.12.* *.kubernerdes.lab
  User mansible
  UserKnownHostsFile ~/.ssh/known_hosts.kubernerdes.lab
  IdentityFile ~/.ssh/id_ecdsa-kubernerdes.lab
EOF
chmod 0600 ~/.ssh/config

# Update login environment
mkdir ~/.bashrc.d/
cat << EOF >> ~/.bashrc

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "\$rc" ]; then
			. "\$rc"
		fi
	done
fi
EOF
curl https://raw.githubusercontent.com/cloudxabide/devops/main/Files/.bashrc.d_common | tee ~/.bashrc.d/common

# Install Desktop GUI
install_desktop() {
  sudo apt install -y ubuntu-desktop
  NEEDSRESTART=$((NEEDSRESTART + 1))
}

mkdir -p $HOME/Repositories/Personal/cloudxabide/; cd $_
git clone https://github.com/cloudxabide/kubernerdes.git
ln -s $HOME/Repositories/Personal/cloudxabide/kubernerdes $HOME
cd $HOME

[[ $NEEDSRESTART != 0 ]] && { sudo shutdown now -r; }
exit 0
