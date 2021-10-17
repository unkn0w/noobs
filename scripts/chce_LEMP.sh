#!/bin/bash
# LEMP = Linux + Nginx + MySQL (MariaDB) + PHP
# Autor: Jakub Rolecki

# Sprawdz uprawnienia przed wykonaniem skryptu instalacyjnego
if [[ $EUID -ne 0 ]]; then
   echo -e "W celu instalacji tego pakietu potrzebujesz wyzszych uprawnien! Uzyj polecenia \033[1;31msudo ./chce_LEMP.sh\033[0m lub zaloguj sie na konto roota i wywolaj skrypt ponownie."
   exit 1
fi

apt update
apt install -y software-properties-common

# Repozytoria zewnętrzne z PHP 8.0 i najnowszymi wydaniami nginx
add-apt-repository -y ppa:ondrej/php
add-apt-repository -y ppa:nginx/stable

# Aktualizacja repozytoriow
apt update

# nginx + najpopularniejsze moduły do PHP
apt install -y nginx php8.0 php8.0-fpm php8.0-zip php8.0-xml php8.0-sqlite3 php8.0-pgsql php8.0-mysql php8.0-mcrypt php8.0-mbstring php8.0-intl php8.0-gd php8.0-curl php8.0-cli php8.0-bcmath

# dodanie MariaDB (klient i serwer)
apt install -y mariadb-server mariadb-client

# utworzenie konfiguracji wspierającej PHP w nginx
config=$(cat <<EOF
server {
   listen   80 default_server;
   listen   [::]:80 default_server;

   root /var/www/html;

   index index.html index.htm index.php;

   server_name _;

   location / {
      try_files \$uri \$uri/ =404;
   }

   location ~ \.php\$ {
      include snippets/fastcgi-php.conf;
      
      fastcgi_pass unix:/var/run/php/php8.0-fpm.sock;
   }
}
EOF
)

# aktualizacja konfiguracji
echo "$config" >/etc/nginx/sites-available/default

# Dowód na działanie PHP
echo '<?php echo "2 + 2 = ".(2+2); ' >/var/www/html/index.php

# Serwer będzie się przedstawiał jako "Nginx" - bez wersji serwera
sed -e 's/# server_tokens off;/server_tokens off;/' -i /etc/nginx/nginx.conf 

# Przeładowanie nginxa
systemctl reload nginx

systemctl status nginx