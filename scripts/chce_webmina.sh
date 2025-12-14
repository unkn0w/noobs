#!/usr/bin/env bash
#
# Author: Marcin 'y0rune' Wozniak
#

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

# Check if you are root
require_root

# Configuring tzdata if not exist
[[ ! -f /etc/localtime ]] && ln -fs /usr/share/zoneinfo/Europe/Warsaw /etc/localtime

# Install all missing dependencies
pkg_update
pkg_install curl wget perl libnet-ssleay-perl openssl libauthen-pam-perl \
	libpam-runtime libio-pty-perl apt-show-versions python unzip \
	shared-mime-info

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

# Restart uslugi
service_restart webmin

# Remove tmp file
rm "$webadmin_tmp"
