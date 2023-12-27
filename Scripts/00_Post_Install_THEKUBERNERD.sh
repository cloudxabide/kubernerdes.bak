#!/bin/bash
#
#      Status: Complete/Done
#        Date: 
#     Purpose: To configure the "admin host" (aka thekubernerd) once the OS is installed and host is on the network
# Assumptions: It is assumed this is being run on a "newly deployed Ubuntu Host".  I did not necessarilly create it to 
#                be idempotent.
#
# Set some VARS
NEEDRESTART_MODE=a


# Allow sudo NOPASSWD
SUDO_USER=mansible
echo "NOTE:  you are going to be asked the login password for $SUDO_USER to (permanently) enable sudo"
echo "       This should be the ONLY time you are asked for a password"
echo "$SUDO_USER ALL=(ALL) NOPASSWD: ALL" | sudo tee  /etc/sudoers.d/$SUDO_USER-nopasswd-all

# Install/enable SSH Server
sudo systemctl --no-pager status sshd || { sudo apt install -y openssh-server; sudo systemctl enable sshd --now; }

# I use brew to install k9s
mkdir ~/homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
~/homebrew/bin/brew

# Setup User Environment
# Update login environment
[ ! -d ${HOME}/.bashrc.d ] && { mkdir ${HOME}/.bashrc.d; }
# Enable $HOME/.bashrc.d/* functionality
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
curl https://raw.githubusercontent.com/cloudxabide/devops/main/Files/.bashrc.d_ubuntu | tee ~/.bashrc.d/ubuntu

# Enable Firewall (not sure I'll be using a firewall)
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

# Update the system
sudo apt update -y
sudo apt upgrade -y

# Install some general "system tools"
PKGS="etherwake net-tools curl git"
OPT_PKGS="nmap"
sudo apt -y install $PKGS $OPT_PKGS

# Unload problematic kernel module at reboot via cron (this is specific to my NUCs)
sudo su - -c '
CRON_UPDATE="@reboot modprobe -r tps6598x"
(crontab -l; echo "$CRON_UPDATE") | crontab -
modprobe -r tps6598x '

# Update SSH Keys and Config
[ ! -f ~/.ssh/id_ecdsa ] && { echo | ssh-keygen -C "Default Host SSH Key" -f ~/.ssh/id_ecdsa -tecdsa -b521 -N ''; } 
[ ! -f ~/.ssh/id_ecdsa-kubernerdes.lab ] && { echo | ssh-keygen -C "Lab Host SSH Key" -f ~/.ssh/id_ecdsa-kubernerdes.lab -tecdsa -b521 -N ''; } 
cat << EOF > ~/.ssh/config 
Host 10.10.12.* *.kubernerdes.lab
  User mansible
  UserKnownHostsFile ~/.ssh/known_hosts.kubernerdes.lab
  IdentityFile ~/.ssh/id_ecdsa-kubernerdes.lab
EOF
chmod 0600 ~/.ssh/config

## Install Helm
which helm || {
sudo snap install  helm --classic
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
}

# Install Desktop GUI
install_desktop() {
  sudo apt install -y ubuntu-desktop
  NEEDSRESTART=$((NEEDSRESTART + 1))
}

mkdir -p $HOME/Repositories/Personal/cloudxabide/; cd $_
git clone https://github.com/cloudxabide/kubernerdes.git
ln -s $HOME/Repositories/Personal/cloudxabide/kubernerdes $HOME
cd $HOME

exit 0
