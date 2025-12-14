#!/bin/bash
# Create netdata instance
# Autor: Radoslaw Karasinski
# Supported parameters:
#  --port PORT_NUMBER,
#  --token TOKEN
#  --rooms ROOM
#  --url URL
#  --duplicate

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

# some bash magic: https://brianchildress.co/named-parameters-in-bash/
while [ $# -gt 0 ]; do
    if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare "$param"="$2"
    fi
  shift
done


if [ -z "$port" ]; then
    echo "Give desired port for netdata: (i.e. 20xxx or 30xxx):"
    read -r port
fi

extra_args=()

if [ -n "$token" ]; then
    extra_args+=(--claim-token "$token")
fi

if [ -n "$rooms" ]; then
    extra_args+=(--claim-rooms "$rooms")
fi

if [ -n "$url" ]; then
    extra_args+=(--claim-url "$url")
fi

if [ -n "$duplicate" ]; then
    extra_args+=(--allow-duplicate-install)
fi

echo "Install required packages."
pkg_install curl
echo

# install netdata
bash <(curl -Ss https://my-netdata.io/kickstart.sh) "${extra_args[@]}"

# change default netdata port and restart service
sed -i "s|# default port = 19999|default port = $port|" /etc/netdata/netdata.conf
service_restart netdata
