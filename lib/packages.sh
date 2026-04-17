#!/bin/bash
# Menedzer pakietow - noobs_lib modul
[[ -n "${_NOOBS_PACKAGES_LOADED:-}" ]] && return 0
readonly _NOOBS_PACKAGES_LOADED=1

_NOOBS_PKG_MANAGER=""

detect_package_manager() {
    if [[ -n "$_NOOBS_PKG_MANAGER" ]]; then
        echo "$_NOOBS_PKG_MANAGER"
        return 0
    fi

    if command -v apt &>/dev/null; then
        _NOOBS_PKG_MANAGER="apt"
    elif command -v dnf &>/dev/null; then
        _NOOBS_PKG_MANAGER="dnf"
    elif command -v yum &>/dev/null; then
        _NOOBS_PKG_MANAGER="yum"
    elif command -v pacman &>/dev/null; then
        _NOOBS_PKG_MANAGER="pacman"
    else
        msg_error "Nie znaleziono obslugiwanego menedzera pakietow."
        return 1
    fi

    echo "$_NOOBS_PKG_MANAGER"
}

pkg_update() {
    local pm
    pm=$(detect_package_manager) || return 1

    msg_info "Aktualizowanie listy pakietow..."
    case "$pm" in
        apt)    sudo apt update ;;
        dnf)    sudo dnf check-update || true ;;
        yum)    sudo yum check-update || true ;;
        pacman) sudo pacman -Sy ;;
    esac
    msg_ok "Lista pakietow zaktualizowana."
}

pkg_install() {
    local pm
    pm=$(detect_package_manager) || return 1

    [[ $# -eq 0 ]] && { msg_error "Nie podano pakietow do instalacji."; return 1; }

    msg_info "Instalowanie pakietow: $*"
    case "$pm" in
        apt)    sudo apt install -y "$@" ;;
        dnf)    sudo dnf install -y "$@" ;;
        yum)    sudo yum install -y "$@" ;;
        pacman) sudo pacman -S --noconfirm "$@" ;;
    esac
}

pkg_remove() {
    local pm
    pm=$(detect_package_manager) || return 1

    [[ -z "$1" ]] && { msg_error "Nie podano pakietu do usuniecia."; return 1; }

    msg_info "Usuwanie pakietu: $1"
    case "$pm" in
        apt)    sudo apt remove -y "$1" ;;
        dnf)    sudo dnf remove -y "$1" ;;
        yum)    sudo yum remove -y "$1" ;;
        pacman) sudo pacman -R --noconfirm "$1" ;;
    esac
}

pkg_is_installed() {
    local pm
    pm=$(detect_package_manager) || return 1

    case "$pm" in
        apt)    dpkg -s "$1" &>/dev/null ;;
        dnf|yum) rpm -q "$1" &>/dev/null ;;
        pacman) pacman -Q "$1" &>/dev/null ;;
    esac
}

pkg_install_if_missing() {
    local pkg="$1"
    if ! pkg_is_installed "$pkg"; then
        msg_info "Pakiet '$pkg' nie jest zainstalowany. Instaluje..."
        pkg_install "$pkg"
    else
        msg_debug "Pakiet '$pkg' jest juz zainstalowany."
    fi
}
