#!/bin/bash
#Michał Giza

echo -e "\e[1;32mSprawdzenie uprawnień \e[0m"
if [ $EUID != 0 ]
then
	echo "Uruchom poprzez sudo bash chce_prestashop.sh lub jako root"
    exit
fi


echo -e "\e[1;32mAktualizacja pakietów \e[0m"
apt update

echo -e "\e[1;32mDodanie repozytorium z PHP \e[0m"
apt install software-properties-common -y
add-apt-repository ppa:ondrej/php -y
apt update

echo -e "\e[1;32mInstalacja pakietów \e[0m"
apt install vsftpd unzip nginx mariadb-server php7.4-fpm php7.4-common php7.4-mysql php7.4-gmp php7.4-curl php7.4-intl php7.4-mbstring php7.4-xmlrpc php7.4-gd php7.4-xml php7.4-cli php7.4-zip -y

echo -e "\e[1;32mBlokada dostępu SSH \e[0m"
cat >> /etc/ssh/sshd_config <<EOL
Match User shop
ChrootDirectory /home/shop
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
mysql -e "CREATE DATABASE shop;"
mysql -e "CREATE USER 'shop'@'localhost' IDENTIFIED BY '${HASLO}';"
mysql -e "GRANT ALL ON shop.* TO 'shop'@'localhost' WITH GRANT OPTION;"
mysql -e "FLUSH PRIVILEGES;"

echo -e "\e[1;32mDodanie dedykowanego usera dla web servera \e[0m"
SSH_PASS="$(openssl rand -base64 12)"
useradd -m shop -s /bin/bash
echo shop:${SSH_PASS} | chpasswd

echo -e "\e[1;32mZmiana ustawień PHP \e[0m"
sed -i 's,^file_uploads =.*$,file_uploads = On,' /etc/php/7.4/fpm/php.ini
sed -i 's,^allow_url_fopen =.*$,allow_url_fopen = On,' /etc/php/7.4/fpm/php.ini
sed -i 's,^short_open_tag =.*$,short_open_tag = On,' /etc/php/7.4/fpm/php.ini
sed -i 's,^memory_limit =.*$,memory_limit = 256M,' /etc/php/7.4/fpm/php.ini
sed -i 's,^upload_max_filesize =.*$,upload_max_filesize = 100M,' /etc/php/7.4/fpm/php.ini
sed -i 's,^max_execution_time =.*$,max_execution_time = 360,' /etc/php/7.4/fpm/php.ini
cat >> /etc/php/7.4/fpm/php.ini <<EOL
cgi.fix_pathinfo = 0
date.timezone = Europe/Warsaw
EOL

echo -e "\e[1;32mUtworzenie dedykowanego PHP pool \e[0m"
cp /etc/php/7.4/fpm/pool.d/www.conf /etc/php/7.4/fpm/pool.d/shop.conf
cat > /etc/php/7.4/fpm/pool.d/shop.conf <<EOL
[shop]
user = shop
group = shop
listen = /run/php/shop.sock
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
EOL

echo -e "\e[1;32mRestart PHP \e[0m"
systemctl restart php7.4-fpm

echo -e "\e[1;32mPobieranie PrestaShop \e[0m"
wget https://download.prestashop.com/download/releases/prestashop_1.7.7.8.zip -O /tmp/prestashop_main.zip

echo -e "\e[1;32mWypakowywanie do /home/shop i usunięcie niepotrzebnych plików \e[0m"
unzip /tmp/prestashop_main.zip
rm Install_PrestaShop.html index.php
unzip prestashop.zip -d /home/shop
rm prestashop.zip

echo -e "\e[1;32mDostosowanie uprawnień \e[0m"
chown -R shop:shop /home/shop
chmod -R 755 /home/shop
chmod -R 777 /home/shop/var

echo -e "\e[1;32mDodanie konfiguracji Nginx \e[0m"
unlink /etc/nginx/sites-enabled/default
mv prestashop /etc/nginx/sites-available/prestashop
ln -s /etc/nginx/sites-available/prestashop /etc/nginx/sites-enabled/

echo -e "\e[1;32mRestart Nginx \e[0m"
systemctl restart nginx

echo -e "\e[1;32mDalsze instrukcje w pliku prestashop.txt \e[0m"
GATEWAY="$(/sbin/ip route | awk '/default/ { print $3 }')"
IP="$(ip route get ${GATEWAY} | grep -oP 'src \K[^ ]+')"
cat > prestashop.txt <<EOL
PrestaShop jest gotowa do instalacji pod http://${IP}.
Nazwa bazy i użytkownika to shop.
Hasło do bazy: ${HASLO}
Hasło FTP dla lokalnego użytkownika shop: ${SSH_PASS}

Po zakończonej instalacji usuń katalog install: sudo rm -rf /home/shop/install (lub poprzez FTP)
Sprawdź, pod jakim adresem jest panel administratora.
Nazwa katalogu w /home/shop zaczyna się od 'admin'.
W pliku /etc/nginx/sites-enabled/prestashop zamień 'CHANGE' (2x) na nazwę katalogu z panelem.
Następnie wykonaj sudo systemctl restart nginx
EOL
