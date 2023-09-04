#!/bin/bash
# LAMP = Linux + Apache + MySQL (MariaDB) + PHP
# Autor: Jakub 'unknow' Mrugalski

apt update
apt install -y software-properties-common 

# Repozytoria zewnętrzne z najnowszym Apachem i PHP (nie ma ich w standardowym Ubuntu)
add-apt-repository -y ppa:ondrej/apache2
add-apt-repository -y ppa:ondrej/php

# apache + najpopularniejsze moduły do PHP
apt install -y apache2 php libapache2-mod-php php-zip php-xml php-sqlite3 php-pgsql php-mysql php-mcrypt php-mbstring php-intl php-gd php-curl php-cli php-bcmath

# dodanie MariaDB (klient i serwer)
apt install -y mariadb-server mariadb-client

# uruchomienie serwera mariadb
systemctl start mariadb

# aktywacja mod_rewrite dla wspierania krótkich linków - np. w Wordpress
a2enmod rewrite

# restart usługi po dodaniu nowego modułu
systemctl restart apache2

# dodanie autostartu do mariadb i apache
systemctl enable apache2
systemctl enable mariadb

# Usuwamy domyślną 
rm /var/www/html/index.html

# Dowód na działanie PHP
echo '<?php echo "2 + 2 = ".(2+2); ' >/var/www/html/index.php

# == Lekki hardening ustawień ==

# Serwer ma się nie doklejać swojej stopki nigdzie
sed -i -e "s/^ServerSignature OS*.*\$/ServerSignature Off/" '/etc/apache2/conf-available/security.conf'

# Serwer będzie się przedstawiał jako "Apache" - bez wersji softu i OS
sed -i -e "s/^ServerTokens OS*.*\$/ServerTokens Prod/" '/etc/apache2/conf-available/security.conf'

