#!/bin/bash

#  Status: Complete/Done
# Purpose: Install Ansible 

sudo apt-get install -y python-software-properties
sudo apt-add-repository -y ppa:ansible/ansible
sudo apt-get update

sudo apt-get install -y ansible
ansible --version

exit 0

