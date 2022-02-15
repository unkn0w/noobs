#!/bin/bash
#Script created by Andrzej "Ferex" Szczepaniak
check_number='^[0-9]+$'
if [ -z "$1" ]; then
    echo "Poprawna składnia: ./chce_mariadb_binary.sh użytkownik_mysql port"
    exit 0
elif [ -z "$2" ]; then
    echo "Poprawna składnia: ./chce_mariadb_binary.sh użytkownik_mysql port"
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
dbver1=$(curl https://mariadb.com/kb/en/changes-improvements-in-mariadb-106/ | grep -Eo 'MariaDB 10.6.([0-9])' | head -1 | awk '{print $2}')
wget https://mirror.vpsfree.cz/mariadb//mariadb-"$dbver1"/bintar-linux-systemd-x86_64/mariadb-"$dbver1"-linux-systemd-x86_64.tar.gz -O /usr/local/mysql/mariadb.tar.gz
cd /usr/local/mysql/ && tar -xzvf mariadb.tar.gz --strip-components 1
mkdir /usr/local/mysql/mysql_secure
rm *.tar.gz
./scripts/mysql_install_db --user="$2"
chown -R "$2" /usr/local/mysql
cd /usr/local/mysql && ./bin/mysqld --basedir=/usr/local/mysql/ --datadir=/usr/local/mysql/data --user="$2" --log-error=/usr/local/mysql/data/mysql.err --pid-file=/usr/local/mysql/mysql.pid --secure-file-priv=/usr/local/mysql/mysql_secure --socket=/usr/local/mysql/thesock --port="$2" &
echo "cd /usr/local/mysql && ./bin/mysqld --basedir=/usr/local/mysql/ --datadir=/usr/local/mysql/data --user=$2 --log-error=/usr/local/mysql/data/mysql.err --pid-file=/usr/local/mysql/mysql.pid --secure-file-priv=/usr/local/mysql/mysql_secure --socket=/usr/local/mysql/thesock --port=$2 &" > /root/mysqlstart.sh
echo "W pliku /root/mysqlstart.sh jest zapisane polecenie do odpalenia bazy danych MySQL"
echo "Aby zmienić hasło roota wykonaj polecenie: cd /usr/local/mysql/bin/ && ./mysqladmin --user=root --socket=/usr/local/mysql/thesock --protocol=socket password tuwpiszswojenowehaslo"
echo "Aby z linii poleceń zalogować się do serwera MySQL wydaj polecenie cd /usr/local/mysql/bin/ && ./mysql -u root -P 3306 -p"
fi
fi
