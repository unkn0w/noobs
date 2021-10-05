#!/bin/bash
# Skrypt stawia najnowszą wersję VSCode Server
# Autor: Jakub 'unknow' Mrugalski

# Sprawdz uprawnienia przed wykonaniem skryptu instalacyjnego
if [[ $EUID -ne 0 ]]; then
   echo -e "W celu instalacji tego pakietu potrzebujesz wyzszych uprawnien! Uzyj polecenia \033[1;31msudo ./chce_VSCode.sh\033[0m lub zaloguj sie na konto roota."
   exit 1
fi

# pobierz linka do najnowszej paczki
latest=`curl -s https://api.github.com/repos/cdr/code-server/releases/latest | grep -Eo 'https://.+_amd64.deb'`

# ściagnij paczke z powyższego linka
wget $latest -O /tmp/vscode.deb

# zainstaluj paczkę
dpkg -i /tmp/vscode.deb

# załóż katalog na configi
mkdir -p ~/.config/code-server

# wygeneruj losowe, 12 znakowe hasło
pass=`head -c255 /dev/urandom | base64 | grep -Eoi '[a-z0-9]{12}' | head -n1`

# utwórz hosta o nazwie 'globalipv6' reprezentującego globalny adres IPv6
sed -i '/ip6-loopback/a ::              globalipv6' /etc/hosts

# stwórz plik konfiguracyjny dla VSCode z powyższym hasłem
echo -e "bind-addr: globalipv6:80\nauth: password\npassword: $pass\ncert: false" >~/.config/code-server/config.yaml

# uruchom VSCode
systemctl start code-server@root
