#!/usr/bin/env bash
# NEXTCLOUD installation script
# Autors: Mariusz 'maniek205' Kowalski, Marcin Wozniak
# Refactored: noobs community (v2.0.0)

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

msg_info "Sprawdzenie uprawnien"
require_root

# Generowanie hasel
DB_USER="nextcloud"
DB_PASS="$(generate_random_string 16)"
NC_USER="admin"
NC_PASS="$(generate_random_string 16)"

# Ustawienie strefy czasowej
[[ ! -f /etc/localtime ]] && ln -snf /usr/share/zoneinfo/Poland /etc/localtime && echo "Etc/UTC" > /etc/timezone

msg_info "Aktualizacja pakietow"
pkg_update

msg_info "Instalacja pakietow"
pkg_install apache2 mariadb-server libapache2-mod-php8.1 sudo wget tar curl
php_install_packages "8.1" gd mysql curl mbstring intl gmp bcmath imagick xml zip fpm

msg_info "Konfiguracja bazy danych"
mysql_create_db_user "nextcloud" "$DB_USER" "$DB_PASS"

msg_info "Pobieranie Nextcloud"
nextcloud_link=$(curl -s https://nextcloud.com/install/\#instructions-server \
	| grep -Eo 'https://.+\/releases\/.+\.tar\.bz2"' | sed 's/"//g')
download_and_extract "$nextcloud_link" "/var/www/html" 0

msg_info "Konfiguracja Apache"
rm -f /var/www/html/index.html
chown -R www-data:www-data /var/www/html/

apache_create_alias "nextcloud" "/nextcloud" "/var/www/html/nextcloud"

a2enmod rewrite headers env dir mime setenvif proxy_fcgi
a2enconf php8.1-fpm
service_restart apache2

msg_info "Instalacja Nextcloud"
cd /var/www/html/nextcloud || die "Nie mozna przejsc do katalogu nextcloud"
sudo -u www-data php occ maintenance:install --database \
"mysql" --database-name "nextcloud" --database-user "$DB_USER" --database-pass \
"$DB_PASS" --admin-user "$NC_USER" --admin-pass "$NC_PASS"

# Sprawdzenie czy istnieje /storage
if [[ -d /storage ]]; then
    msg_info "Przenoszenie danych do /storage/nextcloud_data"
    mkdir -p /storage/nextcloud_data
    rsync -av /var/www/html/nextcloud/data/ /storage/nextcloud_data/
    chown -R www-data:www-data /storage/nextcloud_data/
    rm -rf /var/www/html/nextcloud/data
    ln -s /storage/nextcloud_data /var/www/html/nextcloud/data
fi

msg_ok "Nextcloud zainstalowany pomyslnie!"

cat > /root/nextcloud.txt <<EOL
== Dane do bazy danych ==
DB_USER=$DB_USER
DB_PASS=$DB_PASS

== Dane do logowania do panelu ==
NC_USER=$NC_USER
NC_PASS=$NC_PASS

Wazne: Edytuj plik /var/www/html/nextcloud/config/config.php
i dodaj swoja domene do tablicy 'trusted_domains'.
EOL

chmod 600 /root/nextcloud.txt
msg_info "Szczegoly zapisane w /root/nextcloud.txt"
