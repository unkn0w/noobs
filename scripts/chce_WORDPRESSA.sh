#!/bin/bash
#Autor: Adrian Busse

sh ./chce_LAMP.sh

#Pobieranie i wypakowanie polskiej ostatniej wersji wordpressa
cd /tmp
curl -o latest.tar.gz https://pl.wordpress.org/latest-pl_PL.tar.gz

tar xzvf latest.tar.gz

rm latest.tar.gz

touch /tmp/wordpress/.htaccess

cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php

#Tworzenie katalogu upgrade, żeby wordpress nie musiał tego robić sam.
mkdir /tmp/wordpress/wp-content/upgrade


cp -a /tmp/wordpress/. /var/www/wordpress

#Ustawienie katalogu root w apache.
sed -i "s,/var/www/html,/var/www/wordpress,g" '/etc/apache2/sites-available/000-default.conf'

#Czyszczenie po wszystkim.
rm -r /tmp/wordpress

### Brakuje jeszcze konfiguracji bazy danych.
