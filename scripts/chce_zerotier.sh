#!/usr/bin/env bash
# Skrypt instaluje i laczy sie z sieca ZeroTier
# Autor: Maciej Loper @2021-10

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

SLEEP=5
TIMEOUT=60

usage (){
    echo "Uzycie: $0 <network_id>";
    echo "Jesli nie masz konta, zarejestruj sie na: https://www.zerotier.com";
    exit 3;
}

# start -----------------------------
[ "$#" -lt 1 ] && usage

[ "$EUID" -eq 0 ] && { msg_error "Uruchamianie jako root jest niebezpieczne. Uzyj zwyklego uzytkownika."; exit 1; }
sudo --validate || { msg_error "Nie masz uprawnien do uruchamiania komend jako root - dodaj '$USER' do grupy 'sudoers'."; exit 1; }

net="$1"

msg_info "pobranie i instalacja z oficjalnego skryptu"
dpkg --status zerotier-one &>/dev/null || {
    curl -s https://install.zerotier.com | sudo bash
}

msg_info "uruchomienie (+ dodanie do boot'a)"
sudo systemctl enable --now zerotier-one.service &>/dev/null

msg_info "dolaczanie do sieci $net"
sudo zerotier-cli join "$net"

id="$(sudo zerotier-cli info | cut -d" " -f3)"
msg_info "twoj ID w sieci to: $id"

msg_info "oczekiwanie na polaczenie..."

counter=0
while true; do
    echo -n "."
    found="$(ip -br -c=never addr show | grep 'ztbt' | awk -F" " '{print $3}' | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")"
    [ -n "$found" ] && break
    sleep $SLEEP
    counter=$((counter+1))
    [ "$counter" -ge $TIMEOUT ] && { echo; msg_error "brak polaczenia"; exit 5; }
done

echo
msg_ok "Twoj IP w sieci ZeroTier to: $found"
