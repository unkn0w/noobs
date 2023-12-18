#!/bin/bash
# docker + docker-compose
# Autor: Jakub Rolecki

# Sprawdz uprawnienia przed wykonaniem skryptu instalacyjnego
if [[ $EUID -ne 0 ]]; then
   echo -e "W celu instalacji tego pakietu potrzebujesz wyzszych uprawnien! Uzyj polecenia \033[1;31msudo ./chce_dockera.sh\033[0m lub zaloguj sie na konto roota i wywolaj skrypt ponownie."
   exit 1
fi

apt update
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Dodanie oficjalnego klucza GPG Dockera
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Dodanie oficjalnych repozytorium Dockera do systemu
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
# Instalacja dockera
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Nadanie uprawnień do Dockera dla obecnego non-root usera
groupadd docker
usermod -aG docker $USER
newgrp docker

# Sprawdzenie czy Docker został prawidłowo zainstalowany
docker run hello-world
