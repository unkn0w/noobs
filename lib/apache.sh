#!/bin/bash
# Konfiguracja Apache - noobs_lib modul
[[ -n "${_NOOBS_APACHE_LOADED:-}" ]] && return 0
readonly _NOOBS_APACHE_LOADED=1

# Uzycie: apache_create_vhost <name> <document_root> [port] [server_name]
apache_create_vhost() {
    local vhost_name="$1"
    local doc_root="$2"
    local port="${3:-80}"
    local server_name="${4:-_}"

    [[ -z "$vhost_name" ]] && { msg_error "Nie podano nazwy vhosta."; return 1; }
    [[ -z "$doc_root" ]] && { msg_error "Nie podano document root."; return 1; }

    local vhost_file="/etc/apache2/sites-available/${vhost_name}.conf"

    msg_info "Tworzenie Apache VirtualHost: $vhost_name"

    cat > "$vhost_file" <<EOF
<VirtualHost *:${port}>
    ServerName ${server_name}
    DocumentRoot ${doc_root}

    <Directory ${doc_root}>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/${vhost_name}_error.log
    CustomLog \${APACHE_LOG_DIR}/${vhost_name}_access.log combined
</VirtualHost>
EOF

    msg_ok "VirtualHost utworzony: $vhost_file"
}

# Uzycie: apache_create_alias <alias_name> <alias_url> <directory_path>
apache_create_alias() {
    local alias_name="$1"
    local alias_url="$2"
    local dir_path="$3"

    [[ -z "$alias_name" ]] && { msg_error "Nie podano nazwy aliasu."; return 1; }
    [[ -z "$alias_url" ]] && { msg_error "Nie podano URL aliasu."; return 1; }
    [[ -z "$dir_path" ]] && { msg_error "Nie podano sciezki katalogu."; return 1; }

    local alias_file="/etc/apache2/sites-available/${alias_name}.conf"

    msg_info "Tworzenie Apache Alias: $alias_name"

    cat > "$alias_file" <<EOF
Alias ${alias_url} "${dir_path}/"

<Directory ${dir_path}/>
    Satisfy Any
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews

    <IfModule mod_dav.c>
        Dav off
    </IfModule>
</Directory>
EOF

    msg_ok "Alias utworzony: $alias_file"
}

# Uzycie: webserver_enable_site <server_type> <site_name>
webserver_enable_site() {
    local server_type="$1"
    local site_name="$2"

    [[ -z "$server_type" ]] && { msg_error "Nie podano typu serwera."; return 1; }
    [[ -z "$site_name" ]] && { msg_error "Nie podano nazwy strony."; return 1; }

    msg_info "Wlaczanie strony: $site_name ($server_type)"

    case "$server_type" in
        apache)
            a2ensite "$site_name" >/dev/null 2>&1
            service_reload apache2
            ;;
        nginx)
            ln -sf "/etc/nginx/sites-available/${site_name}" \
                   "/etc/nginx/sites-enabled/${site_name}"
            service_reload nginx
            ;;
        *)
            msg_error "Nieznany typ serwera: $server_type"
            return 1
            ;;
    esac

    msg_ok "Strona wlaczona: $site_name"
}

# Uzycie: webserver_disable_site <server_type> <site_name>
webserver_disable_site() {
    local server_type="$1"
    local site_name="$2"

    [[ -z "$server_type" ]] && { msg_error "Nie podano typu serwera."; return 1; }
    [[ -z "$site_name" ]] && { msg_error "Nie podano nazwy strony."; return 1; }

    msg_info "Wylaczanie strony: $site_name ($server_type)"

    case "$server_type" in
        apache)
            a2dissite "$site_name" >/dev/null 2>&1
            service_reload apache2
            ;;
        nginx)
            rm -f "/etc/nginx/sites-enabled/${site_name}"
            service_reload nginx
            ;;
        *)
            msg_error "Nieznany typ serwera: $server_type"
            return 1
            ;;
    esac

    msg_ok "Strona wylaczona: $site_name"
}
