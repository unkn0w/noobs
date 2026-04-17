#!/bin/bash
# Operacje na plikach konfiguracyjnych - noobs_lib modul
[[ -n "${_NOOBS_CONFIG_LOADED:-}" ]] && return 0
readonly _NOOBS_CONFIG_LOADED=1

# Uzycie: config_set_value <file> <key> <value> [delimiter]
config_set_value() {
    local file="$1"
    local key="$2"
    local value="$3"
    local delimiter="${4:-=}"

    [[ -z "$file" ]] && { msg_error "Nie podano pliku konfiguracyjnego."; return 1; }
    [[ -z "$key" ]] && { msg_error "Nie podano klucza."; return 1; }
    [[ ! -f "$file" ]] && { msg_error "Plik nie istnieje: $file"; return 1; }

    if grep -qE "^[#;]*\s*${key}\s*${delimiter}" "$file"; then
        sed -i "s|^[#;]*\s*${key}\s*${delimiter}.*|${key}${delimiter}${value}|" "$file"
        msg_debug "Zmieniono: ${key}${delimiter}${value} w $file"
    else
        echo "${key}${delimiter}${value}" >> "$file"
        msg_debug "Dodano: ${key}${delimiter}${value} do $file"
    fi
}

# Uzycie: config_append_if_missing <file> <line>
config_append_if_missing() {
    local file="$1"
    local line="$2"

    [[ -z "$file" ]] && { msg_error "Nie podano pliku."; return 1; }
    [[ -z "$line" ]] && { msg_error "Nie podano linii."; return 1; }

    [[ ! -f "$file" ]] && touch "$file"

    if ! grep -qF "$line" "$file"; then
        echo "$line" >> "$file"
        msg_debug "Dodano do $file: $line"
        return 0
    else
        msg_debug "Linia juz istnieje w $file"
        return 1
    fi
}

# Uzycie: config_remove_line <file> <pattern>
config_remove_line() {
    local file="$1"
    local pattern="$2"

    [[ -z "$file" ]] && { msg_error "Nie podano pliku."; return 1; }
    [[ -z "$pattern" ]] && { msg_error "Nie podano wzorca."; return 1; }
    [[ ! -f "$file" ]] && { msg_error "Plik nie istnieje: $file"; return 1; }

    sed -i "/${pattern}/d" "$file"
    msg_debug "Usunieto linie pasujace do '$pattern' z $file"
}

# Uzycie: config_comment_line <file> <pattern> [comment_char]
config_comment_line() {
    local file="$1"
    local pattern="$2"
    local comment="${3:-#}"

    [[ ! -f "$file" ]] && { msg_error "Plik nie istnieje: $file"; return 1; }

    sed -i "s|^\(${pattern}.*\)|${comment}\1|" "$file"
}

# Uzycie: config_uncomment_line <file> <pattern> [comment_char]
config_uncomment_line() {
    local file="$1"
    local pattern="$2"
    local comment="${3:-#}"

    [[ ! -f "$file" ]] && { msg_error "Plik nie istnieje: $file"; return 1; }

    sed -i "s|^${comment}\s*\(${pattern}.*\)|\1|" "$file"
}

# Uzycie: secure_file <file> [mode]
secure_file() {
    local file="$1"
    local mode="${2:-600}"

    [[ -z "$file" ]] && { msg_error "Nie podano pliku."; return 1; }
    [[ ! -f "$file" ]] && { msg_error "Plik nie istnieje: $file"; return 1; }

    chown root:root "$file"
    chmod "$mode" "$file"
    msg_debug "Zabezpieczono plik: $file (mode: $mode)"
}
