#!/bin/bash
# Konfiguracja PHP - noobs_lib modul
[[ -n "${_NOOBS_PHP_LOADED:-}" ]] && return 0
readonly _NOOBS_PHP_LOADED=1

# Uzycie: php_install_packages <version> <packages...>
# Przyklad: php_install_packages "8.1" fpm mysql gd curl mbstring
php_install_packages() {
    local php_version="$1"
    shift
    local packages=("$@")

    [[ -z "$php_version" ]] && { msg_error "Nie podano wersji PHP."; return 1; }
    [[ ${#packages[@]} -eq 0 ]] && { msg_error "Nie podano pakietow PHP."; return 1; }

    msg_info "Instalowanie PHP $php_version z pakietami: ${packages[*]}"

    local full_packages=()
    for pkg in "${packages[@]}"; do
        if [[ "$pkg" == "php" ]]; then
            full_packages+=("php${php_version}")
        else
            full_packages+=("php${php_version}-${pkg}")
        fi
    done

    pkg_install "${full_packages[@]}"
}

# Uzycie: php_configure <version> <setting> <value> [type: fpm|cli|apache2]
# Przyklad: php_configure "8.1" "memory_limit" "512M" "fpm"
php_configure() {
    local php_version="$1"
    local setting="$2"
    local value="$3"
    local type="${4:-fpm}"

    [[ -z "$php_version" ]] && { msg_error "Nie podano wersji PHP."; return 1; }
    [[ -z "$setting" ]] && { msg_error "Nie podano ustawienia."; return 1; }
    [[ -z "$value" ]] && { msg_error "Nie podano wartosci."; return 1; }

    local ini_path="/etc/php/${php_version}/${type}/php.ini"

    if [[ ! -f "$ini_path" ]]; then
        msg_error "Plik php.ini nie istnieje: $ini_path"
        return 1
    fi

    msg_info "Ustawianie PHP: $setting = $value"

    backup_file "$ini_path"

    sed -i "s|^;*\s*${setting}\s*=.*|${setting} = ${value}|" "$ini_path"

    msg_ok "Zmieniono: $setting = $value w $ini_path"
}

# Uzycie: php_fpm_create_pool <version> <pool_name> <user> [pm_max_children]
# Zwraca: sciezka socketa w REPLY
php_fpm_create_pool() {
    local php_version="$1"
    local pool_name="$2"
    local user="$3"
    local group="${4:-$user}"
    local pm_max="${5:-5}"

    [[ -z "$php_version" ]] && { msg_error "Nie podano wersji PHP."; return 1; }
    [[ -z "$pool_name" ]] && { msg_error "Nie podano nazwy puli."; return 1; }
    [[ -z "$user" ]] && { msg_error "Nie podano uzytkownika."; return 1; }

    local pool_dir="/etc/php/${php_version}/fpm/pool.d"
    local pool_file="${pool_dir}/${pool_name}.conf"
    local socket_path="/run/php/${pool_name}.sock"

    [[ ! -d "$pool_dir" ]] && { msg_error "Katalog PHP-FPM nie istnieje: $pool_dir"; return 1; }

    msg_info "Tworzenie puli PHP-FPM: $pool_name"

    cat > "$pool_file" <<EOF
[$pool_name]
user = $user
group = $group
listen = $socket_path
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

pm = dynamic
pm.max_children = $pm_max
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3

php_admin_value[error_log] = /var/log/php-fpm/${pool_name}-error.log
php_admin_flag[log_errors] = on
EOF

    mkdir -p /var/log/php-fpm

    msg_ok "Pula PHP-FPM utworzona: $pool_file"
    msg_info "Socket: $socket_path"

    REPLY="$socket_path"
}
