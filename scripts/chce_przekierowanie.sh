#!/bin/bash
# Autor: Krzysztof Siek
#Przekierowanie portów urządzeń zapiętych po vpn na publiczne port mikrusowe

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

FILE=/root/openvpn-install.sh
if [ -f "$FILE" ]; then
    echo "Openvpn jest zainstalowany."
else
    echo "zainstaluj openvpn(cd /opt/noobs/scripts && ./chce_openvpn.sh)."
    exit
fi


echo "IP i port w sieci VPN które chcesz przekiwerować na świat(np. 10.8.0.2:80)"
read ip_local
echo "port mikrusow na który chcesz przekierować(np. 40048)"
read port_public
echo "Nazwa usługi która ma być wystawiona na świat"
read usluga
echo "mikrusowy port ssh"
read ssh
echo "port na którym stoi openvpn"
read openvpn



ufw allow 22 comment "ssh internal"
ufw allow $ssh comment "ssh external"
ufw allow $openvpn comment "openVPN"
ufw allow $port_public comment "$usluga"
ufw enable


ipconfset=$(cat <<EOF
*nat
:PREROUTING ACCEPT [0:0]
-A PREROUTING -p tcp --dport $port_public -j DNAT --to-destination $ip_local
COMMIT
EOF
)
echo "$ipconfset" >> /etc/ufw/before.rules

echo "wszytko się poprawnie ustawiło"
