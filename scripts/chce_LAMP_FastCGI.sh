#!/bin/bash
# LAMP = Linux + Apache + MySQL (MariaDB) + PHP
# Autor: Jakub 'unknow' Mrugalski
# Edited and modified by: Andrzej 'Ferex' Szczepaniak & Jarosław 'Evilus' Rauza

apt update
apt install -y software-properties-common

# Repozytoria zewnętrzne z PHP i najnowszym Apachem (nie ma ich w standardowym Ubuntu)
add-apt-repository -y ppa:ondrej/apache2
add-apt-repository -y ppa:ondrej/php

# apache + najpopularniejsze moduły do PHP oraz memcached
apt install -y apache2 libapache2-mod-fcgid php php-fpm php-memcached php-memcache php-zip php-xml php-sqlite3 php-pgsql php-mysql php-mcrypt php-mbstring php-intl php-gd php-curl php-cli php-bcmath

# zmiana mpm_prefork na mpm_event, mpm-prefork działa kiedy instalujemy libapache2-mod-php, zaś event dla php-fpm
a2dismod mpm_prefork
a2enmod mpm_event

# aktywacja mod_rewrite dla wspierania krótkich linków - np. w Wordpress, oraz proxy i proxy dla fastcgi
a2enmod rewrite setenvif proxy proxy_fcgi

# instalacja memcached
apt install memcached libmemcached-tools -y

# aktywacja konfiguracji modułu php-fpm dla apache2
PHP_VERSION = "$(/usr/bin/php.default -v | head -1 | cut -c5-7)"
a2enconf php"$PHP_VERSION"-fpm

# restart usługi po dodaniu nowego modułu
apache2ctl restart

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

