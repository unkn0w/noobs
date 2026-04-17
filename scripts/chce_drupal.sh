#!/bin/bash
#Michał Giza

echo -e "\e[1;32mSprawdzenie uprawnień \e[0m"
if [ $EUID != 0 ]
then
	echo "Uruchom poprzez sudo bash chce_drupal.sh lub jako root"
    exit
fi


echo -e "\e[1;32mAktualizacja pakietów \e[0m"
apt update

echo -e "\e[1;32mDodanie repozytorium z PHP \e[0m"
apt install software-properties-common -y
add-apt-repository ppa:ondrej/php -y
apt update

echo -e "\e[1;32mInstalacja pakietów \e[0m"
apt install vsftpd unzip nginx mariadb-server php8.0-fpm php8.0-dom php8.0-gd php8.0-xml php8.0-mysql php8.0-mbstring -y

echo -e "\e[1;32mBlokada dostępu SSH \e[0m"
cat >> /etc/ssh/sshd_config <<EOL
Match User drupal
ChrootDirectory /home/drupal
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

echo -e "\e[1;32mTworzenie bazy i usera \e[0m"
HASLO="$(openssl rand -base64 12)"
mysql -e "CREATE DATABASE drupal;"
mysql -e "CREATE USER 'drupal'@'localhost' IDENTIFIED BY '${HASLO}';"
mysql -e "GRANT ALL ON drupal.* TO 'drupal'@'localhost' WITH GRANT OPTION;"
mysql -e "FLUSH PRIVILEGES;"

echo -e "\e[1;32mDodanie dedykowanego usera dla web servera \e[0m"
SSH_PASS="$(openssl rand -base64 12)"
useradd -m drupal -s /bin/bash
echo drupal:${SSH_PASS} | chpasswd

echo -e "\e[1;32mZmiana ustawień PHP \e[0m"
sed -i 's,^memory_limit =.*$,memory_limit = 768M,' /etc/php/8.0/fpm/php.ini
sed -i 's,^max_execution_time =.*$,max_execution_time = 3600,' /etc/php/8.0/fpm/php.ini
sed -i 's,^max_input_time =.*$,max_input_time = 3600,' /etc/php/8.0/fpm/php.ini

echo -e "\e[1;32mUtworzenie dedykowanego PHP pool \e[0m"
cp /etc/php/8.0/fpm/pool.d/www.conf /etc/php/8.0/fpm/pool.d/drupal.conf
cat > /etc/php/8.0/fpm/pool.d/drupal.conf <<EOL
[drupal]
user = drupal
group = drupal
listen = /run/php/drupal.sock
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
EOL

echo -e "\e[1;32mRestart PHP \e[0m"
systemctl restart php8.0-fpm

echo -e "\e[1;32mPobieranie Drupal \e[0m"
su - drupal -c "wget https://ftp.drupal.org/files/projects/drupal-9.2.8.zip"

echo -e "\e[1;32mWypakowywanie do /home/drupal/public_html \e[0m"
su - drupal -c "unzip drupal-9.2.8.zip"
su - drupal -c "rm drupal-9.2.8.zip"
su - drupal -c "mv drupal-9.2.8 public_html"

echo -e "\e[1;32mDodanie konfiguracji Nginx \e[0m"
unlink /etc/nginx/sites-enabled/default
cat > /etc/nginx/sites-available/drupal <<EOL
server {
    server_name _;
    root /home/drupal/public_html;
    location / {
        try_files \$uri /index.php?\$query_string;
    }

    location @rewrite {
        rewrite ^ /index.php;
    }
    location ~ '\.php\$|^/update.php' {
        fastcgi_split_path_info ^(.+?\.php)(|/.*)\$;
        try_files \$fastcgi_script_name =404;
        include fastcgi_params;
        fastcgi_param HTTP_PROXY "";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_param QUERY_STRING \$query_string;
        fastcgi_intercept_errors on;
        fastcgi_pass unix:/run/php/drupal.sock;
    }
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)\$ {
        try_files \$uri @rewrite;
        expires max;
        log_not_found off;
    }
    location ~ ^/sites/.*/files/styles/ {
        try_files \$uri @rewrite;
    }
    location ~ ^(/[a-z\-]+)?/system/files/ {
        try_files \$uri /index.php?\$query_string;
    }
    if (\$request_uri ~* "^(.*/)index\.php/(.*)") {
        return 307 \$1\$2;
    }
}
EOL
ln -s /etc/nginx/sites-available/drupal /etc/nginx/sites-enabled/

echo -e "\e[1;32mRestart Nginx \e[0m"
systemctl restart nginx

echo -e "\e[1;32mDalsze instrukcje w pliku drupal.txt \e[0m"
GATEWAY="$(/sbin/ip route | awk '/default/ { print $3 }')"
IP="$(ip route get ${GATEWAY} | grep -oP 'src \K[^ ]+')"
cat > drupal.txt <<EOL
Drupal jest gotowy do instalacji pod http://${IP}.
Nazwa bazy i użytkownika to drupal.
Hasło do bazy: ${HASLO}
Hasło FTP dla lokalnego użytkownika drupal: ${SSH_PASS}
EOL
