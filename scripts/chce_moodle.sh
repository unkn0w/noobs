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
pkg_install vsftpd nginx libpcre3 libpcre3-dev graphviz aspell ghostscript clamav mariadb-server
php_install_packages "7.4" fpm common mysql curl mbstring xmlrpc soap zip gd xml intl json

msg_info "Tworzenie uzytkownika moodle"
create_web_user "moodle" "/home/moodle" "/bin/bash" true
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

msg_info "Zmiana ustawien PHP"
php_configure "7.4" "max_input_vars" "5000" "fpm"

msg_info "Tworzenie puli PHP-FPM"
php_fpm_create_pool "7.4" "moodle" "moodle"
PHP_SOCKET="$REPLY"
service_restart php7.4-fpm

msg_info "Konfiguracja MySQL"
backup_file /etc/mysql/mariadb.conf.d/50-server.cnf
cat > /etc/mysql/mariadb.conf.d/50-server.cnf <<EOL
[server]
[mysqld]
innodb_file_format = Barracuda
innodb_large_prefix = 1
user                    = mysql
pid-file                = /run/mysqld/mysqld.pid
socket                  = /run/mysqld/mysqld.sock
basedir                 = /usr
datadir                 = /var/lib/mysql
tmpdir                  = /tmp
lc-messages-dir         = /usr/share/mysql
bind-address            = 127.0.0.1
query_cache_size        = 16M
log_error = /var/log/mysql/error.log
expire_logs_days        = 10
character-set-server  = utf8mb4
collation-server      = utf8mb4_general_ci
[embedded]
[mariadb]
[mariadb-10.3]
EOL
service_restart mariadb

msg_info "Tworzenie bazy danych"
mysql_create_db_user "moodle" "moodle"
DB_PASS="$REPLY"

msg_info "Pobieranie i instalacja Moodle"
download_and_extract "https://download.moodle.org/stable311/moodle-3.11.2.tgz" "/home/moodle" 0
mv /home/moodle/moodle /home/moodle/public_html
chown -R moodle:moodle /home/moodle/public_html
chmod -R 755 /home/moodle/public_html

msg_info "Tworzenie katalogu danych"
mkdir -p /var/moodledata
chown -R moodle:moodle /var/moodledata
chmod -R 755 /var/moodledata

msg_info "Konfiguracja Nginx"
webserver_disable_site "nginx" "default"
nginx_create_server_block "moodle" "/home/moodle/public_html" "$PHP_SOCKET" "moodle"
webserver_enable_site "nginx" "moodle"

msg_ok "Moodle zainstalowane pomyslnie!"
GATEWAY="$(/sbin/ip route | awk '/default/ { print $3 }')"
IP="$(ip route get ${GATEWAY} | grep -oP 'src \K[^ ]+')"

cat > moodle.txt <<EOL
Moodle jest gotowe do instalacji pod http://${IP}.
Katalog danych Moodle to /var/moodledata
Wybierz MariaDB jako typ bazy.
Nazwa bazy i uzytkownika: moodle
Haslo do bazy: ${DB_PASS}
Haslo FTP/SSH dla uzytkownika moodle: ${SSH_PASS}
EOL

msg_info "Szczegoly zapisane w moodle.txt"
