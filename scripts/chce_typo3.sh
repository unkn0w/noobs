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
pkg_install vsftpd apache2 mariadb-server curl git gnupg2
php_install_packages "7.4" "" common gmp curl intl mbstring xmlrpc mysql gd xml cli zip
pkg_install libapache2-mod-php7.4

msg_info "Tworzenie uzytkownika cms"
create_web_user "cms" "/home/cms" "/bin/bash" true
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
mysql_create_db_user "cms" "cms"
DB_PASS="$REPLY"

msg_info "Zmiana ustawien PHP"
php_configure "7.4" "memory_limit" "256M" "apache2"
php_configure "7.4" "upload_max_filesize" "100M" "apache2"
php_configure "7.4" "post_max_size" "100M" "apache2"
php_configure "7.4" "max_execution_time" "360" "apache2"
php_configure "7.4" "date.timezone" "Europe/Warsaw" "apache2"
php_configure "7.4" "max_input_vars" "1500" "apache2"
service_restart apache2

msg_info "Pobieranie TYPO3"
download_and_extract "https://get.typo3.org/10.4.21" "/home/cms" 0
mv /home/cms/typo3_src-* /home/cms/public_html

msg_info "Zmiana uprawnien"
chown -R cms:www-data /home/cms/public_html
chmod 2775 /home/cms/public_html
find /home/cms/public_html -type d -exec chmod 2775 {} +
find /home/cms/public_html -type f -exec chmod 0664 {} +

msg_info "Konfiguracja Apache"
webserver_disable_site "apache" "000-default"
apache_create_vhost "cms" "/home/cms/public_html" 80
webserver_enable_site "apache" "cms"
a2enmod rewrite
service_restart apache2

msg_info "Utworzenie pliku FIRST_INSTALL"
sudo -u cms touch /home/cms/public_html/FIRST_INSTALL

msg_ok "TYPO3 zainstalowany pomyslnie!"
GATEWAY="$(/sbin/ip route | awk '/default/ { print $3 }')"
IP="$(ip route get ${GATEWAY} | grep -oP 'src \K[^ ]+')"

cat > typo3.txt <<EOL
TYPO3 jest gotowy do instalacji pod http://${IP}.
Nazwa bazy i uzytkownika: cms
Haslo do bazy: ${DB_PASS}
Haslo FTP/SSH dla uzytkownika cms: ${SSH_PASS}
EOL

msg_info "Szczegoly zapisane w typo3.txt"
