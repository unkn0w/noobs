#!/bin/bash
# fail2ban
# Autor: Bartlomiej Szyszko
# Edycja: ThomasMaven, lakusz
# Poprawki: walidacja portu, weryfikacja startu, enabled=true, IPv6, Pusher

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

# Walidacja portu SSH
if [[ -z "$SSH_PORT" ]]; then
   echo -e "\033[1;31mBlad:\033[0m Nie podano portu SSH. Uzyj flagi -p PORT."
   echo ""
   usage
fi

if ! [[ "$SSH_PORT" =~ ^[0-9]+$ ]] || [[ "$SSH_PORT" -lt 1 ]] || [[ "$SSH_PORT" -gt 65535 ]]; then
   echo -e "\033[1;31mBlad:\033[0m Port SSH musi byc liczba z zakresu 1-65535."
   exit 1
fi

apt update
apt install -y fail2ban

# Zatrzymaj usluge fail2ban
systemctl stop fail2ban

# Lokalny plik konfiguracyjny
config=$(cat <<EOF
[DEFAULT]
ignoreip = 127.0.0.1 ::1
bantime  = $BAN_TIME
findtime = $FIND_TIME
maxretry = $MAXRETRY

[sshd]
enabled  = true
port     = $SSH_PORT
logpath  = %(sshd_log)s
backend  = %(sshd_backend)s
action   = iptables-multiport
           pusher-notify
EOF
)

rm /etc/fail2ban/jail.local 2> /dev/null
echo "$config" >> /etc/fail2ban/jail.local

# Konfiguracja akcji Pushera
cat > /etc/fail2ban/action.d/pusher-notify.conf <<'EOF'
[Definition]
actionban   = echo "Fail2ban: zbanowano <ip> na porcie <port> po <failures> nieudanych probach logowania." | pusher fail2ban_ban
actionunban = echo "Fail2ban: odbanowano <ip>" | pusher fail2ban_unban
EOF

# Uruchomienie uslugi
systemctl enable --now fail2ban

# Weryfikacja czy fail2ban wystartował
sleep 2
if systemctl is-active --quiet fail2ban; then
   echo -e "\033[1;32mFail2ban zainstalowany i uruchomiony!\033[0m"
   echo ""
   fail2ban-client status sshd
else
   echo -e "\033[1;31mBlad:\033[0m Fail2ban nie uruchomil sie poprawnie. Sprawdz logi: journalctl -xe -u fail2ban"
   exit 1
fi
