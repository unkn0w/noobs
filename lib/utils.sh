#!/bin/bash
# Narzedzia ogolne - noobs_lib modul
[[ -n "${_NOOBS_UTILS_LOADED:-}" ]] && return 0
readonly _NOOBS_UTILS_LOADED=1

generate_password() {
    local length="${1:-16}"
    head -c255 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c "$length"
}

generate_random_string() {
    local length="${1:-8}"
    cat /dev/urandom | tr -dc 'a-z0-9' | head -c "$length"
}

get_primary_ip() {
    hostname -I 2>/dev/null | awk '{print $1}'
}

get_local_ip() {
    hostname -I 2>/dev/null | awk '{print $1}'
}

get_public_ip() {
    local ip=""

    if command_exists curl; then
        ip=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null)
        [[ -n "$ip" ]] && { echo "$ip"; return 0; }

        ip=$(curl -s --connect-timeout 5 ipinfo.io/ip 2>/dev/null)
        [[ -n "$ip" ]] && { echo "$ip"; return 0; }
    fi

    if command_exists wget; then
        ip=$(wget -qO- --timeout=5 ifconfig.me 2>/dev/null)
        [[ -n "$ip" ]] && { echo "$ip"; return 0; }
    fi

    if command_exists dig; then
        ip=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null)
        [[ -n "$ip" ]] && { echo "$ip"; return 0; }
    fi

    msg_warn "Nie udalo sie pobrac publicznego IP"
    return 1
}

get_gateway_ip() {
    ip route | awk '/default/ { print $3 }' | head -1
}

get_routed_ip() {
    local gateway
    gateway=$(get_gateway_ip)
    [[ -z "$gateway" ]] && { msg_warn "Brak gateway"; return 1; }
    ip route get "$gateway" | grep -oP 'src \K[^ ]+' | head -1
}

get_hostname_number() {
    local hostname
    hostname=$(hostname)
    echo "${hostname##*[!0-9]}"
}

backup_file() {
    local file="$1"
    local backup="${file}.bak.$(date +%Y%m%d_%H%M%S)"

    if [[ -f "$file" ]]; then
        cp "$file" "$backup"
        msg_info "Utworzono kopie zapasowa: $backup"
    fi
}

cleanup_temp() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        msg_info "Usuwanie plikow tymczasowych: $dir"
        rm -rf "$dir"
    fi
}
