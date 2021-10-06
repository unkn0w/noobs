#!/usr/bin/env bash
# Tworzenie nowego uzytkownika, z dostepem do sudo i kopia authorized_keys
# Autor: Radoslaw Karasinski, Grzegorz Ćwikliński


# Kolorki, zeby bylo ladniej :)
if [[ -t 1 ]]
then
    ncolors="$(tput colors)"
    if [[ -n "${ncolors}" ]] && [[ "${ncolors}" -ge 8 ]]
    then
        C_RED='\e[1;31m'
        C_PURPLE='\e[1;35m'
        C_YELLOW='\e[1;33m'
        C_GREEN='\e[1;32m'
        C_BLUE='\e[1;34m'
        C_CLEAR='\e[0m'
    fi
fi

_info() { echo -e "${C_GREEN}LOG [INFO] -> $*${C_CLEAR}" >&2; }
_debug() { echo -e "${C_BLUE}LOG [DEBUG] -> $*${C_CLEAR}" >&2; }
_warn() { echo -e "${C_YELLOW}LOG [WARNING] -> $*${C_CLEAR}" >&2;}
_error() { echo -e "${C_RED}LOG [ERROR] -> $*${C_CLEAR}" >&2; exit 1; }
_source() { echo "$*"; }



_check_if_user_exits() {
    given_user=$1
    if sudo id "${given_user}" &>/dev/null; then
            _error "Użytkownik ${given_user} już istnieje!"
    fi
}

_check_if_user_blank() {
    given_user=$1
    if [ -z "$1" ]; then
        _error "Nie podałeś nazwy użytkownia!"
fi
}

if ! [ -z "$1" ]; then
    username=$1
else
    _info "Podaj nazwę użytkownika:"
    read username
fi

_check_if_user_blank $username
_check_if_user_exits $username

# stworz nowego uzytkownika
sudo adduser $username

# dodaj nowego uzytkownika do sudo
sudo usermod -aG sudo $username

ssh_dir="/home/$username/.ssh"

# stworz folder na ustawienia ssh oraz ustaw odpowiednie prawa
sudo mkdir -p $ssh_dir
sudo chmod 700 $ssh_dir

# stworz authorized_keys oraz ustaw odpowiednie prawa
sudo touch $ssh_dir/authorized_keys
sudo chmod 600 $ssh_dir/authorized_keys

# zmien wlasciciela folderu i plikow
sudo chown -R $username:$username $ssh_dir

# skopiuj klucze obecnego uzytkownika do nowo stworzoneg
cat ~/.ssh/authorized_keys | sudo tee -a $ssh_dir/authorized_keys >/dev/null

_info "Pomyślnie stworzono użytkownia ${username}."
