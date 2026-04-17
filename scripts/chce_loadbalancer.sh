#!/bin/bash
#
# Skrypt sprawdza czy HAProxy jest zainstalowane i instaluje jezeli nie.
# Nastepnie za pomocą kreatora tworzy kowa konfigurację load balancera.
#
# Autor: Pawel 'Pawilonek' Kaminski


# Funkcja wyswietla podany tekst i prosi uzytkownika o podanie wartosci
_ask_input() {
  local text=$1
  local default=$2

  if [[ -n $default ]]
  then
    text="$text [domyślnie: $default]"
  fi

  echo -e -n "$text: \e[33m"
  read -r userValue
  echo -e -n "\e[39m"

  result="${userValue:-$default}"
}


# Funkcja sprawdza, czy podany serwis jest już zainstalowany
_service_exists() {
    local service=$1

    if [[ $(systemctl list-units --all -t service --full --no-legend "$service.service" | sed 's/^\s*//g' | cut -f1 -d' ') == $service.service ]]; then
        return 0
    else
        return 1
    fi
}


# Spawdzanie czy uzytkownik jest administratorem
if [ "$(id -u)" != "0" ]; then
  echo -e "[\e[31m ERR \e[39m] Musisz uruchomić ten skrypt jako root:"
  echo "  sudo $0"

  exit 1
fi



##########
# Instalowanie zaleznosci
#

echo -e "[\e[34m i \e[39m] Instalowanie HAProxy"
# Spawdzanie czy HAProxy jest juz zainstalowane
if _service_exists haproxy; then
    echo -e "[\e[32m OK \e[39m] Jest już zainstalowane"
else
    apt update
    apt install -y haproxy
    echo -e "[\e[32m OK \e[39m] zainstalowane"
fi



##########
# Sprawdzanie obecnej konfiguracji
#

haproxy -c -V -f /etc/haproxy/haproxy.cfg 
if [ $? -ne 0 ]; then
  echo -e "[\e[31m ERR \e[39m] Twoja obecna konfiguracja serwera HAProxy jest niepoprawna"
  echo -e "[\e[31m ERR \e[39m] Sprawdź plik /etc/haproxy/haproxy.cfg"

  exit 1
fi



##########
# Zbieranie danych od uzytkownika
#

echo -e "[\e[34m i \e[39m] Dodawanie nowej konfiguracji"

# Generowanie losowej nazwy
randomName=$(echo $RANDOM | md5sum | head -c 5)

_ask_input "Nazwa serwisu" "$randomName"
name=$result

_ask_input "Na jakim porcie nasłuchiwać" "80"
port=$result

servers=()
echo "Podaj listę adresów z portem na jakie ruch ma być przekierowany. Pusta linijka kończy wpisywanie."
echo "Przykładowe wartości:"
echo "  127.0.0.1:80"
echo "  mikrus:443"
echo ""

_ask_input "1"
server=$result
i=1

while [[ -n $server ]]
do
  servers+=("$server")
  ((i=i+1))

  _ask_input "$i"
  server=$result
done

# Spawdzanie czy zostal podany przynajmniej jeden serwer
if [ ${#servers[@]} -eq 0 ]; then
  echo -e "[\e[31m ERR \e[39m] Musisz podać przynajmniej jeden serwer"

  exit 1
fi



##########
# Przygotowanie nowj konfiguracji
#


# Pozbywamy sie spacji z nazwy
name="${name// /_}"

# Przygotowanie przykladowej konfiguracji
config=$(cat <<-END

frontend ${name}_front
        # Słuchaj na porcie ${port} ipv4 i ipv6
        bind *:${port}
        bind [::]:${port} v4v6
        # I przekerowuj ruch na serwery pod nazwą ${name}_backend_servers
        default_backend    ${name}_backend_servers

backend ${name}_backend_servers
        # Rozkładaj ruch za pomocą karuzeli (roundrobin)
        balance            roundrobin
        # I przekerowuj ruch na następujące serwery
END
)

# Dodanie do konfiguracj serwerow
i=0
for address in "${servers[@]}"
do
  config="${config}
        server             srv${i} ${address} check"
  
  ((i=i+1))
done


# Sprawdzanie nowej konfiguracji
tmpConfig=/tmp/${randomName}-haproxy.cfg
cp /etc/haproxy/haproxy.cfg ${tmpConfig}
echo "$config" >> ${tmpConfig}
haproxy -c -V -f ${tmpConfig}
configReturn=$?
rm ${tmpConfig}
if [ $configReturn -ne 0 ]; then
  echo -e "[\e[31m ERR \e[39m] Niestety podana konfiguracja jest niepoprawna"

  exit 1
fi


# Dodanie nowego wpisu do konfiguracji
echo "$config" >> /etc/haproxy/haproxy.cfg
echo -e "[\e[32m OK \e[39m] Twoja konfiguracja została zapisana w: /etc/haproxy/haproxy.cfg"

# Restart servera HAProxy
echo -e "[\e[34m i \e[39m] Restart serwera"
systemctl restart haproxy


echo -e "[\e[32m OK \e[39m] Gotowe!"

