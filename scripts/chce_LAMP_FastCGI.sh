#!/bin/bash
# LAMP = Linux + Apache + MySQL (MariaDB) + PHP
# Autor: Jakub 'unknow' Mrugalski
# Edited and modified by: Andrzej 'Ferex' Szczepaniak & Jarosław 'Evilus' Rauza

apt update
apt install -y software-properties-common 

# Repozytoria zewnętrzne z PHP 8.0 i najnowszym Apachem (nie ma ich w standardowym Ubuntu)
add-apt-repository -y ppa:ondrej/apache2
add-apt-repository -y ppa:ondrej/php

# apache + najpopularniejsze moduły do PHP oraz memcached
apt install -y apache2 libapache2-mod-fcgid php8.0 php8.0-fpm php8.0-memcached php8.0-memcache php8.0-zip php8.0-xml php8.0-sqlite3 php8.0-pgsql php8.0-mysql php8.0-mcrypt php8.0-mbstring php8.0-intl php8.0-gd php8.0-curl php8.0-cli php8.0-bcmath

# zmiana mpm_prefork na mpm_event, mpm-prefork działa kiedy instalujemy libapache2-mod-php, zaś event dla php-fpm
a2dismod mpm_prefork
a2enmod mpm_event

# aktywacja mod_rewrite dla wspierania krótkich linków - np. w Wordpress, oraz proxy i proxy dla fastcgi
a2enmod rewrite setenvif proxy proxy_fcgi

# instalacja memcached
apt install memcached libmemcached-tools -y

# aktywacja konfiguracji modułu php8.0-fpm dla apache2
a2enconf php8.0-fpm

# restart usługi po dodaniu nowego modułu
systemctl restart apache2

# dodanie MariaDB (klient i serwer)
apt install -y mariadb-server mariadb-client

# uruchomienie serwera mariadb
systemctl start mariadb

# dodanie autostartu do mariadb i apache
systemctl enable apache2
systemctl enable mariadb

# Usuwamy domyślną 
rm /var/www/html/index.html

# Dowód na działanie PHP
echo '<?php echo "2 + 2 = ".(2+2); ?>' >/var/www/html/index.php

# == Lekki hardening ustawień ==

# Serwer ma się nie doklejać swojej stopki nigdzie
sed -i -e "s/^ServerSignature OS*.*\$/ServerSignature Off/" '/etc/apache2/conf-available/security.conf'

# Serwer będzie się przedstawiał jako "Apache" - bez wersji softu i OS
sed -i -e "s/^ServerTokens OS*.*\$/ServerTokens Prod/" '/etc/apache2/conf-available/security.conf'

