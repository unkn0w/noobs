#!/bin/bash
# Create OpenVPN server
# Autor: Radoslaw Karasinski
# Usage: you can pass --port and/or --host variables to script, otherwise
# defaults will be choosen.

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
    hosts["x"]="maluch"
    host="${hosts[$key]}"
    if [ -z "$host" ]; then
        echo "Server hostname not known for key $key"
        exit 1
    fi
    host="$host.mikr.us"
fi


echo "Using hostname $host and port $port for configuration."

echo "Download configuration script and run it."
curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
chmod +x openvpn-install.sh

export AUTO_INSTALL=y
export APPROVE_INSTALL=y
export APPROVE_IP=y
export ENDPOINT="$host"
export IPV6_SUPPORT=n
export PORT_CHOICE=2
export PORT=$port
export PROTOCOL_CHOICE=1
export DNS=1
export COMPRESSION_ENABLED=n
export CUSTOMIZE_ENC=n
export PASS=1

./openvpn-install.sh

mv openvpn-install.sh ~/openvpn-install.sh
echo "In order to add new clients, run ~/openvpn-install.sh"
