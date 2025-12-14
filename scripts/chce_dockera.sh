#!/bin/bash
# docker + docker-compose
# Autor: Jakub Rolecki

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

# Sprawdz uprawnienia przed wykonaniem skryptu instalacyjnego
require_root

pkg_update
pkg_install apt-transport-https ca-certificates curl gnupg lsb-release

# Dodanie oficjalnego klucza GPG Dockera
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Dodanie oficjalnych repozytorium Dockera do systmeu
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

pkg_update
# Instalacja dockera
pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Nadanie uprawnień do Dockera dla obecnego non-root usera
groupadd docker
usermod -aG docker $USER
newgrp docker

# Sprawdzenie czy Docker został prawidłowo zainstalowany
docker run hello-world
