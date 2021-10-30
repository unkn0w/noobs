#!/bin/bash
#
# firewall
# Authors: Kacper Adamczak
# Version: 1.0
#

sudo apt update
sudo apt install ufw

sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow OpenSSH;
sudo ufw allow ssh;

host=$(hostname)
host=${host:1}

port1=$((10000+host))
port2=$((20000+host))
port3=$((30000+host))

if sudo ufw allow $port1 ; then
    echo "Do regul firewalla poprawnie dodano port $port1"
else
    echo "Blad dodawania $port1 do regul firewalla"
fi

if sudo ufw allow $port2 ; then
    echo "Do regul firewalla poprawnie dodano port $port2"
else
    echo "Blad dodawania $port2 do regul firewalla"
fi

if sudo ufw allow $port3 ; then
    echo "Do regul firewalla poprawnie dodano port $port3"
else
    echo "Blad dodawania $port3 do regul firewalla"
fi

sudo ufw enable

echo "Firewall został włączony"

ipset create port_scanners hash:ip family inet hashsize 32768 maxelem 65536 timeout 600
ipset create scanned_ports hash:ip,port family inet hashsize 32768 maxelem 65536 timeout 60

iptables -A INPUT -m state --state INVALID -j DROP
iptables -A INPUT -m state --state NEW -m set ! --match-set scanned_ports src,dst -m hashlimit --hashlimit-above 1/hour --hashlimit-burst 5 --hashlimit-mode srcip --hashlimit-name portscan --hashlimit-htable-expire 10000 -j SET --add-set port_scanners src --exist
iptables -A INPUT -m state --state NEW -m set --match-set port_scanners src -j DROP
iptables -A INPUT -m state --state NEW -j SET --add-set scanned_ports src,dst