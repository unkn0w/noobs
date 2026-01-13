#!/bin/bash
# Autor: Jakub Suchenek (itsanon.xyz)
#
# Przed przysąpieniem do isntalacji, skrypt sprawdza:
# 1. Czy jest uruchomiony jako root
# 2. Czy Tailscale jest już zainstalowany
# 3. Czy curl jest zainstalowany, jeśli nie to go instaluje
# 4. Czy system operacyjny to Ubuntu 20.04 lub nowszy

if [[ $EUID -ne 0 ]]; then
    echo "Ten skrypt musi być uruchomiony jako root."
    exit 1
fi

if command -v tailscale &> /dev/null; then
    echo "Tailscale jest już zainstalowany na tym systemie."
    exit 0
fi

if ! command -v curl &> /dev/null; then
    echo "Breakuje curl, instaluję..."
    apt-get update && apt-get install -y curl
    if [[ $? -ne 0 ]]; then
        echo "Nie udało się zainstalować curl! Zobacz co się stało powyżej."
        exit 1
    fi
fi

if [ ! -f /etc/os-release ]; then
    echo "Nie można wykryć systemu operacyjnego!"
    exit 1
else
    . /etc/os-release
fi

if [ ! "$ID" == "ubuntu" ]; then
    echo "Ten skrypt działa tylko na Ubuntu!"
    exit 1
fi

if [[ "${VERSION_ID:0:2}" -lt 20 ]]; then
    echo "Ten skrypt działa tylko na Ubuntu 20.04 lub nowszym!"
    exit 1
fi

echo "Wykryto instalacje Ubuntu '$UBUNTU_CODENAME'."

echo "Pobieranie klucza GPG Tailscale..."
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/$UBUNTU_CODENAME.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
if [[ $? -ne 0 ]]; then
    echo "Nie udało się pobrać klucza GPG Tailscale!"
    exit 1
fi

echo "Dodawanie repozytorium Tailscale..."
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/$UBUNTU_CODENAME.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
if [[ $? -ne 0 ]]; then
    echo "Nie udało się dodać repozytorium Tailscale!"
    exit 1
fi

echo "Instalowanie Tailscale..."
apt-get update && apt-get install -y tailscale
if [[ $? -ne 0 ]]; then
    echo "Nie udało się zainstalować Tailscale! Zobacz co się stało powyżej."
    exit 1
fi

echo "Weryfikacja instalacji Tailscale..."
if ! command -v tailscale &> /dev/null; then
    echo "Instalacja Tailscale zakończyła się niepowodzeniem!"
    exit 1
fi

echo ""
echo "-----------------------------------------"
echo "Tailscale został pomyślnie zainstalowany!"
echo "-----------------------------------------"
echo "Następne kroki:"
echo "1. Uruchom 'tailscale up' aby połączyć się z siecią Tailscale."
echo "2. Postępuj zgodnie z instrukcjami wyświetlanymi w terminalu."
echo ""

exit 0
