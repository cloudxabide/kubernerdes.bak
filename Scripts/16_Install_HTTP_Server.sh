#!/bin/bash

#     Purpose: deploy an HTTP/S Server (running on port 8080)
#        Date:
#      Status:
# Assumptions:

# Install the Apache2 packages
sudo apt install -y apache2 php libapache2-mod-php php-mysql

# Change the port apache2 will listen on
sudo sed -i -e 's/80/8080/g' /etc/apache2/ports.conf
sudo sed -i -e 's/80/8080/g' /etc/apache2/sites-enabled/000-default.conf
sudo systemctl enable apache2 --now

firewall_update() {
sudo ufw app list
sudo ufw allow in 'Apache'
sudo ufw status
sudo systemctl enable --now ufw
}

# Update the index page to be a dynamic version run in PHP
sudo curl -o /var/www/html/index.php https://raw.githubusercontent.com/cloudxabide/kubernerdes/main/Files/index.php
sudo chown -R www-data:www-data /var/www
exit 0

# NOTE:  you can now browse http://10.10.12.10:8080/


