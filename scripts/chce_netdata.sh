#!/bin/bash
# Create netdata instance
# Autor: Radoslaw Karasinski


if ! [ -z "$1" ]; then
    port=$1
else
    echo "Give desired port for netdata: (i.e. 20xxx or 30xxx):"
    read port
fi


echo "Install required packages."
apt install -y curl
echo


# install netdata
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --allow-duplicate-install

# change default netdata port and restart service
sed -i "s|# default port = 19999|default port = $port|" /etc/netdata/netdata.conf
service netdata restart
