#!/bin/bash
#Script created by Andrzej "Ferex" Szczepaniak
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
# Stary binarny Percona Server 5.7 wymaga libaio.so.1; Ubuntu 24.04+ ma tylko libaio1t64 (t64 transition)
apt-get install -y libaio1t64 || apt-get install -y libaio1 || { echo "Nie udalo sie zainstalowac libaio - mysqld sie nie uruchomi."; exit 1; }

# Grupa dla usera moze nie nazywac sie tak samo jak user (zalezy od USERGROUPS_ENAB)
user_group=$(id -gn "$1")

mkdir /usr/local/mysql
cd /usr/local/mysql/ || exit 1
if ! wget https://downloads.percona.com/downloads/Percona-Server-5.7/Percona-Server-5.7.36-39/binary/tarball/Percona-Server-5.7.36-39-Linux.x86_64.glibc2.12-minimal.tar.gz -O mysql.tar.gz; then
    echo "Pobieranie Percona Server nie powiodlo sie."
    exit 1
fi
if ! tar -xzvf mysql.tar.gz --strip-components 1; then
    echo "Rozpakowanie archiwum Percona Server nie powiodlo sie."
    exit 1
fi
if ! ./bin/mysqld --initialize-insecure --datadir=/usr/local/mysql/data; then
    echo "mysqld --initialize-insecure zakonczylo sie bledem - przerywam."
    exit 1
fi
mkdir /usr/local/mysql/secure
chown -R "$1":"$user_group" /usr/local/mysql/
cd /usr/local/mysql && ./bin/mysqld --basedir=/usr/local/mysql/ --datadir=/usr/local/mysql/data --user="$1" --log-error=/usr/local/mysql/data/mysql.err --pid-file=/usr/local/mysql/mysql.pid --secure-file-priv=/usr/local/mysql/secure --socket=/usr/local/mysql/thesock --port="$2" --bind-address=0.0.0.0 &
sleep 2
if ! kill -0 $! 2>/dev/null; then
    echo "mysqld nie wystartowal - sprawdz /usr/local/mysql/data/mysql.err"
    exit 1
fi
rm /usr/local/mysql/mysql.tar.gz
echo "cd /usr/local/mysql && ./bin/mysqld --basedir=/usr/local/mysql/ --datadir=/usr/local/mysql/data --user=$1 --log-error=/usr/local/mysql/data/mysql.err --pid-file=/usr/local/mysql/mysql.pid --secure-file-priv=/usr/local/mysql/secure --socket=/usr/local/mysql/thesock --port=$2 --bind-address=0.0.0.0 &" > /root/mysqlstart.sh
echo "W pliku /root/mysqlstart.sh jest zapisane polecenie do odpalenia bazy danych MySQL"
echo "Aby zmienić hasło roota wykonaj polecenie: cd /usr/local/mysql/bin/ && ./mysqladmin --user=root --socket=/usr/local/mysql/thesock --protocol=socket password tuwpiszswojenowehaslo"
echo "Aby z linii poleceń zalogować się do serwera MySQL wydaj polecenie cd /usr/local/mysql/bin/ && ./mysql -u root --socket=/usr/local/mysql/thesock -p"
fi
fi
