#!/bin/bash
# docker + docker-compose
# Autor: Jakub Rolecki
# Zmodyfikowane przez: Jakub Suchenek (itsanon.xyz)

if [[ $EUID -ne 0 ]]; then
    echo -e "W celu instalacji tego pakietu potrzebujesz wyzszych uprawnien! Uzyj polecenia \033[1;31msudo ./chce_dockera.sh\033[0m lub zaloguj sie na konto roota i wywolaj skrypt ponownie."
    exit 1
fi

if [ ! -f /etc/os-release ]; then
    echo "Nie można wykryć systemu operacyjnego!"
    exit 1
else
    . /etc/os-release
fi

if [ ! "$ID" == "ubuntu" ]; then
    echo "Ten skrypt działa tylko na Ubuntu!"
    exit 1
fi

# Zgodnie z oficjalną dokumentacją, minimalnym wspieranym systemem jest Ubuntu 22.04 LTS.
# https://docs.docker.com/engine/install/ubuntu/#os-requirements
if [[ "${VERSION_ID:0:2}" -lt 22 ]]; then
    echo "Ten skrypt działa tylko na Ubuntu 22.04 lub nowszym!"
    exit 1
fi

echo "Usuwanie starych lub innych implementacji Dockera..."
apt-get remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)
if [[ $? -ne 0 ]]; then
    echo "Wystąpił błąd podczas usuwania! Zobacz co się stało powyżej."
    exit 1
fi

echo "Przygotowywanie repozytorium Dockera..."
apt-get update && apt-get install -y ca-certificates curl
if [[ $? -ne 0 ]]; then
    echo "Nie można zainstalować pośrednich zależności Dodckera! Zobacz co się stało powyżej."
    exit 1
fi

echo "Pobieranie klucza GPG repozytorium Dockera..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
if [[ $? -ne 0 ]]; then
    echo "Nie można pobrać klucza GPG!"
    exit 1
fi
chmod a+r /etc/apt/keyrings/docker.asc

echo "Wykryto instalację Ubuntu '$UBUNTU_CODENAME'."

echo "Dodawanie repozytorium Dockera..."
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $UBUNTU_CODENAME
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
apt-get update
if [[ $? -ne 0 ]]; then
    echo "Wystąpił błąd przy dodawaniu repozytrium! Zobacz co się stało powyżej lub zgłoś ten problem na GitHubie."
    exit 1
fi

echo "Instalowanie Dockera..."
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
if [[ $? -ne 0 ]]; then
    echo "Wystąpił błąd podczas instalowania Dockera! Zobacz co się stało powyżej."
    exit 1
fi

echo "Uruchamianie Dockera (dla pewności)..."
# Dokumentacja nie precyzuje, czy ma być to 'docker.service' czy 'docker.socket'.
# https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
systemctl enable --now docker
if [[ $? -ne 0 ]]; then
    echo "Nie można uruchomić Dockera! Sprawdź logi korzystając z:"
    echo "systemctl status docker"
    exit 1
fi

echo "Uruchamianie testowego obrazu Dockera..."
docker run hello-world
if [[ $? -ne 0 ]]; then
    echo "Nie można uruhcomić testowego obrazu Dockera!"
    exit 1
fi

# Nadanie uprawnień do Dockera dla domyślnego użytkownika.
DEFAULT_USER=$(getent passwd 1000 | cut -d ":" -f 1)
if [ ! "$DEFAULT_USER" == "" ]; then
    groupadd docker
    usermod -aG docker $DEFAULT_USER
    echo "Dodano uprawnienia do Dockera dla konta '$DEFAULT_USER'."
    echo "Zalecane jest ponownie uruchomienie Mikrusa z panelu."
fi

echo ""
echo "--------------------------------------"
echo "Docker został pomyślnie zainstalowany!"
echo "--------------------------------------"
echo "> Możesz korzystać zarówno z 'docker' jak i 'docker compose'."
echo "  Uwaga, NIE 'docker-compose'!"
if [ ! "$DEFAULT_USER" == "" ]; then
    echo "> Korzystając z Dockera, nie musisz pisać 'sudo'."
fi
echo ""
