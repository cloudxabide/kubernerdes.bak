#!/bin/bash

#NOTE #NOTE #NOTE #NOTE 
# THIS MAY BE UNNECESSARY AND POSSIBLY WORSE, MAKE EKS-A NOT WORK

sudo apt install -y apache2 php libapache2-mod-php php-mysql
sudo systemctl enable apache2 --now

sudo ufw app list
sudo ufw allow in 'Apache'
sudo ufw status
#sudo systemctl enable --now ufw

# https://anywhere.eks.amazonaws.com/docs/osmgmt/artifacts/
EKSA_RELEASE_VERSION=$(curl -sL https://anywhere-assets.eks.amazonaws.com/releases/eks-a/manifest.yaml | yq ".spec.latestVersion")
# EKSA_RELEASE_VERSION=v0.18.0
BUNDLE_MANIFEST_URL=$(curl -sL https://anywhere-assets.eks.amazonaws.com/releases/eks-a/manifest.yaml | yq ".spec.releases[] | select(.version==\"$EKSA_RELEASE_VERSION\").bundleManifestUrl")

cd /var/www/html
sudo mv index.html index.html.orig

# Bottlerocket Image
curl -s $BUNDLE_MANIFEST_URL | yq ".spec.versionsBundles[].eksD.raw.bottlerocket.uri" | sudo tee manifest-$EKSA_RELEASE_VERSION.txt
sudo curl -O -J $(tail -1 manifest-$EKSA_RELEASE_VERSION.txt)

# vmlinuz
sudo curl -O -J $(curl -s $BUNDLE_MANIFEST_URL | yq ".spec.versionsBundles[0].tinkerbell.tinkerbellStack.hook.vmlinuz.amd.uri")
# initramfs
sudo curl -O -J $(curl -s $BUNDLE_MANIFEST_URL | yq ".spec.versionsBundles[0].tinkerbell.tinkerbellStack.hook.initramfs.amd.uri")

sudo chown -R www-data:www-data /var/www
# Update the index page to be a dynamic version run in PHP
sudo curl -o /var/www/html/index.php https://raw.githubusercontent.com/cloudxabide/kubernerdes/main/Files/index.php
exit 0



######################33
#### I have decided NOT to do any of this, and just use /var/www/html 

# Some foolishness to serve this repo as the web directory (might change this later?)
sudo mkdir /var/www/kubernerdes /var/www/hookImages /var/www/osImage
sudo scp -r --exclude ".git" /home/mansible/Repositories/Personal/cloudxabide/kubernerdes/ /var/www/kubernerdes/
sudo chown -R www-data:www-data /var/www/

cat << EOF | sudo tee -a /etc/hosts

# Entry for VirtualHost HTTP Server
10.10.12.10 kubernerdes.lab
EOF 

sudo rm /etc/apache2/sites-enabled/000-default.conf

cat << EOF  | sudo tee /etc/apache2/sites-available/kubernerdes.lab.conf
<VirtualHost *:80>
    ServerAdmin webmaster@kubernerdes.lab
    ServerName kubernerdes.lab
    ServerAlias kubernerdes.lab
    DocumentRoot /var/www/kubernerdes
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
    Options Indexes FollowSymLinks MultiViews

    Alias /osImage/ "/var/www/osImage/"
    <Directory "/var/www/osImage">
        Options Indexes MultiViews FollowSymLinks
        AllowOverride None
        Order allow,deny
        Allow from all
    </Directory>

    Alias /hookImages/ "/var/www/hookImages/"
    <Directory "/var/www/hookImages">
        Options Indexes MultiViews FollowSymLinks
        AllowOverride None
        Order allow,deny
        Allow from all
    </Directory>
</VirtualHost>
EOF 

sudo apache2ctl configtest
cd /etc/apache2/sites-enabled
sudo ln -s ../sites-available/kubernerdes.lab.conf
sudo systemctl restart apache2

