#!/bin/bash
# przydatne narzedzia: htop,
# Autor: Kuba 'kubaeror' Konat

# Sprawdz uprawnienia
if [[ $EUID -ne 0 ]]; then
   echo -e "W celu instalacji tego pakietu potrzebujesz uprawnien roota Uzyj polecenia \033[1;31msudo ./chce_narzedzia.sh\033[0m "
   exit 1
fi

apt update

# tmux
sudo apt install tmux

# htop
sudo apt install htop

# multitail
sudo apt install multitail