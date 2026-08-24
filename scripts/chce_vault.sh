#!/bin/bash
# Vault installation script
#
# Author: Sebastian Matuszczyk
#


# Install the software-properties-common package in order to add HashiCorp repo
sudo apt install software-properties-common gnupg -y

# Add the HashiCorp GPG key
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add the HashiCorp repo
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update and install
sudo apt-get update && sudo apt-get install vault

# Verifying the installation
if vault -h ; then
    echo -e "\e[1;32mGotowe! \e[1;37mVault zainstalowany."
else
    echo -e "\e[1;31mInstalacja się nie powiodła."
fi