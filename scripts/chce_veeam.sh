#!/bin/bash

echo -e "\e[1;32mSprawdzenie uprawnień \e[0m"
if [ $EUID != 0 ] 
then
	echo "Uruchom poprzez sudo bash chce_veeam.sh lub jako root"
    exit
fi

echo -e "\e[1;32mPobieranie paczki z Veeam \e[0m"
wget https://download2.veeam.com/veeam-release-deb_1.0.8_amd64.deb -O /tmp/veeam.deb

echo -e "\e[1;32mAktualizacja pakietów \e[0m"
apt update

echo -e "\e[1;32mInstalacja xorriso i cifs-utils \e[0m"
apt install xorriso cifs-utils -y

echo -e "\e[1;32mInstalacja paczki \e[0m"
dpkg -i /tmp/veeam.deb

echo -e "\e[1;32mAktualizacja pakietów \e[0m"
apt update

echo -e "\e[1;32mInstalacja Veeam \e[0m"
apt install veeam -y

echo -e "\e[1;32mDodanie możliwości tworzenia recovery ISO \e[0m"
mkdir /etc/systemd/system/veeamservice.service.d
echo "[Service]" >> /etc/systemd/system/veeamservice.service.d/override.conf
echo "LimitNOFILE=524288" >> /etc/systemd/system/veeamservice.service.d/override.conf
echo "LimitNOFILESoft=524288" >> /etc/systemd/system/veeamservice.service.d/override.conf
systemctl daemon-reload
systemctl restart veeamservice.service

echo -e "\e[1;32mVeeam uruchomisz poprzez: sudo veeam \e[0m"
