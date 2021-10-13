#!/bin/bash
#Author Borys Gnaciński

# privileges check
if [ $EUID != 0 ] 
then
    echo "Uruchom skrypt jako root."
    exit
fi

primary_user="$(sudo getent passwd | grep /bin/bash | awk -F: '{print $1}' | grep -v root | head -1)"

# ssh securing
securing_ssh(){
    echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config
    echo "AuthorizedKeysFile      .ssh/authorized_keys" >> /etc/ssh/sshd_config
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
    echo "AllowGroups ssh_group" >> /etc/ssh/sshd_config
    echo "X11Forwarding no" >> /etc/ssh/sshd_config
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config
    echo "MaxAuthTries 3" >> /etc/ssh/sshd_config
}

# installing specified packages
package_installation(){
    sudo apt update
    sudo apt install -y lynis debsums unattended-upgrades apt-show-versions
    sudo apt install -y logwatch
}

# setting up cron
cron_job_setup(){
    echo -e "#!/bin/bash\n#Check if removed-but-not-purged\ntest -x /usr/share/logwatch/scripts/logwatch.pl || exit 0\n#execute\n/usr/sbin/logwatch | pusher" > /etc/cron.daily/00logwatch
    chmod +x /etc/cron.daily/00logwatch
}

# ---