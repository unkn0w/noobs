#!/bin/bash
apk update
apk add apache2 apache2-utils php83-apache2 php83-mysqli php83-bcmath php83-simplexml php83-zip php83-pear php83-xml php83-curl php83-mbstring php83-pdo_mysql php83-pdo
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
