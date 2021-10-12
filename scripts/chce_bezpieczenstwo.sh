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

package_installation(){
    sudo apt update
    sudo apt install lynis debsums unattended-upgrades apt-show-versions
}