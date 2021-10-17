#!/bin/bash
#
# Author: Marcin 'y0rune' Wozniak
#

# Check if you are root
[[ $EUID != 0 ]]  && { echo "Please run as root" ; exit; }

# Configuring tzdata if not exist
[[ ! -f /etc/localtime ]] && ln -fs /usr/share/zoneinfo/Europe/Warsaw /etc/localtime

# Install all missing dependencies
apt-get update
apt-get install curl wget perl libnet-ssleay-perl openssl libauthen-pam-perl \
	libpam-runtime libio-pty-perl apt-show-versions python unzip \
	shared-mime-info -y

# Values
webadmin_tmp="/tmp/webadmin.deb"
latest=$(curl https://www.webmin.com | grep -Eo 'http://.+.deb')

# Downloading
wget "$latest" -O "$webadmin_tmp"

# Installation
dpkg -i "$webadmin_tmp"

# Configuration
port_number=$(echo -e "30$(hostname | grep -Eo '[0-9]{3}')")
sed -i "s|port=10000|port=$port_number|" /etc/webmin/miniserv.conf
sed -i "s|listen=10000|listen=$port_number|" /etc/webmin/miniserv.conf

# Restart
/etc/init.d/webmin restart

# Remove tmp file
rm "$webadmin_tmp"
