#!/bin/bash
# LAMP = Linux + Apache + MySQL (MariaDB) + PHP
# Autor: Jakub 'unknow' Mrugalski
# Edited and modified by: Andrzej 'Ferex' Szczepaniak, Jarosław 'Evilus' Rauza, Artur 'stefopl' Stefański

function show_help() {
    echo "Użycie: $0 [--php-fpm | --php-mod]"
    echo "Opcje:"
    echo "  --php-fpm      Zainstaluj Apache z FPM/FastCGI"
    echo "  --php-mod      Zainstaluj Apache z mod_php"
    echo "  -h, --help     Wyświetl pomoc"
    echo ""
}

[[ $EUID != 0 ]]  && { echo "Uruchom jako root" ; exit; }

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
            echo "Błąd: Nieprawidłowa opcja '$arg'."
            show_help
            exit 1
            ;;
    esac
done

apt update
apt install -y software-properties-common

# Repozytoria zewnętrzne z najnowszymi PHP i Apache2 (nie ma ich w standardowym Ubuntu)
add-apt-repository -y ppa:ondrej/apache2
add-apt-repository -y ppa:ondrej/php

# Instalacja Apache2 oraz popularnych modułów PHP
if [ "$USE_PHP_FPM" = true ]; then
    apt install -y apache2 libapache2-mod-fcgid php php-fpm php-curl php-common php-igbinary php-imagick php-intl php-mbstring php-xml php-zip php-bcmath php-gd php-cli php-memcached php-memcache php-sqlite3 php-pgsql php-mysql php-mcrypt
    # Zmiana mpm_prefork na mpm_event mpm-prefork działa kiedy instalujemy libapache2-mod-php a mpm_event dla php-fpm
    a2dismod mpm_prefork
    if ! apache2ctl -M | grep -q 'mpm_event'; then
        a2enmod mpm_event
    fi
    # Aktywacja konfiguracji modułu php-fpm dla apache2
    PHP_VERSION="$(/usr/bin/php.default -v | head -1 | cut -c5-7)"
    a2enconf php"$PHP_VERSION"-fpm
    a2enmod rewrite setenvif proxy proxy_fcgi
else
    apt install -y apache2 libapache2-mod-php php php-curl php-common php-igbinary php-imagick php-intl php-mbstring php-xml php-zip php-bcmath php-gd php-cli php-sqlite3 php-pgsql php-mysql php-mcrypt

    PHP_VERSION="$(/usr/bin/php.default -v | head -1 | cut -c5-7)"
    a2disconf php"$PHP_VERSION"-fpm
    a2dismod mpm_event
    if ! apache2ctl -M | grep -q 'mpm_prefork'; then
        a2enmod php"$PHP_VERSION"
        a2enmod mpm_prefork
    fi
    a2enmod rewrite
fi

# Restart Apache
systemctl restart apache2

# Instalacja MariaDB (klient i serwer)
apt install -y mariadb-server mariadb-client
# Uruchomienie serwera mariadb
systemctl start mariadb
# Dodanie MariaDB i Apache2 do autostartu
systemctl enable apache2
systemctl enable mariadb


if [ -f /var/www/html/index.html ]; then
    echo "Plik /var/www/html/index.html istnieje. Usuwanie..."
    rm /var/www/html/index.html
fi

if [ -f /var/www/html/index.php ]; then
    read -p "Plik /var/www/html/index.php już istnieje. Czy chcesz go nadpisać? (t/n): " choice
    if [[ "$choice" != "t" ]]; then
        echo "Plik nie został nadpisany."
        exit 0
    fi
fi

echo '<?php
echo "<h1>Test PHP</h1>";
echo "<p>Wynik dodawania 2 + 2 = " . (2 + 2) . "</p>";
echo "<p>Aktualny czas: " . date("d.m.Y H:i:s") . "</p>";
echo "<p>Wersja PHP: " . phpversion() . "</p>";
echo "<p>Server API: " . php_sapi_name() . "</p>";
echo "<p>Domyślna strona utworzona za pomocą skryptu <a href=\"https://github.com/unkn0w/noobs/\">NOOBS</a> <a href=\"https://github.com/unkn0w/noobs/blob/main/scripts/chce_LAMP.sh\">chce_LAMP.sh</a></p>";
?>' >/var/www/html/index.php

# == Lekki hardening ustawień ==
# Serwer ma się nie doklejać swojej stopki nigdzie
sed -i -e "s/^ServerSignature OS*.*\$/ServerSignature Off/" '/etc/apache2/conf-available/security.conf'
# Serwer będzie się przedstawiał jako "Apache" - bez wersji softu i OS
sed -i -e "s/^ServerTokens OS*.*\$/ServerTokens Prod/" '/etc/apache2/conf-available/security.conf'

# Restart Apache
systemctl restart apache2
