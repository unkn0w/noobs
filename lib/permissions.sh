#!/bin/bash
# Sprawdzanie uprawnien i walidacja - noobs_lib modul
[[ -n "${_NOOBS_PERMISSIONS_LOADED:-}" ]] && return 0
readonly _NOOBS_PERMISSIONS_LOADED=1

check_root() {
    [[ $EUID -eq 0 ]]
}

require_root() {
    if [[ $EUID -ne 0 ]]; then
        msg_error "Ten skrypt wymaga uprawnien administratora."
        msg_error "Uruchom jako root lub uzyj: sudo $0"
        exit 1
    fi
}

require_non_root() {
    if [[ $EUID -eq 0 ]]; then
        msg_error "Uruchamianie jako root jest niebezpieczne. Uzyj zwyklego uzytkownika."
        exit 1
    fi
}

require_sudo() {
    if ! sudo --validate 2>/dev/null; then
        msg_error "Nie masz uprawnien do uruchamiania komend jako root."
        msg_error "Dodaj '$USER' do grupy 'sudoers'."
        exit 1
    fi
}

command_exists() {
    command -v "$1" &>/dev/null
}

file_exists() {
    [[ -f "$1" ]]
}

dir_exists() {
    [[ -d "$1" ]]
}

is_port_valid() {
    local port="$1"
    [[ "$port" =~ ^[0-9]+$ ]] && (( port >= 1 && port <= 65535 ))
}

is_port_free() {
    local port="$1"
    ! netstat -tuln 2>/dev/null | grep -q ":$port " && \
    ! ss -tuln 2>/dev/null | grep -q ":$port "
}

check_internet() {
    if ping -c 1 -W 3 8.8.8.8 &>/dev/null || \
       ping -c 1 -W 3 1.1.1.1 &>/dev/null; then
        return 0
    else
        msg_error "Brak polaczenia z internetem."
        return 1
    fi
}

user_exists() {
    id "$1" &>/dev/null
}

group_exists() {
    getent group "$1" &>/dev/null
}
