#!/bin/bash

echo -e "\033[0;33mUWAGA\t\033\033[0;31mUWAGA\t\033[1;36mUWAGA\033[0m"
echo -e "Uruchom przynajmiej jedną \033[4mdodatkową\033[0m sesję ssh \033[4mprzed\033[0m wykonaniem tego skryptu!"
echo -e "Wykonaj oczywiście z sudo.\n"
echo -e "\033[0;32mDodaj danego użytkownika do grupy \033[0m\033[7mwithout-otp\033[0m, \033[0;32mjeśli nie należy wymagać od niego podania kodu OTP przy logowaniu (np. sesje sftp)! \033[0m \n"

read -n1 -s -r -p $'\033[0;33mNaciśnij enter, aby kontynuować...\033[0m\n' key
if [ "$key" != "" ]; then
    echo -e "\033[0;31mWykryto inny przycisk, anulowanie aktywowania usługi 2FA...\033[0m"
    exit 1
fi

apt install libpam-google-authenticator
google-authenticator
if [ $? != 0 ]; then
    echo -e "\033[0;31mKonfiguracja 2FA nie zwróciła prawidłowego kodu zakończenia, anulowanie aktywowania usługi 2FA...\033[0m"
    exit 1
fi

if [ ! -f "$HOME/.google_authenticator" ]; then
    echo -e "\033[0;31mNie znaleziono pliku konfiguracyjnego 2FA w katalogu domowym. Spróbuj ponownie uruchomić skrypt.\033[0m"
    exit 1
fi

if [ -f "/etc/pam.d/sshd" ]; then
    if grep -Fq "pam_google_authenticator.so" "/etc/pam.d/sshd"; then
        echo -e "\033[0;31m2FA prawdopodobnie jest już skonfigurowane na twoim systemie."
        echo -e "\033[0;33mZweryfikuj zawartość pliku \033[0m\033[7m/etc/pam.d/sshd\033[0;33m i spróbuj ponownie.\033[0m"
        exit 1
    fi
fi

echo "auth [success=done default=ignore] pam_succeed_if.so user ingroup without-otp" >>/etc/pam.d/sshd
echo "auth required pam_google_authenticator.so" >>/etc/pam.d/sshd
# DO NOT CHANGE THE SEQUENCE OF ABOVE LINES

grep -Fq "UsePAM" /etc/ssh/sshd_config && sed -i 's/UsePAM no/UsePAM yes/' /etc/ssh/sshd_config || echo "UsePAM yes" >> /etc/ssh/sshd_config
grep -Fq "ChallengeResponseAuthentication" /etc/ssh/sshd_config && sed -i 's/\(ChallengeResponseAuthentication\) no/\1 yes/g' /etc/ssh/sshd_config || echo "ChallengeResponseAuthentication yes" >> /etc/ssh/sshd_config
systemctl restart sshd.service

echo -e "\033[0;32mGotowe!\033[0m"
