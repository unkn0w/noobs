#!/bin/bash
# Michał Giza
# Refactored: noobs community (v2.0.0)

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

msg_info "Sprawdzenie uprawnien"
require_root

msg_info "Aktualizacja pakietow"
pkg_update

msg_info "Dodanie repozytorium z PHP"
add_ppa_repo "ondrej/php"

msg_info "Instalacja pakietow"
pkg_install vsftpd unzip nginx mariadb-server
php_install_packages "7.4" fpm common mysql gmp curl intl mbstring xmlrpc gd xml cli zip

msg_info "Tworzenie uzytkownika shop"
create_web_user "shop" "/home/shop" "/bin/bash" true
SSH_PASS="$REPLY"

msg_info "Konfiguracja FTP"
backup_file /etc/vsftpd.conf
cat > /etc/vsftpd.conf <<EOL
listen=NO
listen_ipv6=YES
anonymous_enable=NO
local_enable=YES
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
ssl_enable=NO
write_enable=YES
local_umask=022
chroot_local_user=YES
allow_writeable_chroot=YES
pasv_enable=Yes
pasv_min_port=40000
pasv_max_port=40100
EOL
service_restart vsftpd

msg_info "Tworzenie bazy danych"
mysql_create_db_user "shop" "shop"
DB_PASS="$REPLY"

msg_info "Zmiana ustawien PHP"
php_configure "7.4" "file_uploads" "On" "fpm"
php_configure "7.4" "allow_url_fopen" "On" "fpm"
php_configure "7.4" "short_open_tag" "On" "fpm"
php_configure "7.4" "memory_limit" "256M" "fpm"
php_configure "7.4" "upload_max_filesize" "100M" "fpm"
php_configure "7.4" "max_execution_time" "360" "fpm"
php_configure "7.4" "cgi.fix_pathinfo" "0" "fpm"
php_configure "7.4" "date.timezone" "Europe/Warsaw" "fpm"

msg_info "Tworzenie puli PHP-FPM"
php_fpm_create_pool "7.4" "shop" "shop"
PHP_SOCKET="$REPLY"
service_restart php7.4-fpm

msg_info "Pobieranie PrestaShop"
download_file "https://download.prestashop.com/download/releases/prestashop_1.7.7.8.zip" "/tmp/prestashop_main.zip"

msg_info "Wypakowywanie PrestaShop"
cd /tmp || die "Nie mozna przejsc do /tmp"
unzip -o /tmp/prestashop_main.zip -d /tmp/prestashop_extract
rm -f /tmp/prestashop_extract/Install_PrestaShop.html /tmp/prestashop_extract/index.php
unzip -o /tmp/prestashop_extract/prestashop.zip -d /home/shop
rm -rf /tmp/prestashop_extract /tmp/prestashop_main.zip

msg_info "Dostosowanie uprawnien"
chown -R shop:shop /home/shop
chmod -R 755 /home/shop
# Uzyj 775 zamiast 777 dla bezpieczenstwa (grupa www-data moze zapisywac)
chmod -R 775 /home/shop/var
# Dodaj uzytkownika shop do grupy www-data
usermod -aG www-data shop

msg_info "Konfiguracja Nginx"
webserver_disable_site "nginx" "default"
nginx_create_server_block "prestashop" "/home/shop" "$PHP_SOCKET" "prestashop"
webserver_enable_site "nginx" "prestashop"

msg_ok "PrestaShop zainstalowany pomyslnie!"
GATEWAY="$(/sbin/ip route | awk '/default/ { print $3 }')"
IP="$(ip route get ${GATEWAY} | grep -oP 'src \K[^ ]+')"

cat > prestashop.txt <<EOL
PrestaShop jest gotowy do instalacji pod http://${IP}.
Nazwa bazy i uzytkownika: shop
Haslo do bazy: ${DB_PASS}
Haslo FTP/SSH dla uzytkownika shop: ${SSH_PASS}

Po zakonczeniu instalacji usun katalog install:
sudo rm -rf /home/shop/install

Sprawdz nazwe katalogu panelu admina (zaczyna sie od 'admin').
EOL

msg_info "Szczegoly zapisane w prestashop.txt"
