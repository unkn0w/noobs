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

check_number='^[0-9]+$'
db_user="$1"
db_port="$2"
line="$3"
sciezka="$4"
service_name="mariadb-${db_user}-${db_port}.service"
service_path="/etc/systemd/system/${service_name}"

if [[ "$db_user" == "root" ]]; then
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

if ! id -u "$db_user" &>/dev/null ; then
useradd -M -N -s /usr/sbin/nologin "$db_user"
fi

mkdir -p "$sciezka"
cd "$sciezka" || exit 1

# Wersje MariaDB od dawna sa numerowane major.minor (np. 11.4, 11.8), nie samym majorem -
# jesli user poda tylko "11" (jak sugeruje komunikat uzycia tego skryptu), rozwiazujemy to
# do najnowszej stabilnej linii minor w ramach tego majora (np. 11 -> 11.8).
resolved_line="$line"
if [[ "$line" =~ ^[0-9]+$ ]]; then
    resolved_line=$(curl -sf "https://downloads.mariadb.org/rest-api/mariadb/" | python3 -c "
import json,sys
d=json.load(sys.stdin)
candidates = [r['release_id'] for r in d.get('major_releases', [])
              if r['release_id'].split('.')[0] == '$line' and r.get('release_status') == 'Stable']
candidates.sort(key=lambda v: [int(x) for x in v.split('.')], reverse=True)
print(candidates[0] if candidates else '')
" 2>/dev/null)
    if [ -z "$resolved_line" ]; then
        echo "Nie znaleziono stabilnej linii MariaDB w obrębie majora ${line}." >&2
        exit 1
    fi
    echo "Linia wersji '${line}' rozwiazana do '${resolved_line}'."
fi

# Oficjalne REST API MariaDB - zwraca najnowszy patch danej linii wersji wraz z URL-em do tarballa
release_json=$(curl -sf "https://downloads.mariadb.org/rest-api/mariadb/${resolved_line}/latest/")
if [ -z "$release_json" ]; then
    echo "Nie udalo sie pobrac informacji o wersji MariaDB ${resolved_line} z downloads.mariadb.org. Sprawdz czy taka linia wersji istnieje." >&2
    exit 1
fi

download_url=$(echo "$release_json" | grep -oP '"file_download_url":\s*"\K[^"]+(?=".*"linux-systemd-x86_64\.tar\.gz)' | head -n1)
if [ -z "$download_url" ]; then
    download_url=$(echo "$release_json" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for rel in d.get('releases', {}).values():
    for f in rel.get('files', []):
        if f.get('os') == 'Linux' and f.get('cpu') == 'x86_64' and 'systemd' in (f.get('file_name') or ''):
            print(f['file_download_url'])
            break
" 2>/dev/null)
fi

if [ -z "$download_url" ]; then
    echo "Nie znaleziono paczki linux-systemd-x86_64 dla linii wersji ${resolved_line}. Przerywam." >&2
    exit 1
fi

if ! wget -L "$download_url" -O "$sciezka"/mariadb.tar.gz; then
    echo "Pobieranie MariaDB nie powiodlo sie (URL: $download_url)." >&2
    exit 1
fi

cd "$sciezka" || exit 1
if ! tar -xzvf mariadb.tar.gz --strip-components 1; then
    echo "Rozpakowanie archiwum MariaDB nie powiodlo sie." >&2
    exit 1
fi
mkdir -p "$sciezka"/mysql_secure "$sciezka"/data
chown -R "$1" "$sciezka"/
rm -f "$sciezka"/mariadb.tar.gz

if [ ! -x "$sciezka/scripts/mariadb-install-db" ]; then
    echo "Brak scripts/mariadb-install-db w rozpakowanym archiwum - instalacja przerwana." >&2
    exit 1
fi

if ! ./scripts/mariadb-install-db --basedir="$sciezka" --datadir="$sciezka/data" --user="$1"; then
    echo "mariadb-install-db zakonczylo sie bledem - serwis systemd nie zostanie utworzony." >&2
    exit 1
fi


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
