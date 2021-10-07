#!/bin/bash
# NEXTCLOUD installation script
# Autors: Mariusz 'maniek205' Kowalski, Marcin Wozniak

USERNAME="admin"
PASSWORD=$(head -c 100 /dev/urandom | tr -dc A-Za-z0-9 | head -c13)

DB_USER=root
DB_PASS=$(head -c 100 /dev/urandom | tr -dc A-Za-z0-9 | head -c13)

NEXT_CLOUD_USER="admin"
NEXT_CLOUD_PASS=$(head -c 100 /dev/urandom | tr -dc A-Za-z0-9 | head -c13)

#Set Timezone to prevent installation interruption
[[ ! -f /etc/localtime ]] && ln -snf /usr/share/zoneinfo/Poland /etc/localtime && echo "Etc/UTC" > /etc/timezone

#Installing prerequisites https://docs.nextcloud.com/server/latest/admin_manual/installation/example_ubuntu.html
apt update
apt install -y apache2 mariadb-server libapache2-mod-php7.4
apt install -y php7.4-gd php7.4-mysql php7.4-curl php7.4-mbstring php7.4-intl
apt install -y php7.4-gmp php7.4-bcmath php-imagick php7.4-xml php7.4-zip

#Configuring mariaDB
/etc/init.d/mysql start
mysql -u"$DB_USER" -p"$DB_PASS" -e "CREATE USER '$USERNAME'@'localhost' IDENTIFIED BY '$PASSWORD';
CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
GRANT ALL PRIVILEGES ON nextcloud.* TO '$USERNAME'@'localhost';
FLUSH PRIVILEGES;"

#Downloading nextcloud tar.bz2 file
apt install -y wget tar curl

nextcloud_link=$(curl https://nextcloud.com/install/\#instructions-server \
	| grep -Eo 'https://.+\/releases\/.+\.tar\.bz2"' | sed 's/"//g')
nextcloud_tmp="/tmp/nextcloud.tar.bz2"

wget "$nextcloud_link" -O "$nextcloud_tmp"
tar -xf "$nextcloud_tmp"

#Copy nextcloud to apache folder
rm /var/www/html/index.html
echo "Copying nextcloud to apache folder..."
cp -r nextcloud/ /var/www/html/
rm -v "$nextcloud_tmp"
echo "Done",
#Apache config
cat > /etc/apache2/sites-available/nextcloud.conf <<EOL
Alias /nextcloud "/var/www/html/nextcloud/"

<Directory /var/www/html/nextcloud/>
  Satisfy Any
  Require all granted
  AllowOverride All
  Options FollowSymLinks MultiViews

  <IfModule mod_dav.c>
    Dav off
  </IfModule>
</Directory>
EOL

a2ensite nextcloud.conf
a2enmod rewrite
a2enmod headers
a2enmod env
a2enmod dir
a2enmod mime
a2enmod setenvif
service apache2 restart

chown -R www-data:www-data /var/www/html/

apt install -y sudo

cd /var/www/html/nextcloud  || exit
sudo -u www-data php occ  maintenance:install --database \
"mysql" --database-name "nextcloud"  --database-user "$USERNAME" --database-pass \
"$PASSWORD" --admin-user "$NEXT_CLOUD_USER" --admin-pass "$NEXT_CLOUD_PASS"

# czy user posiada /storage/?
if [ -d /storage ]; then
    echo "Znalazłem /storage - przenoszę dane do /storage/nextcloud_data";
    mkdir /storage/nextcloud_data
    rsync -av /var/www/html/nextcloud/data/ /storage/nextcloud_data/
    chown -R www-data:www-data /storage/nextcloud_data/
    rm -rf /var/www/html/nextcloud/data
    ln -s /storage/nextcloud_data /var/www/html/nextcloud/data
fi

echo "
== Dostępy na których działa Nextcloud ==
MYSQL_USERNAME=$USERNAME
MYSQL_PASSWORD=$PASSWORD


== Dane do bazy danych ==
DB_USER=$DB_USER
DB_PASS=$DB_PASS

== Dane do Logowania do panelu ==
NC_USER=$NEXT_CLOUD_USER
NC_PASS=$NEXT_CLOUD_PASS

Bardzo ważne:
Edytuj plik /var/www/html/nextcloud/config/config.php
Znajdź linijkę z tekstem 'localhost' i ponieżej dopisz swoją domenę na której będzie działać Nextcloud.

P.S. Zapisałem te dane do /root/nextcloud.txt
" | tee /root/nextcloud.txt

chmod 600 /root/nextcloud.txt
