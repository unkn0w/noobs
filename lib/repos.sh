#!/bin/bash
# Zarzadzanie repozytoriami - noobs_lib modul
[[ -n "${_NOOBS_REPOS_LOADED:-}" ]] && return 0
readonly _NOOBS_REPOS_LOADED=1

# Uzycie: import_gpg_key <key_url> [keyring_name]
import_gpg_key() {
    local key_url="$1"
    local keyring_name="${2:-$(basename "$key_url" .asc | tr '.' '-')}"
    local keyring_path="/usr/share/keyrings/${keyring_name}.gpg"

    [[ -z "$key_url" ]] && { msg_error "Nie podano URL klucza GPG."; return 1; }

    msg_info "Importowanie klucza GPG: $key_url"

    if ! command_exists gpg; then
        pkg_install gnupg
    fi

    if wget -qO - "$key_url" | gpg --dearmor -o "$keyring_path" 2>/dev/null; then
        chmod 644 "$keyring_path"
        msg_ok "Klucz GPG zaimportowany: $keyring_path"
        echo "$keyring_path"
        return 0
    else
        msg_error "Nie udalo sie zaimportowac klucza GPG."
        return 1
    fi
}

# Uzycie: add_ppa_repo <ppa_name>
add_ppa_repo() {
    local ppa="$1"

    [[ -z "$ppa" ]] && { msg_error "Nie podano nazwy PPA."; return 1; }

    if ! grep -qi ubuntu /etc/os-release 2>/dev/null; then
        msg_warn "PPA sa obslugiwane tylko na Ubuntu. Pomijam: $ppa"
        return 1
    fi

    if ! command_exists add-apt-repository; then
        msg_info "Instalowanie software-properties-common..."
        pkg_install software-properties-common
    fi

    msg_info "Dodawanie PPA: $ppa"

    if [[ "$ppa" != ppa:* ]]; then
        ppa="ppa:$ppa"
    fi

    if add-apt-repository -y "$ppa" >/dev/null 2>&1; then
        msg_ok "PPA dodane: $ppa"
        return 0
    else
        msg_error "Nie udalo sie dodac PPA: $ppa"
        return 1
    fi
}

# Uzycie: add_repository_with_key <repo_line> <list_file> <key_url> [arch]
add_repository_with_key() {
    local repo_line="$1"
    local list_file="$2"
    local key_url="$3"
    local arch="${4:-amd64}"

    [[ -z "$repo_line" ]] && { msg_error "Nie podano linii repozytorium."; return 1; }
    [[ -z "$list_file" ]] && { msg_error "Nie podano nazwy pliku list."; return 1; }
    [[ -z "$key_url" ]] && { msg_error "Nie podano URL klucza."; return 1; }

    list_file="${list_file%.list}"

    local keyring_path
    keyring_path=$(import_gpg_key "$key_url" "$list_file") || return 1

    local list_path="/etc/apt/sources.list.d/${list_file}.list"

    msg_info "Dodawanie repozytorium: $list_file"

    echo "deb [arch=${arch} signed-by=${keyring_path}] ${repo_line}" > "$list_path"

    if [[ -f "$list_path" ]]; then
        msg_ok "Repozytorium dodane: $list_path"
        pkg_update
        return 0
    else
        msg_error "Nie udalo sie utworzyc pliku repozytorium."
        return 1
    fi
}

# Uzycie: remove_repository <list_file>
remove_repository() {
    local list_file="$1"
    list_file="${list_file%.list}"

    local list_path="/etc/apt/sources.list.d/${list_file}.list"
    local keyring_path="/usr/share/keyrings/${list_file}.gpg"

    if [[ -f "$list_path" ]]; then
        rm -f "$list_path"
        msg_ok "Usunieto repozytorium: $list_path"
    fi

    if [[ -f "$keyring_path" ]]; then
        rm -f "$keyring_path"
        msg_ok "Usunieto klucz: $keyring_path"
    fi
}
