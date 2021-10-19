#!/bin/bash
# Script chce_domoticz.sh created by Andrzej "Ferex" Szczepaniak
# Script syntax: ./chce_domoticz.sh port_http port_https
#===== DONT' EDIT THIS SECTION!! =====
service_code=$(cat <<EOF
[Unit]
Description=Domoticz Home Automation
After=network.target

[Service]
ExecStart=/opt/domoticz/domoticz -daemon -www $1 -sslwww $2
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
)
#===== Checker =====
if [ -z "$1" ]; then
    echo "Poprawna składnia: ./chce_domoticz.sh port_http port_https"
elif [ -z "$2" ]; then
    echo "Poprawna składnia: ./chce_domoticz.sh port_http port_https"
else
#===== Install required packages =====
apt update
apt install libusb-0.1-4 libcurl3-gnutls tar wget lsb -y
#===== Script =====
mkdir /opt/domoticz
cd /opt/domoticz || { echo 'Folder nie istnieje'; exit; }
wget --inet4-only https://releases.domoticz.com/releases/release/domoticz_linux_x86_64.tgz
tar -xzvf domoticz_linux_x86_64.tgz
rm domoticz_linux_x86_64.tgz
echo "$service_code" > /etc/systemd/system/domoticz.service
systemctl enable --now domoticz.service
#===== End of script =====
fi
