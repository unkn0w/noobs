#!/bin/bash
#Script created by Andrzej "Ferex" Szczepaniak
#Thanks for Jakub "Unknow" Mrugalski, Marcin "y0rune" Wozniak, Mariusz "maniek205" Kowalski and Paweł aka "./lemon.sh" for help

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

set -euo pipefail

pkg_update
pkg_install lsb-release ca-certificates apt-transport-https software-properties-common gnupg2

os_check=$(cat /etc/os-release | grep "^ID=")
if [[ $os_check == "ID=debian" ]] ;
then
# Nowoczesna metoda dodawania repozytorium (zamiast deprecated apt-key)
keyring_path=$(import_gpg_key "https://packages.sury.org/php/apt.gpg" "sury-php")
echo "deb [signed-by=${keyring_path}] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/sury-php.list
elif [[ $os_check == "ID=ubuntu" ]] ;
then
apt-add-repository ppa:ondrej/php -y
apt-add-repository ppa:ondrej/apache2 -y
fi

pkg_update

if [[ -f /usr/sbin/nginx ]]; then
    echo "Wybacz, ale nginxa nie wspieram obecnie :c"
    exit 0
fi

pkg_install apache2 libapache2-mod-fcgid php8.0-fpm php8.0-memcached php8.0-memcache memcached libmemcached-tools openssl wget php8.0-imagick php8.0-xml php8.0-intl php8.0-dom php8.0-mysqli php8.0-sqlite3 php8.0-gd php8.0-mbstring php8.0-common php8.0-curl php8.0-gd php8.0-imap php8.0-intl php8.0-mbstring php8.0-mysql php8.0-ssh2 php8.0-xml php8.0-zip php8.0-apcu php8.0-ldap php8.0-gmp libmagickcore-6.q16-6-extra
a2enmod dir env headers mime rewrite setenvif ssl proxy proxy_fcgi
a2dismod mpm_prefork
a2enmod mpm_event
a2enconf php8.0-fpm
phpenmod -v 8.0 apcu memcache
echo "apc.enable_cli=1" >> /etc/php/8.0/cli/php.ini
echo "apc.enable_cli=1" >> /etc/php/8.0/fpm/php.ini

crontab -l > /tmp/crontasks

if [[ -d "/storage" ]]; then
    if [[ -d "/storage/nextcloud/" ]]; then
        if [ "$(ls -A /storage/nextcloud)" ]; then
            mv /storage/nextcloud /storage/nextcloud-old
        fi
        rm -rf /storage/nextcloud
    fi
    cd /storage && wget https://download.nextcloud.com/server/releases/latest.tar.bz2 -O nextcloud.tar.bz2
    cd /storage && tar -xf nextcloud.tar.bz2
    cd /storage && rm nextcloud.tar.bz2
    chown -R www-data:www-data /storage/nextcloud

cat > /etc/apache2/sites-available/nextcloud.conf <<\EOL
Alias /nextcloud "/storage/nextcloud"
<Directory /storage/nextcloud>
  Options +FollowSymlinks
  AllowOverride All
  Require all granted
</Directory>
EOL

cat > /storage/nextcloud/config/autoconfig.php <<\EOL
<?php
$AUTOCONFIG = [
  "directory"     => "/storage/nextcloud/data",
];
EOL

cat > /storage/nextcloud/config/memcache.config.php <<\EOL
<?php
$_SERVER['HTTPS'] = 'on';
$CONFIG = array (
  'memcache.local' => '\OC\Memcache\APCu',
  'filelocking.enabled' => 'true',
  'memcache.locking' => '\OC\Memcache\APCu',
);
EOL

echo "*/5  *  *  *  * sudo -u www-data /usr/bin/php --define apc.enable_cli=1 -f /storage/nextcloud/cron.php" >> /tmp/crontasks

else
cd /var/www/html && wget https://download.nextcloud.com/server/releases/latest.tar.bz2 -O nextcloud.tar.bz2
cd /var/www/html && tar -xf nextcloud.tar.bz2
cd /var/www/html && rm nextcloud.tar.bz2
chown -R www-data:www-data /var/www/html

cat > /etc/apache2/sites-available/nextcloud.conf <<\EOL
Alias /nextcloud "/var/www/html/nextcloud"
<Directory /var/www/html/nextcloud>
  Options +FollowSymlinks
  AllowOverride All
  Require all granted
</Directory>
EOL

cat > /var/www/html/nextcloud/config/autoconfig.php <<\EOL
<?php
$AUTOCONFIG = [
  "directory"     => "/var/www/html/nextcloud/data",
];
EOL

cat > /var/www/html/nextcloud/config/memcache.config.php <<\EOL
<?php
$_SERVER['HTTPS'] = 'on';
$CONFIG = array (
  'memcache.local' => '\OC\Memcache\APCu',
  'filelocking.enabled' => 'true',
  'memcache.locking' => '\OC\Memcache\APCu',
);
EOL

echo "*/5  *  *  *  * sudo -u www-data /usr/bin/php --define apc.enable_cli=1 -f /var/www/html/nextcloud/cron.php" >> /tmp/crontasks

fi

crontab /tmp/crontasks
rm /tmp/crontasks
a2ensite nextcloud
service_restart apache2
