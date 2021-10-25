#!/bin/bash
# docker + docker-compose
# Autor: Jakub Rolecki
# Modyfikacje: Piotr Koska

. ./functions/function_apt.sh

# Sprawdz uprawnienia przed wykonaniem skryptu instalacyjnego
if [[ $EUID -ne 0 ]]; then
   echo -e "W celu instalacji tego pakietu potrzebujesz wyzszych uprawnien! Uzyj polecenia $0 lub zaloguj sie na konto roota i wywolaj skrypt ponownie: $0"
   exit 1
fi

apt_update
apt_install_software apt-transport-https ca-certificates curl gnupg lsb-release

# Dodanie oficjalnego klucza GPG Dockera
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Dodanie oficjalnych repozytorium Dockera do systmeu
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt_update
# Instalacja dockera
apt_install_software -y docker-ce docker-ce-cli containerd.io docker-compose

# Sprawdzenie czy Docker został prawidłowo zainstalowany
docker run hello-world

# Sprawdzanie wersji docker
docker --version

# Sprawdzenie wersji
docker-compose --version