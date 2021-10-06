#!/bin/bash
# Tworzenie nowego uzytkownika, z dostepem do sudo i kopia authorized_keys
# Autor: Radoslaw Karasinski

read -p "Podaj nazwe nowego uzytkownika: " username

if sudo id "$username" &>/dev/null; then
    echo "Podany uzytkownik juz istnieje!"
    exit
fi

# stworz nowego uzytkownika
sudo adduser $username

# dodaj nowego uzytkownika do sudo
sudo usermod -aG sudo $username

SSH_DIR="/home/$username/.ssh"

# stworz folder na ustawienia ssh oraz ustaw odpowiednie prawa
sudo mkdir -p $SSH_DIR
sudo chmod 700 $SSH_DIR

# stworz authorized_keys oraz ustaw odpowiednie prawa
sudo touch $SSH_DIR/authorized_keys
sudo chmod 600 $SSH_DIR/authorized_keys

# zmien wlasciciela folderu i plikow
sudo chown -R $username:$username $SSH_DIR

# skopiuj klucze obecnego uzytkownika do nowo stworzoneg
cat ~/.ssh/authorized_keys | sudo tee -a $SSH_DIR/authorized_keys >/dev/null
