#!/bin/bash
#Author Borys Gnaciński

# ssh hardening
echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config
echo "AuthorizedKeysFile      .ssh/authorized_keys" >> /etc/ssh/sshd_config
echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
echo "AllowGroups ssh_group" >> /etc/ssh/sshd_config
echo "X11Forwarding no" >> /etc/ssh/sshd_config
echo "PermitRootLogin no" >> /etc/ssh/sshd_config
echo "MaxAuthTries 6" >> /etc/ssh/sshd_config