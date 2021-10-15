#!/bin/bash
# FTP installation script
# Authors: Mariusz 'maniek205' Kowalski

[ "$EUID" -eq 0 ] && { err "Uruchamianie jako root jest niebezpieczne. Uzyj zwyklego uzytkownika."; }
sudo --validate || { err "Nie masz uprawnien do uruchamiania komend jako root - dodaj '$USER' do grupy 'sudoers'."; }

hostname=$(hostname)
listen_port=20${hostname:1}

if sudo lsof -i:"${listen_port}" | grep -q PID ; then
   echo "$listen_port in use trying: "
   listen_port=30${hostname:1}
   echo "$listen_port"
elif sudo lsof -i:"${listen_port}" | grep -q PID ; then
   echo "$listen_port in use error. All external ports are in use. Please release external port 20${hostname:1} or 30${hostname:1}"
   exit 1
fi
echo "Using port: $listen_port"

sudo apt update
sudo apt install -y vsftpd
sudo sed -i 's/#write_enable=YES/write_enable=YES/g' /etc/vsftpd.conf

echo "
listen_port=${listen_port}
" >> /etc/vsftpd.conf

sudo systemctl enable vsftpd
sudo systemctl restart vsftpd

echo "FTP server has been installed. Use your credentials to log in.
Server IP: srvX.mikr.us (change X to your server number)
Port: $listen_port"
