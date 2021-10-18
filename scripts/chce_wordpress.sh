#!/bin/bash
#
# Author: Rafal Masiarek <rafal@masiarek.pl>

# Check if you are root
[[ $EUID != 0 ]]  && { echo "Please run as root" ; exit; }

# Configuring tzdata if not exist
[[ ! -f /etc/localtime ]] && ln -fs /usr/share/zoneinfo/Europe/Warsaw /etc/localtime

if test -f /opt/noobs/scripts/chce_LAMP.sh; then
    . /opt/noobs/scripts/chce_LAMP.sh
else
    echo "Skrypt https://github.com/unkn0w/noobs/blob/main/scripts/chce_LAMP.sh jest niezbedny do dzialania"
    exit 8
fi

# Instalacja wp-cli
wget -q -O /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
wget -q -O /etc/bash_completion.d/wp-cli  https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash
chmod +x /usr/local/bin/wp
chmod +x /etc/bash_completion.d/wp-cli

wordpress_folder="/var/www/html/wp"
if mkdir -p "$wordpress_folder"; then
    chown www-data:www-data "$wordpress_folder"
fi

cd "$wordpress_folder" || { echo "Directory cannot exist"; exit; }
if ! /usr/local/bin/wp core is-installed --allow-root 2>/dev/null; then

    # Generyczna baza danych
    # https://bash.0x1fff.com/polecenia_wbudowane/polecenie_readonly.html
    readonly DB=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
    readonly DBPASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

    readonly Q1="CREATE DATABASE IF NOT EXISTS wp_$DB;"
    readonly Q2="GRANT ALL ON wp_$DB.* TO 'wp_$DB'@'localhost' IDENTIFIED BY '$DBPASS';"
    readonly Q3="FLUSH PRIVILEGES;"
    readonly SQL="$Q1$Q2$Q3"

    mysql -uroot -e "$SQL"

    # Instalacja wordpressa z uzyciem wp-cli
    # FIX: https://github.com/wp-cli/core-command/issues/30#issuecomment-323069641
    WP_CLI_CACHE_DIR=/dev/null /usr/local/bin/wp \
		core \
		download \
		--allow-root \
		--locale=pl_PL

    /usr/local/bin/wp \
		config \
		create \
		--allow-root \
		--dbname=wp_"$DB" \
		--dbuser=wp_"$DB" \
		--dbpass="$DBPASS" \
		--locale=pl_PL

    # nadawanie uprawnien na pliki
    find . -exec chown www-data:www-data {} \;

    # Zastapienie defaultowej sciezki documentroot w konfiguracji apache2 i pozniejszy restart
    sed -i "s#/var/www/html#$wordpress_folder#g" '/etc/apache2/sites-available/000-default.conf'
    apache2ctl -t && apache2ctl graceful
else
    echo -e "Istnieje juz wordpress pod sciezka $wordpress_folder automayczna instalacja nie jest możliwa.\nJesli to nieuzywany wordpress usun go i ponow skrypt albo zainstaluj wordpressa recznie pod inna sciezka.";
    exit 9
fi
