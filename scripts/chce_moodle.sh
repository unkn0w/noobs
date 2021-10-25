#!/bin/bash
#Michał Giza

echo -e "\e[1;32mSprawdzenie uprawnień \e[0m"
if [ $EUID != 0 ]
then
	echo "Uruchom poprzez sudo bash chce_moodle.sh lub jako root"
    exit
fi

echo -e "\e[1;32mAktualizacja pakietów \e[0m"
apt update

echo -e "\e[1;32mDodanie repozytorium z PHP \e[0m"
apt install software-properties-common -y
add-apt-repository ppa:ondrej/php -y
apt update

echo -e "\e[1;32mInstalacja pakietów \e[0m"
apt install vsftpd nginx php7.4-fpm php7.4-common php7.4-iconv php7.4-mysql php7.4-curl php7.4-mbstring php7.4-xmlrpc php7.4-soap php7.4-zip php7.4-gd php7.4-xml php7.4-intl php7.4-json libpcre3 libpcre3-dev graphviz aspell ghostscript clamav mariadb-server -y

echo -e "\e[1;32mBlokada dostępu SSH \e[0m"
cat >> /etc/ssh/sshd_config <<EOL
Match User moodle
ChrootDirectory /home/moodle
EOL

echo -e "\e[1;32mRestart SSH \e[0m"
systemctl restart ssh

echo -e "\e[1;32mKonfiguracja FTP \e[0m"
cp /etc/vsftpd.conf /etc/vsftpd.conf.backup
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

echo -e "\e[1;32mRestart vsftpd \e[0m"
systemctl restart vsftpd

echo -e "\e[1;32mDodanie dedykowanego usera dla web servera \e[0m"
SSH_PASS="$(openssl rand -base64 12)"
useradd -m moodle -s /bin/bash
echo moodle:${SSH_PASS} | chpasswd

echo -e "\e[1;32mZmiana ustawień PHP \e[0m"
cat >> /etc/php/7.4/fpm/php.ini <<EOL
max_input_vars = 5000
EOL

echo -e "\e[1;32mUtworzenie dedykowanego PHP pool \e[0m"
cp /etc/php/7.4/fpm/pool.d/www.conf /etc/php/7.4/fpm/pool.d/moodle.conf
cat > /etc/php/7.4/fpm/pool.d/moodle.conf <<EOL
[moodle]
user = moodle
group = moodle
listen = /run/php/moodle.sock
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
EOL

echo -e "\e[1;32mRestart PHP-FPM \e[0m"
systemctl restart php7.4-fpm

echo -e "\e[1;32mZmiana konfiguracji MySQL \e[0m"
cat > /etc/mysql/mariadb.conf.d/50-server.cnf <<EOL
[server]
[mysqld]
innodb_file_format = Barracuda
innodb_large_prefix = 1
user                    = mysql
pid-file                = /run/mysqld/mysqld.pid
socket                  = /run/mysqld/mysqld.sock
#port                   = 3306
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

echo -e "\e[1;32mRestart MySQL \e[0m"
systemctl restart mariadb

echo -e "\e[1;32mTworzenie bazy i usera \e[0m"
HASLO="$(openssl rand -base64 12)"
mysql -e "CREATE DATABASE moodle;"
mysql -e "CREATE USER 'moodle'@'localhost' IDENTIFIED BY '${HASLO}'"
mysql -e "GRANT ALL PRIVILEGES ON moodle.* TO 'moodle'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

echo -e "\e[1;32mPobieranie Moodle \e[0m"
wget https://download.moodle.org/stable311/moodle-3.11.2.tgz -O /tmp/moodle.tgz

echo -e "\e[1;32mRozpakowanie archiwum \e[0m"
tar -zvxf /tmp/moodle.tgz -C /home/moodle
mv /home/moodle/moodle /home/moodle/public_html

echo -e "\e[1;32mZmiana uprawnień \e[0m"
chown moodle:moodle -R /home/moodle/public_html
chmod 755 -R /home/moodle/public_html

echo -e "\e[1;32mUtworzenie katalogu na dane użytkowników \e[0m"
mkdir /var/moodledata
chmod 755 -R /var/moodledata
chown moodle:moodle -R /var/moodledata

echo -e "\e[1;32mDodanie konfiguracji Nginx \e[0m"
unlink /etc/nginx/sites-enabled/default
cat > /etc/nginx/sites-available/moodle <<EOL
server{
   listen 80;
    server_name _;
    root        /home/moodle/public_html;
    index       index.php;
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    location ~ ^(.+\.php)(.*)$ {
        fastcgi_split_path_info ^(.+\.php)(.*)$;
        fastcgi_index           index.php;
        fastcgi_pass           unix:/run/php/moodle.sock;
        include                 /etc/nginx/mime.types;
        include                 fastcgi_params;
        fastcgi_param           PATH_INFO       \$fastcgi_path_info;
        fastcgi_param           SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
}
}
EOL
ln -s /etc/nginx/sites-available/moodle /etc/nginx/sites-enabled/

echo -e "\e[1;32mRestart Nginx \e[0m"
systemctl restart nginx

echo -e "\e[1;32mDalsze instrukcje w pliku moodle.txt \e[0m"
GATEWAY="$(/sbin/ip route | awk '/default/ { print $3 }')"
IP="$(ip route get ${GATEWAY} | grep -oP 'src \K[^ ]+')"
cat > moodle.txt <<EOL
Moodle jest gotowe do instalacji pod http://${IP}.
Katalog danych Moodle to /var/moodledata
Wybierz MariaDB jako typ bazy.
Nazwa bazy i użytkownika to moodle.
Hasło do bazy: ${HASLO}
Hasło FTP dla lokalnego użytkownika moodle: ${SSH_PASS}
EOL
