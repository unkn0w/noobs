#!/bin/bash
# Konfiguracja Nginx - noobs_lib modul
[[ -n "${_NOOBS_NGINX_LOADED:-}" ]] && return 0
readonly _NOOBS_NGINX_LOADED=1

# Uzycie: nginx_create_server_block <name> <root_path> <php_socket> [app_type]
# app_type: generic|drupal|moodle|wordpress
nginx_create_server_block() {
    local block_name="$1"
    local root_path="$2"
    local php_socket="${3:-/var/run/php/php-fpm.sock}"
    local app_type="${4:-generic}"

    [[ -z "$block_name" ]] && { msg_error "Nie podano nazwy bloku."; return 1; }
    [[ -z "$root_path" ]] && { msg_error "Nie podano sciezki root."; return 1; }

    local block_file="/etc/nginx/sites-available/${block_name}"

    msg_info "Tworzenie Nginx server block: $block_name"

    cat > "$block_file" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name _;
    root ${root_path};
    index index.php index.html index.htm;

EOF

    case "$app_type" in
        drupal)
            cat >> "$block_file" <<EOF
    location / {
        try_files \$uri /index.php?\$query_string;
    }

    location @rewrite {
        rewrite ^ /index.php;
    }

    location ~ '\.php\$|^/update.php' {
        fastcgi_split_path_info ^(.+?\.php)(|/.*)\$;
        try_files \$fastcgi_script_name =404;
        include fastcgi_params;
        fastcgi_param HTTP_PROXY "";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_intercept_errors on;
        fastcgi_pass unix:${php_socket};
    }
EOF
            ;;
        moodle|wordpress)
            cat >> "$block_file" <<EOF
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(.*)\$;
        fastcgi_index index.php;
        fastcgi_pass unix:${php_socket};
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }
EOF
            ;;
        *)
            cat >> "$block_file" <<EOF
    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${php_socket};
    }
EOF
            ;;
    esac

    cat >> "$block_file" <<EOF

    location ~ /\.ht {
        deny all;
    }

    error_log /var/log/nginx/${block_name}_error.log;
    access_log /var/log/nginx/${block_name}_access.log;
}
EOF

    msg_ok "Server block utworzony: $block_file"
}
