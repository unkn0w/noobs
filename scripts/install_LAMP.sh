#!/bin/bash
apk update
apk add apache2 apache2-utils php81-apache2 php81-mysqli php81-bcmath php81-simplexml php81-zip php81-pear php81-xml php81-curl php81-mbstring php81-pdo_mysql php81-pdo 
rc-update add apache2

chown -R frog:frog /var/www/html

sed -i 's@localhost/htdocs@html@' /etc/apache2/httpd.conf
sed -i 's@AllowOverride.*@AllowOverride all@' /etc/apache2/httpd.conf
sed -i "s@StartServers.*@StartServers\t1@" /etc/apache2/conf.d/mpm.conf
sed -i "s@MaxSpareServers.*@MaxSpareServers\t3@" /etc/apache2/conf.d/mpm.conf
sed -i "s@MinSpareServers.*@MinSpareServers\t1@" /etc/apache2/conf.d/mpm.conf
sed -i "s@MaxRequestWorkers.*@MaxRequestWorkers\t10@" /etc/apache2/conf.d/mpm.conf
sed -i "s@MaxConnectionsPerChild.*@MaxConnectionsPerChild\t50@" /etc/apache2/conf.d/mpm.conf

service apache2 start
echo -e "\n\nPliki strony wrzuc do /var/www/html\n\n"
cat /root/mysql.txt
