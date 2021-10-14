#!/bin/bash
# Create OpenVPN server
# Autor: Radoslaw Karasinski


# some bash magic: https://brianchildress.co/named-parameters-in-bash/
while [ $# -gt 0 ]; do
    if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare "$param"="$2"
    fi
  shift
done

if ! ls /dev/net/tun > /dev/null 2>&1 ; then
    echo "TUN/TAP not activated!"
    exit 1
fi

if [ -z "$port" ]; then
    port="$(( 20000 + $(hostname | grep -o '[0-9]\+') ))"
fi

if lsof -i:$port > /dev/null 2>&1 ; then
    echo "Port $port is already used, try different one"
    exit 1
fi

if [ -z "$host" ]; then
    key="$( hostname | grep -o '[^0-9]\+' )"
    declare -A hosts
    hosts["a"]="srv03"
    hosts["b"]="srv04"
    hosts["e"]="srv07"
    hosts["f"]="srv08"
    hosts["g"]="srv09"
    hosts["h"]="srv10"
    hosts["q"]="mini01"
    host="${hosts[$key]}"
    if [ -z "$host" ]; then
        echo "Server hostname not known for key $key"
        exit 1
    fi
    host="$host.mikr.us"
fi


echo "Using hostname $host and port $port"

#apt update
#apt install
