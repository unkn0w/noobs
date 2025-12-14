#!/usr/bin/env bash
# Script chce_domoticz.sh created by Andrzej "Ferex" Szczepaniak
# Script syntax: ./chce_domoticz.sh port_http port_https

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

#===== Checker =====
if [ -z "$1" ]; then
    echo "Poprawna składnia: ./chce_domoticz.sh port_http port_https"
elif [ -z "$2" ]; then
    echo "Poprawna składnia: ./chce_domoticz.sh port_http port_https"
else
#===== Install required packages =====
pkg_update
pkg_install libusb-0.1-4 libcurl3-gnutls tar wget lsb
#===== Script =====
mkdir /opt/domoticz
cd /opt/domoticz || { echo 'Folder nie istnieje'; exit; }
wget --inet4-only https://releases.domoticz.com/releases/release/domoticz_linux_x86_64.tgz
tar -xzvf domoticz_linux_x86_64.tgz
rm domoticz_linux_x86_64.tgz
awk -v cuv1="USERNAME=pi" -v cuv2="USERNAME=root" '{gsub(cuv1,cuv2); print;}' "/opt/domoticz/domoticz.sh" > /tmp/domoticz.sh
awk -v cuv1="-www 8080" -v cuv2="-www $1" '{gsub(cuv1,cuv2); print;}' "/tmp/domoticz.sh" > /tmp/domoticz2.sh
awk -v cuv1="-sslwww 443" -v cuv2="-sslwww $2" '{gsub(cuv1,cuv2); print;}' "/tmp/domoticz2.sh" > /etc/init.d/domoticz.sh
rm /tmp/domotic*.sh
service_enable domoticz.sh
service_start domoticz.sh
#===== End of script =====
fi
