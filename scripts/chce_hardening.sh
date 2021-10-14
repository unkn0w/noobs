#!/bin/bash
#Author Borys Gnaciński

# privileges check
if [ $EUID != 0 ] 
then
    echo "Uruchom skrypt jako root."
    exit
fi

primary_user="$(ls /home/ | head -1)"

# ssh securing
securing_ssh(){
    echo "" > /etc/ssh/sshd_config # cleaning config
    echo "Include /etc/ssh/sshd_config.d/*.conf" >> /etc/ssh/sshd_config
    echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config
    echo "AuthorizedKeysFile      .ssh/authorized_keys" >> /etc/ssh/sshd_config
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
    echo "AllowGroups ssh_group" >> /etc/ssh/sshd_config
    echo "X11Forwarding no" >> /etc/ssh/sshd_config
    echo "PermitRootLogin without-password" >> /etc/ssh/sshd_config
    echo "MaxAuthTries 3" >> /etc/ssh/sshd_config
    echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config
    echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config
}

# installing specified packages
package_installation(){
    sudo apt update
    sudo apt install -y lynis debsums unattended-upgrades apt-show-versions
    sudo apt install -y logwatch
}

# setting up cron
cron_job_setup(){
    echo -e "#!/bin/bash\n#Check if removed-but-not-purged\ntest -x /usr/share/logwatch/scripts/logwatch.pl || exit 0\n#execute\n/usr/sbin/logwatch --detail high" > /etc/cron.daily/00logwatch
    chmod +x /etc/cron.daily/00logwatch
}

# ---

if ! [ "$primary_user" ]
then
    echo "[!] Nie znaleziono innych użytkowników. W systemie musi być inny użytkownik żebyś nie stracił dostępu do serwera."
    echo "Możesz to zrobić używając skryptu 'chce_usera.sh'"
    exit
fi

echo "----------------------------------------------------------------------------------"
echo "[!] Domyślny użytkownik to '$primary_user'. Zostanie on dodany do grupy 'ssh_group'."
echo "----------------------------------------------------------------------------------"
echo "[!] Uwaga! Ten skrypt: "
echo " - wyłącza logowania hasłem", 
echo " - wyłącza możliwość logowania HASŁEM na konto root(przez ssh)"
echo " - ustawia maksymalną ilośc prób uwierzytelnienia na 3"
echo " - wyłącza możliwość używania GUI przez ssh(X11Forwarding)"
echo " - włącza uwierzytelnienie kluczem publicznym"
echo "----------------------------------------------------------------------------------"

echo "[!] W kolejnym kroku zostaną pobrane różne pakiety. Podczas jednego z nich wyświetli się zapytanie o konfigurację, wybierz opcję 'brak konfiguracji'."
read -p "Rozumiem (Enter)"
echo "[*] Instalowanie potrzebnych pakietów..."
package_installation

echo "[*] Zabezpieczanie ssh..."
securing_ssh

# verifying config
if [ "$(sshd -t)" ]
then
    echo "-----------------------------------------------------------"
    echo "[!] Powyższe błędy występują w pliku '/etc/ssh/sshd_config'"
    echo "-----------------------------------------------------------"

    exit
fi

echo "[*] Tworzenie grupy 'ssh_group'..."
sudo addgroup ssh_group

echo "[*] Dodawanie użytkownika do grupy 'ssh_group'..."
gpasswd -a "$primary_user" ssh_group # making sure the user has access to sudo
gpasswd -a "$primary_user" sudo # making sure the user has access to sudo

echo "[*] Kopiowanie kluczy ssh"

#checking ssh keys
if ! [ -f "/root/.ssh/authorized_keys" ] || ! [ -s "/root/.ssh/authorized_keys" ]
then
    echo "[!] Dodaj swój klucz ssh do '/home/$primary_user/.ssh/authorized_keys' i uruchom ponownie skrypt"
    read -p "Rozumiem (Enter)"
    exit
else
    if ! [ -d "/home/$primary_user/.ssh/" ] # looking for ~/.ssh directory
    then
        mkdir /home/"$primary_user"/.ssh/
    fi

    cp /root/.ssh/authorized_keys /home/"$primary_user"/.ssh/authorized_keys
    chown "$primary_user":"$primary_user" /home/$primary_user/.ssh/*
fi

echo "[*] Restartowanie usługi 'ssh'"
service ssh restart

echo "[*] Dodawanie zadania 'cron'"
cron_job_setup

echo "[!] Od teraz logowanie przez ssh jest dostępne TYLKO dla użytkowników z grupy 'ssh_group'."