#!/bin/bash
# fail2ban
# Autor: Bartlomiej Szyszko
# Edycja: ThomasMaven

# Sprawdz uprawnienia przed wykonaniem skryptu instalacyjnego
if [[ $EUID -ne 0 ]]; then
   echo -e "W celu instalacji tego pakietu potrzebujesz wyzszych uprawnien! Uzyj polecenia \033[1;31msudo ./chce_fail2ban.sh\033[0m lub zaloguj sie na konto roota i wywolaj skrypt ponownie."
   exit 1
fi

# Domyslne zmienne konfiguracyjne
BAN_TIME=30m
FIND_TIME=3m
MAXRETRY=5
SSH_PORT=

usage() {
   echo "Uzycie: sudo $0 -p SSH_PORT [-b BAN_TIME] [-f FIND_TIME] [-m MAXRETRY]"
   echo ""
   echo "  -p PORT    Port SSH (wymagany)"
   echo "  -b TIME    Czas bana (domyslnie: 30m)"
   echo "  -f TIME    Czas okna monitorowania (domyslnie: 3m)"
   echo "  -m NUM     Maksymalna liczba prob (domyslnie: 5)"
   echo ""
   echo "Przyklad: sudo $0 -p 2222 -b 1h -f 5m -m 3"
   exit 1
}

while getopts "p:b:f:m:h" opt; do
   case $opt in
      p) SSH_PORT="$OPTARG" ;;
      b) BAN_TIME="$OPTARG" ;;
      f) FIND_TIME="$OPTARG" ;;
      m) MAXRETRY="$OPTARG" ;;
      h) usage ;;
      *) usage ;;
   esac
done

apt update
apt install -y fail2ban

# Zatrzymaj usluge fail2ban
systemctl stop fail2ban

# Lokalny plik konfiguracyjny
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

echo -e "\033[1;32mFail2ban zainstalowany i uruchomiony!\033[0m"
