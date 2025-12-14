#!/bin/bash
# LAMP = Linux + Apache + MySQL (MariaDB) + PHP
# Autor: Jakub 'unknow' Mrugalski
# Edited and modified by: Andrzej 'Ferex' Szczepaniak, Jarosław 'Evilus' Rauza, Artur 'stefopl' Stefański
# Refactored: noobs community (v2.0.0)

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

function show_help() {
    echo "Uzycie: $0 [--php-fpm | --php-mod]"
    echo "Opcje:"
    echo "  --php-fpm      Zainstaluj Apache z FPM/FastCGI"
    echo "  --php-mod      Zainstaluj Apache z mod_php"
    echo "  -h, --help     Wyswietl pomoc"
    echo ""
}

require_root

USE_PHP_FPM=false

if [[ $# -eq 0 ]]; then
    show_help
fi

for arg in "$@"; do
    case $arg in
        --php-fpm)
            USE_PHP_FPM=true
            ;;
        --php-mod)
            USE_PHP_FPM=false
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            msg_err "Nieprawidlowa opcja '$arg'."
            show_help
            exit 1
            ;;
    esac
done

msg_info "Aktualizacja pakietow"
pkg_update
pkg_install software-properties-common

msg_info "Dodawanie repozytoriow zewnetrznych"
add_ppa_repo "ondrej/apache2"
add_ppa_repo "ondrej/php"

msg_info "Instalacja Apache i PHP"
if [ "$USE_PHP_FPM" = true ]; then
    pkg_install apache2 libapache2-mod-fcgid
    php_install_packages "" fpm curl common igbinary imagick intl mbstring xml zip bcmath gd cli memcached memcache sqlite3 pgsql mysql mcrypt

    # Zmiana mpm_prefork na mpm_event
    a2dismod mpm_prefork
    if ! apache2ctl -M | grep -q 'mpm_event'; then
        a2enmod mpm_event
    fi

    # Aktywacja konfiguracji php-fpm dla apache2
    PHP_VERSION="$(/usr/bin/php.default -v | head -1 | cut -c5-7)"
    a2enconf php"$PHP_VERSION"-fpm
    a2enmod rewrite setenvif proxy proxy_fcgi
else
    pkg_install apache2 libapache2-mod-php
    php_install_packages "" "" curl common igbinary imagick intl mbstring xml zip bcmath gd cli sqlite3 pgsql mysql mcrypt

    PHP_VERSION="$(/usr/bin/php.default -v | head -1 | cut -c5-7)"
    a2disconf php"$PHP_VERSION"-fpm 2>/dev/null || true
    a2dismod mpm_event 2>/dev/null || true
    if ! apache2ctl -M | grep -q 'mpm_prefork'; then
        a2enmod php"$PHP_VERSION"
        a2enmod mpm_prefork
    fi
    a2enmod rewrite
fi

service_restart apache2

msg_info "Instalacja MariaDB"
pkg_install mariadb-server mariadb-client
service_start mariadb

msg_info "Dodanie uslug do autostartu"
service_enable apache2
service_enable mariadb

msg_info "Tworzenie strony testowej PHP"
rm -f /var/www/html/index.html

if [ -f /var/www/html/index.php ]; then
    if ! confirm_action "Plik /var/www/html/index.php juz istnieje. Nadpisac?"; then
        msg_info "Plik nie zostal nadpisany."
        exit 0
    fi
fi

cat > /var/www/html/index.php <<'EOL'
<?php
echo "<h1>Test PHP</h1>";
echo "<p>Wynik dodawania 2 + 2 = " . (2 + 2) . "</p>";
echo "<p>Aktualny czas: " . date("d.m.Y H:i:s") . "</p>";
echo "<p>Wersja PHP: " . phpversion() . "</p>";
echo "<p>Server API: " . php_sapi_name() . "</p>";
echo "<p>Domyslna strona utworzona za pomoca skryptu <a href=\"https://github.com/unkn0w/noobs/\">NOOBS</a></p>";
?>
EOL

msg_info "Hardening Apache"
sed -i -e "s/^ServerSignature OS*.*$/ServerSignature Off/" '/etc/apache2/conf-available/security.conf'
sed -i -e "s/^ServerTokens OS*.*$/ServerTokens Prod/" '/etc/apache2/conf-available/security.conf'

service_restart apache2

msg_ok "LAMP zainstalowany pomyslnie!"
