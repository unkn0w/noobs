#!/bin/bash
# Vault installation script
#
# Author: Sebastian Matuszczyk
#
# Note: Vault requires Go 1.17.2. Script is intended to install the newest version of Golang.


# Removing old version of Go
sudo apt remove golang-go -y

# Getting the newest version of Go
git clone https://github.com/udhos/update-golang
cd update-golang
sudo ./update-golang.sh

# Adding /usr/local/go/bin to the PATH environment variable
export PATH=$PATH:/usr/local/go/bin

# Applying changes
source $HOME/.profile

# Verifying if Go has been updated
go version

# Cleaning
cd ~
rm -rf update-golang

# Setting the GOPATH environment variable
export GOPATH=$(go env GOPATH)

# Cloning the Vault repository from GitHub into GOPATH
mkdir -p $GOPATH/src/github.com/hashicorp && cd $_
git clone https://github.com/hashicorp/vault.git
cd vault

export PATH=$PATH:$GOPATH/bin

# Bootstraping the project
make bootstrap

# Building Vault for local environment
echo -e "\e[1;31m[!]  Uwaga! Istnieje możliwość, że Twoja maszyna nie będzie w stanie zbudować środowiska dla Vaulta przy jej obecnych parametrach.\n\e[1;33mGdyby wyskoczył błąd \e[1;37m'signal: killed'\e[1;33m użyj Amfetaminy w panelu mikrusa."
make dev

# Adding ~/go/bin to PATH in order to make vault work from anywhere
export PATH=$PATH:~/go/bin

# Verifying the installation
vault -h

[ $? -eq 0 ] && echo -e "\e[1;32mVault dodany do PATH, wszystko gotowe!"
