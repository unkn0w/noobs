#!/bin/bash
# FTP installation script
# Autors: Mariusz 'maniek205' Kowalski

apt update
apt install -y vsftpd systemctl
sed -i 's/#write_enable=YES/write_enable=YES/g' /etc/vsftpd.conf
systemctl enable vsftpd
systemctl start vsftpd

echo "FTP server has installed. Use your credentials to log in on port 21"