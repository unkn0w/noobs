#!/bin/bash
# fail2ban
# Autor: Bartlomiej Szyszko

# Sprawdz uprawnienia przed wykonaniem skryptu instalacyjnego
if [[ $EUID -ne 0 ]]; then
   echo -e "W celu instalacji tego pakietu potrzebujesz wyzszych uprawnien! Uzyj polecenia \033[1;31msudo ./chce_fail2ban.sh\033[0m lub zaloguj sie na konto roota i wywolaj skrypt ponownie."
   exit 1
fi

# Zmienne konfiguracyjne
BAN_TIME=30m
FIND_TIME=3m
MAXRETRY=5
SSH_PORT=

if [[ $SSH_PORT == "" ]]; then
   echo -e "Otworz skrypt i ustaw swoj port ssh ktorego uzywasz do polaczenia z mikrusem"
   exit
fi

apt update
apt install -y fail2ban

# Zatrzymaj usluge fail2ban
systemctl stop fail2ban

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
systemctl enable --now fail2ban
