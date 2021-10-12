#!/bin/bash
# Create OpenVPN server
# Autor: Radoslaw Karasinski


if ! [ -z "$1" ]; then
    port=$1
else
    port="$(( 20000 + $(hostname | grep -o '[0-9]\+') ))"
fi


if lsof -i:$port > /dev/null 2>&1 ; then
    echo "Port $port is already used, try different one"
    exit 1
fi

if ! ls /dev/net/tun > /dev/null 2>&1 ; then
    echo "TUN/TAP not activated!"
    exit 1
fi

apt update
apt install 
