#!/usr/bin/env bash
# Instalacja przydatnych programow
# Autor: Maciej Loper

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

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
    pkg_install ${!pkg}
}

[ "$#" -lt 1 ] && usage

# sprawdz uprawnienia sudo
require_sudo

refreshed=false

for arg in "$@"; do
    # sprawdz parametr
    echo "$AVAILABLE" | grep -q "$arg" || { usage; }
    # aktualizuj tylko raz
    $refreshed || pkg_update
    # zainstaluj paczke nr X
    install_pX "$arg"
    echo
done
