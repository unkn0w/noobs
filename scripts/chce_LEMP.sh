#!/bin/bash
# LEMP = Linux + Nginx + MySQL (MariaDB) + PHP
# Autor: Jakub Rolecki
# Refactored: noobs community (v2.0.0)

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

msg_info "Sprawdzenie uprawnien"
require_root

msg_info "Aktualizacja pakietow"
pkg_update
pkg_install software-properties-common

msg_info "Dodawanie repozytoriow zewnetrznych"
add_ppa_repo "ondrej/php"
add_ppa_repo "nginx/stable"

msg_info "Instalacja Nginx i PHP"
pkg_install nginx mariadb-server mariadb-client
php_install_packages "" fpm zip xml sqlite3 pgsql mysql mcrypt mbstring intl gd curl cli bcmath

msg_info "Konfiguracja Nginx z obsluga PHP"
cat > /etc/nginx/sites-available/default <<'EOF'
server {
   listen   80 default_server;
   listen   [::]:80 default_server;

   root /var/www/html;

   index index.html index.htm index.php;

   server_name _;

   location / {
      try_files $uri $uri/ =404;
   }

   location ~ \.php$ {
      include snippets/fastcgi-php.conf;
      fastcgi_pass unix:/var/run/php/php-fpm.sock;
   }
}
EOF

msg_info "Tworzenie strony testowej PHP"
echo '<?php echo "2 + 2 = ".(2+2); ?>' > /var/www/html/index.php

msg_info "Hardening Nginx"
sed -e 's/# server_tokens off;/server_tokens off;/' -i /etc/nginx/nginx.conf

msg_info "Uruchamianie uslug"
service_enable_now nginx
service_reload nginx
service_enable mariadb

msg_ok "LEMP zainstalowany pomyslnie!"
