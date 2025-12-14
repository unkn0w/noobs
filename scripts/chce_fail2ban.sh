#!/bin/bash
# fail2ban
# Autor: Bartlomiej Szyszko

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

# Sprawdz uprawnienia przed wykonaniem skryptu instalacyjnego
require_root

# Zmienne konfiguracyjne
BAN_TIME=30m
FIND_TIME=3m
MAXRETRY=5
SSH_PORT=

if [[ $SSH_PORT == "" ]]; then
   echo -e "Otworz skrypt i ustaw swoj port ssh ktorego uzywasz do polaczenia z mikrusem"
   exit
fi

pkg_update
pkg_install fail2ban

# Zatrzymaj usluge fail2ban
service_stop fail2ban

# Lokalny plik z konfiguracyjny
config=$(cat <<EOF
[DEFAULT]
ignoreip = 127.0.0.1
bantime  = $BAN_TIME
findtime = $FIND_TIME
maxretry = $MAXRETRY

[sshd]
port = $SSH_PORT
logpath = %(sshd_log)s
backend = %(sshd_backend)s
EOF
)

rm /etc/fail2ban/jail.local 2> /dev/null
echo "$config" >> /etc/fail2ban/jail.local

# Uruchomienie uslugi
service_enable_now fail2ban
