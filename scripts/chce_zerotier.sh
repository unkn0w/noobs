#!/bin/bash
# Skrypt stawia najnowszą wersję VSCode Server
# Autor: Maciej Loper @2021-10

SLEEP=5
TIMEOUT=60

status() {
    echo -e "\e[0;32m[x] \e[1;32m$1\e[0;0m"
}

err() {
    echo -e "\e[0;31m[!] \e[1;31m$1\e[0;0m";
    exit 1;
}

usage (){
    echo "Uzycie: $0 <network_id>";
    exit 3;
}

# start -----------------------------
[ "$#" -lt 1 ] && usage

[ "$EUID" -eq 0 ] && { err "Uruchamianie jako root jest niebezpieczne. Uzyj zwyklego uzytkownika."; }
sudo --validate || { err "Nie masz uprawnien do uruchamiania komend jako root - dodaj '$USER' do grupy 'sudoers'."; }

net="$1"

status "pobranie i instalacja z oficjalnego skryptu"
dpkg --status zerotier-one &>/dev/null || {
    curl -s https://install.zerotier.com | sudo bash
}

status "uruchomienie (+ dodanie do boot'a)"
sudo systemctl enable --now zerotier-one.service &>/dev/null

status "dolaczanie do sieci $net"
sudo zerotier-cli join "$net"

id="$(sudo zerotier-cli info | cut -d" " -f3)"
status "twoj ID w sieci to: $id"

status "oczekiwanie na polaczenie..."

counter=0
while true; do
    echo -n "."
    found="$(ip -br -c=never addr show | grep 'ztbt' | awk -F" " '{print $3}' | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")"
    [ -n "$found" ] && break
    sleep $SLEEP
    counter=$((counter+1))
    [ "$counter" -ge $TIMEOUT ] && { echo; err "brak polaczenia"; exit 5; }
done

echo
status "Twoj IP w sieci ZeroTier to: $found"