#!/bin/bash
# FTP installation script
# Authors: Mariusz 'maniek205' Kowalski
# Edycja: pZ: Paweł 'pauluZ' Szczepanek

err() {
    echo -e "\e[0;31m[!] \e[1;31m$1\e[0;0m";
    exit 1;
}

[ "$EUID" -eq 0 ] && { err "Uruchamianie jako root jest niebezpieczne. Uzyj zwyklego uzytkownika."; }
sudo --validate || { err "Nie masz uprawnien do uruchamiania komend jako root - dodaj '$USER' do grupy 'sudoers'."; }

hostname=$(hostname)
# pZ: Jesli serwer ma nazwe 'xxxxxxx123' (cyfry na koncu moga byc dowolne) to pobieram trzy ostatnie cyfry
listen_port=20${hostname:(-3)}
listen_port30=30${hostname:(-3)}
vsftpd_conf=/etc/vsftpd.conf

if (sudo lsof -i:"${listen_port}" | grep -q PID) ; then
    echo "Port $listen_port in use trying: $listen_port30"
    if (sudo lsof -i:"${listen_port30}" | grep -q PID) ; then
        err "Port $listen_port30 in use error. All external ports are in use. Please release external port $listen_port or $listen_port30."
        exit 1
    else
        listen_port=${listen_port30}
    fi
fi
echo "Using port: $listen_port"

sudo apt update
sudo apt install -y vsftpd

sudo sed -i 's/#write_enable=YES/write_enable=YES/g' ${vsftpd_conf}

# pZ: podmiana lub dodanie linii 'listen_port=xxx' do /etc/vsftpd.conf (echo nie dziala dla sudo)
if (grep -q "^listen_port=.*" ${vsftpd_conf}) ; then
    sudo sed -i 's/^listen_port=.*/listen_port='"$listen_port"'/g' ${vsftpd_conf}
else
    sudo sed -i '$s/$/\nlisten_port='"$listen_port"'/' ${vsftpd_conf}
fi

sudo systemctl enable vsftpd
sudo systemctl restart vsftpd

echo "FTP server has been installed. Use your credentials to log in.
Server IP: srvX.mikr.us (change X to your server number)
Port: $listen_port"

# pZ: sprawdzenie co nasluchuje na roznych portach:
# /usr/bin/ss -tuln
# -t, --tcp           display only TCP sockets
# -u, --udp           display only UDP sockets
# -l, --listening     display listening sockets
# -n, --numeric       don't resolve service names (aby nie zamienial portow na uslugi np. :22 na ssh)
# EOF
