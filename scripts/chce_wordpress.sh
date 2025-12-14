#!/bin/bash
#
# Author: Rafal Masiarek <rafal@masiarek.pl>
# Refactored: noobs community (v2.0.0)

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

# Sprawdz uprawnienia root
require_root

# Konfiguracja strefy czasowej
[[ ! -f /etc/localtime ]] && ln -fs /usr/share/zoneinfo/Europe/Warsaw /etc/localtime

# Sprawdz zaleznosc LAMP
if [[ -f /opt/noobs/scripts/chce_LAMP.sh ]]; then
    source /opt/noobs/scripts/chce_LAMP.sh
else
    die "Skrypt chce_LAMP.sh jest niezbedny do dzialania. Zainstaluj LAMP najpierw."
fi

# Instalacja wp-cli
msg_info "Instalowanie WP-CLI..."
download_file "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" "/usr/local/bin/wp"
download_file "https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash" "/etc/bash_completion.d/wp-cli"
chmod +x /usr/local/bin/wp
chmod +x /etc/bash_completion.d/wp-cli

# Przygotowanie katalogu WordPress
wordpress_folder="/var/www/html/wp"
mkdir -p "$wordpress_folder"
chown www-data:www-data "$wordpress_folder"

cd "$wordpress_folder" || die "Nie mozna przejsc do katalogu $wordpress_folder"

# Sprawdz czy WordPress jest juz zainstalowany
if /usr/local/bin/wp core is-installed --allow-root 2>/dev/null; then
    msg_warn "WordPress juz istnieje pod sciezka $wordpress_folder"
    msg_info "Usun go lub zainstaluj recznie pod inna sciezka."
    exit 9
fi

# Tworzenie bazy danych dla WordPress
msg_info "Tworzenie bazy danych dla WordPress..."
DB_NAME="wp_$(generate_random_string 12)"
mysql_create_db_user "$DB_NAME" "$DB_NAME"
DB_PASS="$REPLY"

# Instalacja WordPress z uzyciem wp-cli
msg_info "Pobieranie WordPress..."
WP_CLI_CACHE_DIR=/dev/null /usr/local/bin/wp \
    core download \
    --allow-root \
    --locale=pl_PL

msg_info "Konfigurowanie WordPress..."
/usr/local/bin/wp \
    config create \
    --allow-root \
    --dbname="$DB_NAME" \
    --dbuser="$DB_NAME" \
    --dbpass="$DB_PASS" \
    --locale=pl_PL

# Nadawanie uprawnien na pliki
find . -exec chown www-data:www-data {} \;

# Konfiguracja Apache
msg_info "Konfigurowanie Apache..."
sed -i "s#/var/www/html#$wordpress_folder#g" '/etc/apache2/sites-available/000-default.conf'
apache2ctl -t && apache2ctl graceful

msg_ok "WordPress zainstalowany pomyslnie!"
msg_info "Baza danych: $DB_NAME"
msg_info "Haslo bazy: $DB_PASS"
msg_info "Sciezka: $wordpress_folder"
