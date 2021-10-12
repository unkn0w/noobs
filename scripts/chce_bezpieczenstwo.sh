#!/bin/bash
#Author Borys Gnaciński

users_other_than_root(){
    if [ "$(sudo getent passwd | grep /bin/bash | awk -F: '{print $1}' | grep -v root)" != "" ]
    then
        return true
    else
        return false
    fi 
}

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