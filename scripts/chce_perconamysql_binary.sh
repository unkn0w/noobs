#!/bin/bash
#Script created by Andrzej "Ferex" Szczepaniak

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

check_number='^[0-9]+$'
if [ -z "$1" ]; then
    echo "Poprawna składnia: ./chce_perconamysql_binary.sh użytkownik_mysql port"
    exit 0
elif [ -z "$2" ]; then
    echo "Poprawna składnia: ./chce_perconamysql_binary.sh użytkownik_mysql port"
    exit 0
else
check_user_exist=$(cat /etc/passwd | grep "$1")
if [[ $check_user_exist == "root" ]]; then
echo "Userem nie może być root!"
exit 0
elif [[ -z $check_user_exist ]] ; then
echo "Podaj poprawnego usera, bo taki nie istnieje."
exit 0
elif ! [[ $2 =~ $check_number ]] ; then
echo "Podany port nie jest liczbą!" >&2
exit 0
else
mkdir /usr/local/mysql
cd /usr/local/mysql/
wget https://downloads.percona.com/downloads/Percona-Server-5.7/Percona-Server-5.7.36-39/binary/tarball/Percona-Server-5.7.36-39-Linux.x86_64.glibc2.12-minimal.tar.gz -O mysql.tar.gz
tar -xzvf mysql.tar.gz --strip-components 1
cd /usr/local/mysql && ./bin/mysqld --initialize-insecure --datadir=/usr/local/mysql/data
mkdir /usr/local/mysql/secure
chown -R "$1":"$1" /usr/local/mysql/
cd /usr/local/mysql && ./bin/mysqld --basedir=/usr/local/mysql/ --datadir=/usr/local/mysql/data --user="$1" --log-error=/usr/local/mysql/data/mysql.err --pid-file=/usr/local/mysql/mysql.pid --secure-file-priv=/usr/local/mysql/secure --socket=/usr/local/mysql/thesock --port="$2" --bind-address=0.0.0.0 &
rm /usr/local/mysql/mysql.tar.gz
echo "cd /usr/local/mysql && ./bin/mysqld --basedir=/usr/local/mysql/ --datadir=/usr/local/mysql/data --user=$1 --log-error=/usr/local/mysql/data/mysql.err --pid-file=/usr/local/mysql/mysql.pid --secure-file-priv=/usr/local/mysql/secure --socket=/usr/local/mysql/thesock --port=$2 --bind-address=0.0.0.0 &" > /root/mysqlstart.sh
echo "W pliku /root/mysqlstart.sh jest zapisane polecenie do odpalenia bazy danych MySQL"
echo "Aby zmienić hasło roota wykonaj polecenie: cd /usr/local/mysql/bin/ && ./mysqladmin --user=root --socket=/usr/local/mysql/thesock --protocol=socket password tuwpiszswojenowehaslo"
echo "Aby z linii poleceń zalogować się do serwera MySQL wydaj polecenie cd /usr/local/mysql/bin/ && ./mysql -u root --socket=/usr/local/mysql/thesock -p"
fi
fi
