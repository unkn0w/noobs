#!/bin/bash
# Instalacja przydatnych programow
# Autor: Maciej Loper

PKG1="vim tree multitail"
PKG2="unattended-upgrades ncdu silversearcher-ag"
PKG3="ansible ranger logwatch python3-pip fish nmon"
AVAILABLE="1 2 3"

# debug
# e="echo"; set -x

# pokaz dostepne opcje
usage() {
    echo "Uzycie: $0 <1 2 ...>"
    echo "1: $PKG1"
    echo "2: $PKG2"
    echo "3: $PKG3"
    exit 1
}

# zainstaluj paczke nr X
install_pX() {
    pkg="PKG${1}"
    sudo apt install -y ${!pkg}
}

# aktualizuj repozytoria
update_repo() {
    sudo apt update
}

[ "$#" -lt 1 ] && usage

# sprawdz uprawnienia sudo
sudo -l &>/dev/null || { echo "Nie masz uprawnien do uruchamiania komend jako root - dodaj '$USER' do grupy 'sudoers'."; }

refreshed=false

for arg in "$@"; do
    # sprawdz parametr
    echo "$AVAILABLE" | grep -q "$arg" || { usage; }
    # aktualizuj tylko raz
    $refreshed || update_repo
    # zainstaluj paczke nr X
    install_pX "$arg"
    echo
done