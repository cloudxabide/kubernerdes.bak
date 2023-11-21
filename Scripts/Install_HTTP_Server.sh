#!/bin/bash

#NOTE #NOTE #NOTE #NOTE 
# THIS MAY BE UNNECESSARY AND POSSIBLY WORSE, MAKE EKS-A NOT WORK


sudo apt install -y apache2
sudo systemctl enable apache2

sudo ufw app list
sudo ufw allow 'Apache'
sudo ufw status





exit 0
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

