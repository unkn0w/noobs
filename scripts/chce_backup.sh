#!/bin/bash
# Author: Borys Gnaciński
output_dir=""


if [ $EUID != 0 ]
then
    echo "Uruchom skrypt jako root"
    exit
fi

find_output_dir(){
    if [ -d "/storage/" ]
    then
        output_directory="/storage/backup"
    else
        if [ -s "/backup_key" ] 
        then
            echo -e "Host strych.mikr.us\nuser $HOSTNAME\nIdentityFile /backup_key" >> ~/.ssh/config
            output_dir="strych.mikr.us:~/backup"
        else
            echo "---------------------------------------------------------------"
            echo "[!] Aktywuj usługę 'strych' w panelu i uruchom skrypt ponownie."
            echo "---------------------------------------------------------------"
            exit
        fi
    fi
}

install_packages(){
    sudo wget https://mikr.us/tools/rsnappush -O /usr/bin/rsnappush
    sudo chmod +x /usr/bin/rsnappush
}

configure_cron(){
    echo -e "#!/bin/sh\n/usr/bin/rsnappush /etc/ $output_dir/etc/\n/usr/bin/rsnappush /home/ $output_dir/home/\n/usr/bin/rsnappush /var/log/ $output_dir/logs/" > /etc/cron.daily/backup
}

find_output_dir
echo "--------------------------------------------------------"
echo "[!] Backupy będą przechowywane w $output_dir"
echo "--------------------------------------------------------"

echo "[*] Instalowanie potrzebnych pakietów..."
install_packages

echo "[*] Ustawianie crona..."
configure_cron

echo "[!] Wykonywanie pierwszego backupu. Zaakceptuj połączenie jeżeli to potrzebne."
echo "------------------------------------------------------------------------------"
bash /etc/cron.daily/backup

echo "[*] Wszystko powinno działać. Polecenia crona znajdują się w '/etc/cron.daily/backup'"
echo "[*] Backupy są przechowywane w '$output_dir/'"
echo "[*] Domyślnie backupowane są katalogi: '/etc/', '/home/' i '/var/log/'."