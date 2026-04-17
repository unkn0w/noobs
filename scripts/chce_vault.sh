#!/bin/bash
# Vault installation script
#
# Author: Sebastian Matuszczyk
#


# Add the HashiCorp GPG key
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

# Install the software-properties-common package in order to add HashiCorp repo
sudo apt install software-properties-common -y

# Add the HashiCorp repo
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

# Update and install
sudo apt-get update && sudo apt-get install vault

# Verifying the installation
if vault -h ; then
    echo -e "\e[1;32mGotowe! \e[1;37mVault zainstalowany."
else
    echo -e "\e[1;31mInstalacja się nie powiodła."
fi