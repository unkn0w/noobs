#!/usr/bin/env bash
# Create OpenVPN server
# Autor: Radoslaw Karasinski
# Update: Dawid Pospiech, Jakub 'unknow' Mrugalski
# Usage: you can pass --port and/or --host variables to script, otherwise
# defaults will be choosen.

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

# Helper to keep essential code tight
function get-hostname
{
    # Get first part of hostname from hostname -f
    local current_fqdn=$(hostname -f)
    local hostname_part=$(echo "$current_fqdn" | cut -f1 -d '.')

    # If hostname has 4 characters, use old method with curl
    if [ ${#hostname_part} -eq 4 ]; then
        FQDN="$(curl -s https://ipinfo.io/hostname)"

        if [[ "$FQDN" =~ ^.*[.]mikr[.]us$ ]]; then
            host_part=$(echo "$FQDN" | cut -f1 -d '.' )
            host="${host_part}.mikr.us"
            echo "$host_part"
            export host="$host"

        elif [[ ! "$FQDN" =~ ^.*[.]mikr[.]us ]]; then
            echo
            echo "Valid hostname is still not known : ( "
            echo
            echo "You can set it by yourself with command:"
            echo "export host=<replace with server name eg srv100>"
            echo
            echo "example connection command:"
            echo "ssh root@srv100.mikr.us -p12333"
            echo ""
            echo "export host='srv100'"
            echo "After that you can try rerun $0"
            exit 1
        fi
    else
        # Use hostname from hostname -f and build domain as NAZWA.mikrus.xyz
        host="${hostname_part}.mikrus.xyz"
        echo "$hostname_part"
        export host="$host"
    fi
}

# some bash magic: https://brianchildress.co/named-parameters-in-bash/
while [ $# -gt 0 ]; do
    if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare "$param"="$2"
    fi
  shift
done

if [[ ! -c /dev/net/tun ]]; then
    echo "TUN/TAP not activated!"
    exit 1
fi

if [[ -z "$port" ]]; then
    port="$(( 20000 + $(hostname | grep -o '[0-9]\+') ))"
fi

if lsof -i:$port > /dev/null 2>&1 ; then
    echo "Port $port is already used, try different one"
    exit 1
fi

get-hostname

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
