#!/bin/bash

#  Status: Complete/Done
# Purpose:  To configure the "admin host" (aka thekubernerd) once the OS is installed and host is on the network

NEEDSRESTART=0

# Allow sudo NOPASSWD
SUDO_USER=mansible
echo "Note:  you are going to be asked the login password for $SUDO_USER"
echo "$SUDO_USER ALL=(ALL) NOPASSWD: ALL" | sudo tee  /etc/sudoers.d/$SUDO_USER-nopasswd-all

# Update the system
NEEDRESTART_MODE=a
sudo apt update -y
sudo apt upgrade -y

PKGS="etherwake net-tools"
sudo apt -y install $PKGS 

# Unload problematic module at reboot via cron
# TODO:  This has to be done as root - this code is not setup to run as "mansible" to udpate root's cront at this time
CRON_UPDATE="@reboot modprobe -r tps6598x"
(crontab -l; echo "$CRON_UPDATE") | crontab -
modprobe -r tps6598x

# Update SSH 
[ ! -f ~/.ssh/id_ecdsa ] && { echo | ssh-keygen -C "Default Host SSH Key" -f ~/.ssh/id_ecdsa -tecdsa -b521 -N ''; } 
[ ! -f ~/.ssh/id_ecdsa-lab ] && { echo | ssh-keygen -C "Lab Host SSH Key" -f ~/.ssh/id_ecdsa-lab -tecdsa -b521 -N ''; } 
cat << EOF > ~/.ssh/config 
Host *.kubernerdes.lab
  User mansible
  UserKnownHostsFile ~/.ssh/known_hosts.kubernerdes.lab
  IdentityFile ~/.ssh/id_ecdsa-lab
EOF
chmod 0600 ~/.ssh/config

# Update login environment
mkdir ~/.bashrc.d/
cat << EOF >> ~/.bashrc

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
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

[[ $NEEDSRESTART != 0 ]] && { sudo shutdown now -r; }
exit 0