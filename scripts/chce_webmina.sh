#!/bin/bash
#
# Author: Marcin 'y0rune' Wozniak
# Edited and modified by: Andrzej 'Ferex' Szczepaniak
#

# Check if you are root
[[ $EUID != 0 ]]  && { echo "Please run as root" ; exit; }

# Configuring tzdata if not exist
[[ ! -f /etc/localtime ]] && ln -fs /usr/share/zoneinfo/Europe/Warsaw /etc/localtime

curl -o webmin-setup-repo.sh https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repo.sh
bash webmin-setup-repo.sh -f
apt install webmin --install-recommends -y

# Configuration
port_number=$(echo -e "30$(hostname | grep -Eo '[0-9]{3}')")
sed -i "s|port=10000|port=$port_number|" /etc/webmin/miniserv.conf
sed -i "s|listen=10000|listen=$port_number|" /etc/webmin/miniserv.conf

# Restart
systemctl restart webmin
