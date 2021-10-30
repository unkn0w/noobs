#!/bin/bash

echo -e "\033[0;33mUWAGA\t\033\033[0;31mUWAGA\t\033[1;36mUWAGA\033[0m"
echo -e "Uruchom przynajmiej jedną \033[4mdodatkową\033[0m sesję ssh \033[4mprzed\033[0m wykonaniem tego skryptu!"
echo -e "Wykonaj oczywiście z sudo.\n"
echo -e "\033[0;32mDodaj danego użytkownika do grupy \033[0m\033[7mwithout-otp\033[0m, \033[0;32mjeśli nie należy wymagać od niego podania kodu OTP przy logowaniu (np. sesje sftp)! \033[0m \n"

apt install libpam-google-authenticator && google-authenticator
echo "auth [success=done default=ignore] pam_succeed_if.so user ingroup without-otp" >>/etc/pam.d/sshd
echo "auth required pam_google_authenticator.so" >>/etc/pam.d/sshd
# DO NOT CHANGE THE SEQUENCE OF ABOVE LINES

sed -i 's/UsePAM no/UsePAM yes/' /etc/ssh/sshd_config
sed -i 's/\(ChallengeResponseAuthentication\) no/\1 yes/g' /etc/ssh/sshd_config
systemctl restart sshd.service
