#!/usr/bin/env bash
# Tworzenie nowego uzytkownika, z dostepem do sudo i kopia authorized_keys

# Autor: Radoslaw Karasinski, Grzegorz Ćwikliński, Szymon Hryszko

# if no sudo, then exit
if [ "$(id -u)" != "0" ]; then
	echo "Musisz uruchomić ten skrypt jako root" 1>&2
	echo "Spróbuj sudo $0"
	exit 1

fi

_check_if_user_exits() {
    given_user=$1
    if sudo id "${given_user}" &>/dev/null; then
            echo "Użytkownik ${given_user} już istnieje!"
            exit 1
    fi
}

_check_if_user_blank() {
    given_user=$1
    if [ -z "$1" ]; then
        echo "Nie podałeś nazwy użytkownia!"
        exit 1
fi
}

_password_get(){
        username_arg=$1
	while true; do
                if [ "$username_arg" -eq "0" ]; then
		        # ask for password
		        read -s -p "Podaj hasło (zostaw puste aby wygenerować): " password
		        echo
		fi

		# check if password is blank
		if [ -z "$password" ]; then
			# generate password
			password=$(head -c255 /dev/urandom | base64 | grep -Eoi '[a-z0-9]{12}' | head -n1)
			echo "Twoje hasło to $password"
			break
		fi

		read -sp 'Powtórz hasło: ' password_repeat
		echo

		# if passwords are equal
		if [ "$password" == "$password_repeat" ]; then
			break
		else
			echo "Hasła się nie zgadzają, spróbuj ponownie!"
		fi
	done
}

if ! [ -z "$1" ]; then
    username=$1
    username_arg=1
else
    read -p "Podaj nazwę użytkownika: " username
    username_arg=0
fi

_check_if_user_blank $username
_check_if_user_exits $username
_password_get $username_arg


# stworz nowego uzytkownika
sudo useradd -m -p "$password" "$username"

# Ask for the new user name
if [ $# -eq 0 ]
then
	read -p "Podaj nazwe nowego uzytkownika: " username
else
	username=$(echo $1)
fi

# exit if the user doesn't exists
if sudo id "$username" &>/dev/null; then
    echo "Podany uzytkownik juz istnieje!"
    exit
fi

read -p "Czy chcesz podać hasło? Jeśli nie zostanie ono wygenerowane [T/n] " c
# if $c is 'n'
if [[ "$c" == "n" ]]; then
	password=$(head -c255 /dev/urandom | base64 | grep -Eoi '[a-z0-9]{12}' | head -n1)
else
	while true; do
		# ask for password
		read -sp 'Podaj hasło: ' password
		echo
		read -sp 'Podtórz hasło: ' password_repeat
		echo

		# if passwords are equal
		if [ "$password" == "$password_repeat" ]; then
			break
		else
			echo "Hasła się nie zgadzają, spróbuj ponownie!"
		fi
	done
fi

# stworz nowego uzytkownika
useradd -m -p "$password" "$username" && echo "Uzytkownik $username zostal stworzony"

# If password generated, then echo then
if [[ "$c" == "n" ]]; then
	echo "Hasło: $password"
fi

# dodaj nowego uzytkownika do sudo
sudo usermod -aG sudo $username

ssh_dir="/home/$username/.ssh"

# stworz folder na ustawienia ssh oraz ustaw odpowiednie prawa
sudo mkdir -p $ssh_dir
sudo chmod 700 $ssh_dir

# stworz authorized_keys oraz ustaw odpowiednie prawa
sudo touch $ssh_dir/authorized_keys
sudo chmod 600 $ssh_dir/authorized_keys

# zmien wlasciciela folderu i plikow
sudo chown -R $username:$username $ssh_dir

# skopiuj klucze obecnego uzytkownika do nowo stworzoneg
cat ~/.ssh/authorized_keys 2>&1 | sudo tee -a $ssh_dir/authorized_keys >/dev/null

echo "Pomyślnie stworzono użytkownia ${username}."
