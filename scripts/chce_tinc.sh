#!/bin/bash
# docker + docker-compose
# Autor: Mikołaj Kamiński (mikolaj-kaminski.com)
# Tutorial: https://www.digitalocean.com/community/tutorials/how-to-install-tinc-and-set-up-a-basic-vpn-on-ubuntu-18-04

if [[ $EUID -ne 0 ]]; then
   echo -e "W celu instalacji tego pakietu potrzebujesz wyzszych uprawnien! Uzyj polecenia \033[1;31msudo ./chce_tinc.sh\033[0m lub zaloguj sie na konto roota i wywolaj skrypt ponownie."
   exit 1
fi

server_name=server_01
network_name=netname
node_ip=10.0.0.1/32
subnet=10.0.0.0/24

apt update
apt install tinc

mkdir -p /etc/tinc/$network_name/hosts

touch /etc/tinc/$network_name/tinc.conf
echo "Name = $server_name" >> /etc/tinc/$network_name/tinc.conf
echo "AddressFamily = ipv4" >> /etc/tinc/$network_name/tinc.conf
echo "Interface = tun0" >> /etc/tinc/$network_name/tinc.conf

public_ip=`dig +short myip.opendns.com @resolver1.opendns.com`

touch /etc/tinc/$network_name/hosts/$server_name
echo "Address = $public_ip" >> /etc/tinc/$network_name/hosts/$server_name
echo "Subnet = $node_ip" >> /etc/tinc/$network_name/hosts/$server_name

tincd -n $network_name -K4096

touch /etc/tinc/$network_name/tinc-up
echo "#!/bin/sh" >>  >> /etc/tinc/$network_name/tinc-up
echo "ip link set \$INTERFACE up" >> /etc/tinc/$network_name/tinc-up
echo "ip addr add $node_ip dev \$INTERFACE" >> /etc/tinc/$network_name/tinc-up
echo "ip route add $subnet dev \$INTERFACE" >> /etc/tinc/$network_name/tinc-up

touch /etc/tinc/$network_name/tinc-down
echo "#!/bin/sh" >>  >> /etc/tinc/$network_name/tinc-down
echo "ip route del $subnet dev \$INTERFACE" >> /etc/tinc/$network_name/tinc-down
echo "ip addr del $node_ip dev \$INTERFACE" >> /etc/tinc/$network_name/tinc-down
echo "ip link set \$INTERFACE down" >> /etc/tinc/$network_name/tinc-down

chmod 755 /etc/tinc/$network_name/tinc-*

ufw allow 655

systemctl enable tinc@$network_name