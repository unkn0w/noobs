#!/bin/bash
#Michał Giza

echo -e "\e[1;32mSprawdzenie uprawnień \e[0m"
if [ $EUID != 0 ] 
then
	echo "Uruchom poprzez sudo bash chce_typo3.sh lub jako root"
    exit
fi

echo -e "\e[1;32mAktualizacja pakietów \e[0m"
apt update

echo -e "\e[1;32mDodanie repozytorium z PHP \e[0m"
apt install software-properties-common -y
add-apt-repository ppa:ondrej/php -y
apt update

echo -e "\e[1;32mInstalacja pakietów \e[0m"
apt install vsftpd apache2 mariadb-server php7.4 libapache2-mod-php7.4 php7.4-common php7.4-gmp php7.4-curl php7.4-intl php7.4-mbstring php7.4-xmlrpc php7.4-mysql php7.4-gd php7.4-xml php7.4-cli php7.4-zip curl git gnupg2 -y

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
useradd -m cms -s /bin/bash
echo cms:${SSH_PASS} | chpasswd

echo -e "\e[1;32mBlokada dostępu SSH \e[0m"
cat >> /etc/ssh/sshd_config <<EOL
Match User cms
ChrootDirectory /home/cms
EOL

echo -e "\e[1;32mRestart SSH \e[0m"
systemctl restart ssh

echo -e "\e[1;32mZmiana ustawień PHP \e[0m"
sed -i 's,^memory_limit =.*$,memory_limit = 256M,' /etc/php/7.4/apache2/php.ini
sed -i 's,^upload_max_filesize =.*$,upload_max_filesize = 100M,' /etc/php/7.4/apache2/php.ini
sed -i 's,^post_max_size =.*$,post_max_size = 100M,' /etc/php/7.4/apache2/php.ini
sed -i 's,^max_execution_time =.*$,max_execution_time = 360,' /etc/php/7.4/apache2/php.ini
sed -i 's,^date.timezone =.*$,date.timezone = Europe/Warsaw,' /etc/php/7.4/apache2/php.ini
cat >> /etc/php/7.4/apache2/php.ini <<EOL
max_input_vars = 1500
EOL

echo -e "\e[1;32mRestart Apache \e[0m"
systemctl restart apache2

echo -e "\e[1;32mTworzenie bazy i usera \e[0m"
HASLO="$(openssl rand -base64 12)"
mysql -e "CREATE DATABASE cms;"
mysql -e "CREATE USER 'cms'@'localhost' IDENTIFIED BY '${HASLO}';"
mysql -e "GRANT ALL ON cms.* TO 'cms'@'localhost' WITH GRANT OPTION;"
mysql -e "FLUSH PRIVILEGES;"

echo -e "\e[1;32mPobieranie TYPO3 \e[0m"
curl -L -o /tmp/typo3_src.tgz https://get.typo3.org/10.4.21

echo -e "\e[1;32mRozpakowanie archwium \e[0m"
tar -xvzf /tmp/typo3_src.tgz

echo -e "\e[1;32mPrzeniesienie katalogu z TYPO3 do /home/cms \e[0m"
mv typo3_src-10.4.21 /home/cms

echo -e "\e[1;32mZmiana nazwy katalogu na public_html \e[0m"
mv /home/cms/typo3_src-10.4.21 /home/cms/public_html

echo -e "\e[1;32mZmiana uprawnień na odpowiednie \e[0m"
chown -R cms:www-data /home/cms/public_html
chmod 2775 /home/cms/public_html
find /home/cms/public_html -type d -exec chmod 2775 {} +
find /home/cms/public_html -type f -exec chmod 0664 {} +

echo -e "\e[1;32mZapisanie konfiguracji Apache \e[0m"
cat > /etc/apache2/sites-available/cms.conf <<EOL
<VirtualHost *:80>
     DocumentRoot /home/cms/public_html
     <Directory /home/cms/public_html>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
     </Directory>

     ErrorLog ${APACHE_LOG_DIR}/typo3_error.log
     CustomLog ${APACHE_LOG_DIR}/typo3_access.log combined

</VirtualHost>
EOL

echo -e "\e[1;32mAktywacja virtual hosta i wyłączenie domyślnej strony Apache \e[0m"
a2ensite cms.conf
a2dissite 000-default.conf

echo -e "\e[1;32mAktywacja mod_rewrite \e[0m"
a2enmod rewrite

echo -e "\e[1;32mRestart Apache \e[0m"
systemctl restart apache2

echo -e "\e[1;32mUtworzenie koniecznego pliku FIRST_INSTALL \e[0m"
sudo -u cms touch /home/cms/public_html/FIRST_INSTALL

echo -e "\e[1;32mDalsze instrukcje w pliku typo3.txt \e[0m"
GATEWAY="$(/sbin/ip route | awk '/default/ { print $3 }')"
IP="$(ip route get ${GATEWAY} | grep -oP 'src \K[^ ]+')"
cat > typo3.txt <<EOL
TYPO3 jest gotowy do instalacji pod http://${IP}.
Nazwa bazy i użytkownika to cms.
Hasło do bazy: ${HASLO}
Hasło FTP dla lokalnego użytkownika cms: ${SSH_PASS}
EOL
