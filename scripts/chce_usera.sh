#!/bin/bash

# if no sudo, then exit
if [ "$(id -u)" != "0" ]; then
	echo "Musisz uruchomić ten skrypt jako root" 1>&2
	echo "Spróbuj sudo $0"
	exit 1
fi

# if no parameters
if [ $# -eq 0 ]
then
	read -p 'Podaj nazwe usera: ' username
else
	username=$(echo $1)
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

# make user
useradd -m -p "$password" "$username"