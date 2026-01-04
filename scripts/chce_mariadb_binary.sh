#!/bin/bash
#Script created by Andrzej "Ferex" Szczepaniak
if [ -z "$1" ]; then
    echo "Poprawna składnia: ./chce_mariadb_binary.sh użytkownik_mysql port linia_wersji sciezka"
    echo "Gdzie:"
    echo "linia_wersji to np. 10, 11, 12"
    echo "sciezka - miejsce gdzie ma zostac zainstalowany serwer MariaDB"
    exit 1
elif [ -z "$2" ]; then
    echo "Poprawna składnia: ./chce_mariadb_binary.sh użytkownik_mysql port linia_wersji sciezka"
    echo "Gdzie:"
    echo "linia_wersji to np. 10, 11, 12"
    echo "sciezka - miejsce gdzie ma zostac zainstalowany serwer MariaDB"
    exit 1
elif [ -z "$3" ]; then
    echo "Poprawna składnia: ./chce_mariadb_binary.sh użytkownik_mysql port linia_wersji sciezka"
    echo "Gdzie:"
    echo "linia_wersji to np. 10, 11, 12"
    echo "sciezka - miejsce gdzie ma zostac zainstalowany serwer MariaDB"
    exit 1
elif [ -z "$4" ]; then
    echo "Poprawna składnia: ./chce_mariadb_binary.sh użytkownik_mysql port linia_wersji sciezka"
    echo "Gdzie:"
    echo "linia_wersji to np. 10, 11, 12"
    echo "sciezka - miejsce gdzie ma zostac zainstalowany serwer MariaDB"
    exit 1
else

apt install w3m -y

check_user_exist=$(cat /etc/passwd | grep "$1")
check_number='^[0-9]+$'
db_user="$1"
db_port="$2"
line="$3"
sciezka="$4"
service_name="mariadb-${db_user}-${db_port}.service"
service_path="/etc/systemd/system/${service_name}"

if [[ $check_user_exist == "root" ]]; then
echo "Userem nie może być root!"
exit 1
fi

if ! [[ $db_port =~ $check_number ]] ; then
echo "Podany port nie jest liczbą!" >&2
exit 1
fi

if [ -z $line ]; then
    echo "Użycie: $0 <linia wersji, np. 10, 11, 12>"
    exit 1
fi

if [[ -z $check_user_exist ]] ; then
useradd -M -N -s /usr/sbin/nologin "$db_user"
fi

mkdir -p "$sciezka"
cd "$sciezka"
versions=$(curl https://mariadb.com/docs/release-notes/latest-releases | w3m -dump -T text/html | grep -oP 'MariaDB\s\d+\.\d+(\.\d+)?' | sed 's/MariaDB\s//' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -u)
latest=$(echo "$versions" | grep "^$line\." | sort -V | tail -n1)
wget https://mirror.vpsfree.cz/mariadb/mariadb-"$latest"/bintar-linux-systemd-x86_64/mariadb-"$latest"-linux-systemd-x86_64.tar.gz -O "$4"/mariadb.tar.gz
cd "$sciezka" && tar -xzvf mariadb.tar.gz --strip-components 1
mkdir -p "$sciezka"/mysql_secure "$sciezka"/data
chown -R "$1" "$sciezka"/
rm *.tar.gz
./scripts/mariadb-install-db --basedir="$sciezka" --datadir="$sciezka/data" --user="$1"


cat > "$service_path" <<EOF
[Unit]
Description=MariaDB (${db_user}, port ${db_port})
After=network.target
Wants=network.target

[Service]
Type=simple
User=${db_user}

WorkingDirectory=${sciezka}

ExecStart=${sciezka}/bin/mariadbd \\
  --basedir=${sciezka} \\
  --datadir=${sciezka}/data \\
  --user=${db_user} \\
  --log-error=${sciezka}/data/mysql.err \\
  --pid-file=${sciezka}/mysql.pid \\
  --secure-file-priv=${sciezka}/mysql_secure \\
  --socket=${sciezka}/thesock \\
  --port=${db_port}

Restart=on-failure
RestartSec=5s
LimitNOFILE=65536

KillMode=process
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now "$service_name"

echo "==================================================================================================================================================================="
echo "Aby zmienić hasło roota wykonaj polecenie: cd $sciezka/bin/ && ./mysqladmin --user=root --socket=$sciezka/thesock --protocol=socket password tuwpiszswojenowehaslo"
echo "Aby z linii poleceń zalogować się do serwera MySQL wydaj polecenie: cd $sciezka/bin/ && ./mysql -u root -P $2 -p"
echo "==================================================================================================================================================================="

fi
