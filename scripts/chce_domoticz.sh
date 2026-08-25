#!/bin/bash
# Script chce_domoticz.sh created by Andrzej "Ferex" Szczepaniak
# Script syntax: ./chce_domoticz.sh port_http port_https
#===== Checker =====
if [ -z "$1" ]; then
    echo "Poprawna składnia: ./chce_domoticz.sh port_http port_https"
elif [ -z "$2" ]; then
    echo "Poprawna składnia: ./chce_domoticz.sh port_http port_https"
else
#===== Install required packages =====
apt update
apt install libusb-0.1-4 libcurl3-gnutls tar wget curl lsb-release -y || { echo "Instalacja pakietów nie powiodła się."; exit 1; }
#===== Script =====
mkdir -p /opt/domoticz
cd /opt/domoticz || { echo 'Folder nie istnieje'; exit; }

# releases.domoticz.com/releases/release/ nie zawiera już domoticz_linux_x86_64.tgz - pobieramy
# najnowsze wydanie bezpośrednio z GitHub Releases.
domoticz_url=$(curl -s https://api.github.com/repos/domoticz/domoticz/releases/latest | grep -oE '"browser_download_url":\s*"[^"]*domoticz_linux_x86_64\.tgz"' | grep -oE 'https://[^"]+')
if [ -z "$domoticz_url" ]; then
    echo "Nie udało się ustalić adresu najnowszego wydania Domoticz z GitHub API." >&2
    exit 1
fi
if ! wget --inet4-only "$domoticz_url" -O domoticz_linux_x86_64.tgz; then
    echo "Pobieranie Domoticz nie powiodło się (URL: $domoticz_url)." >&2
    exit 1
fi
if ! tar -xzvf domoticz_linux_x86_64.tgz; then
    echo "Rozpakowanie archiwum Domoticz nie powiodło się." >&2
    exit 1
fi
rm domoticz_linux_x86_64.tgz

if [ ! -f /opt/domoticz/domoticz.sh ]; then
    echo "Brak domoticz.sh po rozpakowaniu - instalacja przerwana." >&2
    exit 1
fi
awk -v cuv1="USERNAME=pi" -v cuv2="USERNAME=root" '{gsub(cuv1,cuv2); print;}' "/opt/domoticz/domoticz.sh" > /tmp/domoticz.sh 
awk -v cuv1="-www 8080" -v cuv2="-www $1" '{gsub(cuv1,cuv2); print;}' "/tmp/domoticz.sh" > /tmp/domoticz2.sh 
awk -v cuv1="-sslwww 443" -v cuv2="-sslwww $2" '{gsub(cuv1,cuv2); print;}' "/tmp/domoticz2.sh" > /etc/init.d/domoticz.sh
rm /tmp/domotic*.sh
systemctl enable domoticz.sh
/etc/init.d/domoticz.sh start
#===== End of script =====
fi
