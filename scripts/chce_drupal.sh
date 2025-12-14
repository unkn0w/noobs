#!/usr/bin/env bash
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
php_install_packages "8.0" fpm dom gd xml mysql mbstring

msg_info "Tworzenie uzytkownika drupal"
create_web_user "drupal" "/home/drupal" "/bin/bash" true
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
mysql_create_db_user "drupal" "drupal"
DB_PASS="$REPLY"

msg_info "Zmiana ustawien PHP"
php_configure "8.0" "memory_limit" "768M" "fpm"
php_configure "8.0" "max_execution_time" "3600" "fpm"
php_configure "8.0" "max_input_time" "3600" "fpm"

msg_info "Tworzenie puli PHP-FPM"
php_fpm_create_pool "8.0" "drupal" "drupal"
PHP_SOCKET="$REPLY"
service_restart php8.0-fpm

msg_info "Pobieranie Drupal"
download_and_extract "https://ftp.drupal.org/files/projects/drupal-9.2.8.zip" "/home/drupal/public_html" 0
chown -R drupal:drupal /home/drupal/public_html

msg_info "Konfiguracja Nginx"
webserver_disable_site "nginx" "default"
nginx_create_server_block "drupal" "/home/drupal/public_html" "$PHP_SOCKET" "drupal"
webserver_enable_site "nginx" "drupal"

msg_ok "Drupal zainstalowany pomyslnie!"
GATEWAY="$(/sbin/ip route | awk '/default/ { print $3 }')"
IP="$(ip route get ${GATEWAY} | grep -oP 'src \K[^ ]+')"

cat > drupal.txt <<EOL
Drupal jest gotowy do instalacji pod http://${IP}.
Nazwa bazy i uzytkownika: drupal
Haslo do bazy: ${DB_PASS}
Haslo FTP/SSH dla uzytkownika drupal: ${SSH_PASS}
EOL

msg_info "Szczegoly zapisane w drupal.txt"
