#!/bin/bash
# Script chce_domoticz.sh created by Andrzej "Ferex" Szczepaniak
#Add two new TCP ports in panel and put this ports to this script
#to "Variables" section.
#===== Variables =====
port1=
port2=
#===== DONT' EDIT THIS SECTION!! =====
service_code=$(cat <<EOF
[Unit]
Description=Domoticz Home Automation
After=network.target

[Service]
ExecStart=/opt/domoticz/domoticz -daemon -www $port1 -sslwww $port2
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
)
#===== Checker =====
if [ -z "$port1" ]; then
echo "Wstaw porty TCP (w tym skrypcie w Variables) na których ma działać domoticz"
elif [ -z "$port2" ]; then
echo "Wstaw porty TCP (w tym skrypcie w Variables) na których ma działać domoticz"
else
#===== Script =====
mkdir /opt/domoticz
cd /opt/domoticz
wget --inet4-only https://releases.domoticz.com/releases/release/domoticz_linux_x86_64.tgz
tar -xzvf domoticz_linux_x86_64.tgz
rm domoticz_linux_x86_64.tgz
echo "$service_code" > /etc/systemd/system/domoticz.service
systemctl enable --now domoticz.service
#===== End of script =====
fi
