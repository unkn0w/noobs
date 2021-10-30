#!/bin/bash
# Author: Borys Gnaciński
path=""

if [ $EUID != 0 ]
then
    echo "Uruchom skrypt jako root."
    exit
fi

echo "[*] Instalowanie potrzebnych paczek..."
sudo apt update
sudo apt install -y samba

echo "[*] Próba ustawienia katalogu udostępnianiego przez serwer SMB"
if ! [ -d "/storage" ]
then
    echo "[*] Tworzenie katalogu o nazwie 'share'. Będzie on udostępniany przez serwer SMB."
    if ! [ -d "$HOME/share" ]
    then
        mkdir -p "$HOME/share"
        path="$HOME/share"
    else
        echo "[!] Katalog istnieje, pomijanie"
        path="$HOME/share"
    fi
else
    echo "[*] Tworzenie katalogu o nazwie 'share'. Będzie on udostępniany przez serwer SMB."
    if ! [ -d "/storage/share" ]
    then
        mkdir -p "/storage/share"
        path="/storage/share"
    else
        echo "[!] Katalog istnieje, pomijanie"
        path="/storage/share"
    fi
fi

echo "---------------------------------------------"
echo "[*] Ustawianie katalogu przebiegło pomyślnie."
echo "[*] Udostępniany katalog: '$path'"

echo "[*] Dodawanie niezbędnych konfiguracji..."
echo "[share]" >> /etc/samba/smb.conf
echo "    comment = Samba dla $USER" >> /etc/samba/smb.conf
echo "    path = $path" >> /etc/samba/smb.conf
echo "    read only = no" >> /etc/samba/smb.conf 
echo "    browsable = yes" >> /etc/samba/smb.conf 
echo "    create mask = 0775" >> /etc/samba/smb.conf
echo "    directory mask = 0775" >> /etc/samba/smb.conf

echo "[*] Restartowanie serwera samba i dodawanie go do autostartu"
sudo service smbd restart
sudo systemctl enable smbd

echo "[!] Ustaw hasło dla użytkownika '$USER':"
sudo smbpasswd -a $USER
sudo smbpasswd -e $USER

echo "[*] Zakończono skrypt."
echo "----------------------"
echo "W razie błędu podczas ustawiania hasła:"
echo " - Uruchom 'sudo smbpasswd -a $USER'"
echo " - Uruchom 'sudo smbpasswd -e $USER'"