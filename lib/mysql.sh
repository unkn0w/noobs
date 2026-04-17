#!/bin/bash
# Bazy danych MySQL/MariaDB - noobs_lib modul
[[ -n "${_NOOBS_MYSQL_LOADED:-}" ]] && return 0
readonly _NOOBS_MYSQL_LOADED=1

# Uzycie: mysql_query <query> [user] [password]
mysql_query() {
    local query="$1"
    local user="${2:-root}"
    local password="${3:-}"

    [[ -z "$query" ]] && { msg_error "Nie podano zapytania SQL."; return 1; }

    if [[ -n "$password" ]]; then
        mysql -u"$user" -p"$password" -e "$query"
    else
        mysql -u"$user" -e "$query"
    fi
}

# Uzycie: mysql_create_db_user <db_name> [username] [password] [hostname] [charset]
# Zwraca: haslo w zmiennej REPLY
mysql_create_db_user() {
    local db_name="$1"
    local username="${2:-$db_name}"
    local password="${3:-$(generate_password 16)}"
    local hostname="${4:-localhost}"
    local charset="${5:-utf8mb4}"
    local collation="${6:-utf8mb4_general_ci}"

    [[ -z "$db_name" ]] && { msg_error "Nie podano nazwy bazy danych."; return 1; }

    msg_info "Tworzenie bazy danych: $db_name"

    mysql_query "CREATE DATABASE IF NOT EXISTS \`$db_name\` CHARACTER SET $charset COLLATE $collation;" || {
        msg_error "Nie udalo sie utworzyc bazy danych."
        return 1
    }

    msg_info "Tworzenie uzytkownika: $username@$hostname"

    mysql_query "CREATE USER IF NOT EXISTS '$username'@'$hostname' IDENTIFIED BY '$password';" || {
        msg_error "Nie udalo sie utworzyc uzytkownika."
        return 1
    }

    mysql_query "GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$username'@'$hostname';" || {
        msg_error "Nie udalo sie nadac uprawnien."
        return 1
    }

    mysql_query "FLUSH PRIVILEGES;"

    msg_ok "Baza danych '$db_name' i uzytkownik '$username' utworzeni."

    REPLY="$password"
    return 0
}

# Uzycie: mysql_drop_db_user <db_name> [username] [hostname]
mysql_drop_db_user() {
    local db_name="$1"
    local username="${2:-$db_name}"
    local hostname="${3:-localhost}"

    [[ -z "$db_name" ]] && { msg_error "Nie podano nazwy bazy danych."; return 1; }

    msg_info "Usuwanie bazy danych i uzytkownika: $db_name, $username"

    mysql_query "DROP DATABASE IF EXISTS \`$db_name\`;"
    mysql_query "DROP USER IF EXISTS '$username'@'$hostname';"
    mysql_query "FLUSH PRIVILEGES;"

    msg_ok "Baza danych i uzytkownik usunieci."
}
