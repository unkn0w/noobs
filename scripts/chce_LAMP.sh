#!/bin/bash
# LAMP = Linux + Apache + MySQL (MariaDB) + PHP
# Autor: Jakub 'unknow' Mrugalski

# Check if user is root
if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root" 1>&2
	echo "Try: sudo $0" 1>&2
	exit 1
fi

apt update
apt install -y software-properties-common 

# Repozytoria zewnętrzne z PHP 8.0 i najnowszym Apachem (nie ma ich w standardowym Ubuntu)
add-apt-repository -y ppa:ondrej/apache2
add-apt-repository -y ppa:ondrej/php

# apache + najpopularniejsze moduły do PHP
apt install -y apache2 php8.0 libapache2-mod-php8.0 php8.0-zip php8.0-xml php8.0-sqlite3 php8.0-pgsql php8.0-mysql php8.0-mcrypt php8.0-mbstring php8.0-intl php8.0-gd php8.0-curl php8.0-cli php8.0-bcmath

# dodanie MariaDB (klient i serwer)
apt install -y mariadb-server mariadb-client

# aktywacja mod_rewrite dla wspierania krótkich linków - np. w Wordpress
a2enmod rewrite

# restart usługi po dodaniu nowego modułu
systemctl restart apache2

# Usuwamy domyślną 
rm /var/www/html/index.html

# Dowód na działanie PHP
echo '<?php echo "2 + 2 = ".(2+2); ' >/var/www/html/index.php

# == Lekki hardening ustawień ==

# Serwer ma się nie doklejać swojej stopki nigdzie
sed -i -e "s/^ServerSignature OS*.*\$/ServerSignature Off/" '/etc/apache2/conf-available/security.conf'

# Serwer będzie się przedstawiał jako "Apache" - bez wersji softu i OS
sed -i -e "s/^ServerTokens OS*.*\$/ServerTokens Prod/" '/etc/apache2/conf-available/security.conf'

