#!/bin/bash
# Skrypt stawia najnowszą wersję VSCode Server
# Autor: Jakub 'unknow' Mrugalski
# Poprawki: Maciej Loper @2021-10

# uzycie: ./chce_VSCode.sh [port]

# ustawienia
APP_NAME="code-server"
PKG_FILE="/tmp/vscode.deb"
APP_PATH="$HOME/.config/$APP_NAME"
SERVICE_FILE="/lib/systemd/system/$APP_NAME@.service"
CONF_FILE="$APP_PATH/config.yaml"

status() {
    echo -e "\e[0;37m[x] \e[1;37m$1\e[0;0m"
}

err() {
    echo -e "\e[0;31m[!] \e[1;31m$1\e[0;0m";
    exit 1;
}

usage (){
    echo "Skladnia: $0 [port]";
    exit 3;
}

# start -----------------------------
[ "$EUID" -eq 0 ] && { err "Uruchamianie jako root jest niebezpieczne. Uzyj zwyklego uzytkownika."; }
sudo --validate || { err "Nie masz uprawnien do uruchamiania komend jako root - dodaj '$USER' do grupy 'sudoers'."; }

# sprawdz port
port="${1:-80}"
status "sprawdzanie portu $port"
[ "$port" -eq "$port" ] 2>/dev/null || { echo "Port musi byc liczba!"; exit 2; }
[ "$port" -le 1024 ] && as_root=true || as_root=false 
sudo lsof -i:"$port" | grep -q PID && { err "Port '$port' jest zajety, uzyj innego. Skladnia: $0 [port]."; } 

# pobierz linka do najnowszej paczki
latest="$(curl -s https://api.github.com/repos/cdr/code-server/releases/latest | grep -Eo 'https://.+_amd64.deb')"

# ściagnij paczke z powyższego linka (jeśli nie istnieje)
status "pobieranie instalatora"
[ -f "$PKG_FILE" ] || wget "$latest" -O $PKG_FILE &>/dev/null

# sprawdz czy instnieje i zainstaluj paczkę
dpkg --status code-server &>/dev/null || sudo dpkg -i $PKG_FILE

# wygeneruj losowe, 12 znakowe hasło
pass="$(head -c255 /dev/urandom | base64 | grep -Eoi '[a-z0-9]{12}' | head -n1)"
status "wygenerowane haslo: $pass"

# utwórz hosta o nazwie 'globalipv6' reprezentującego globalny adres IPv6
status "dodawanie 'globalipv6' do '/etc/hosts'"
sudo sed -i '/ip6-loopback/a ::              globalipv6' /etc/hosts

# ustaw uzytkownika
if "$as_root" ; then
    user="root";
    CONF_FILE="/root/.config/$APP_NAME/config.yaml";
    sudo mkdir -p "/root/.config/$APP_NAME" 2>/dev/null
else
    user="$USER"
    mkdir -p "$APP_PATH" 2>/dev/null
fi
status "ustawianie uzytkownika jako '$user'"

# stwórz plik konfiguracyjny dla VSCode z powyższym hasłem
status "tworzenie pliku konfiguracyjnego '$CONF_FILE'"
echo -e "bind-addr: globalipv6:$port\nauth: password\npassword: $pass\ncert: false" | sudo tee "$CONF_FILE" >/dev/null

# konfiguruj usluge
status "konfigurowanie serwisu '$SERVICE_FILE'"
sudo sed -i "s|ExecStart=.*|ExecStart=/usr/bin/code-server --bind-addr [::]:$port|g" "$SERVICE_FILE"
sudo systemctl daemon-reload

# sprzatanie
status "czyszczenie instalatora"
rm "$PKG_FILE"
sudo systemctl stop code-server@"$user" &>/dev/null
sudo systemctl stop code-server@root &>/dev/null

# uruchom VSCode
status 'uruchomienie aplikacji'
sudo systemctl start code-server@"$user"

# pokaz status
status 'sprawdzenie statusu'
sleep 3
addr="http://localhost:$port"
systemctl status code-server@"$user"

echo
netstat -ltn | grep --color "$port"
echo
echo "========================================"
echo -e "\e[0;32mGotowe, serwer jest dostepny pod adresem: \e[1;33m$addr\e[0;32m, a haslo to: \e[1;33m$pass \e[0;0m"
