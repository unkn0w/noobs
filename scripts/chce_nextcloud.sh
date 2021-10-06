#!/bin/bash
# NEXTCLOUD installation script
# Autor: Mariusz 'unknow' Kowalski

USERNAME=admin
PASSWORD=admin

DB_USER=root
DB_PASS=admin

#Set Timezone to prevent installation interruption
ln -snf /usr/share/zoneinfo/Poland /etc/localtime && echo "Etc/UTC" > /etc/timezone


#Installing prerequisites https://docs.nextcloud.com/server/latest/admin_manual/installation/example_ubuntu.html
apt update
apt install -y apache2 mariadb-server libapache2-mod-php7.4
apt install -y php7.4-gd php7.4-mysql php7.4-curl php7.4-mbstring php7.4-intl
apt install -y php7.4-gmp php7.4-bcmath php-imagick php7.4-xml php7.4-zip

#Configuring mariaDB
/etc/init.d/mysql start
mysql -u$DB_USER -p$DB_PASS -e "CREATE USER '$USERNAME'@'localhost' IDENTIFIED BY '$PASSWORD'; 
CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci; 
GRANT ALL PRIVILEGES ON nextcloud.* TO '$USERNAME'@'localhost'; 
FLUSH PRIVILEGES;"

#Downloading nextcloud zip file
apt install -y wget unzip
wget https://download.nextcloud.com/server/releases/nextcloud-22.2.0.zip
unzip nextcloud-22.2.0.zip
#Copy nextcloud to apache folder
cp -r nextcloud /var/www

