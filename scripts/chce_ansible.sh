#!/bin/bash
# Author: Piotr Koska

# Załadowanie funkcji
. ./functions/function_apt.sh

if [[ $EUID -ne 0 ]]; then
   echo "Ten skrypt musi być uruchamiany jako root - użyj np sudo $0" 
   exit 1
fi

# Aktualizacja listy pakietów
apt_update

# Instalacja pakietu software-properties-common
apt_install_software software-properties-common

# Dodanie repo ppa:ansible/ansible
apt_add_repository "ppa:ansible/ansible"

# Instalacja pakietu ansible
apt_install_software ansible

# Wydruk w CLI wersji naszego ansible
/usr/bin/anisble --version