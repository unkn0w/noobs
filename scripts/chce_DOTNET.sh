#!/bin/bash
# Całość dokumentacji:
# https://docs.microsoft.com/pl-pl/dotnet/core/install/linux-ubuntu
#

# określenie wersji systemu

usage (){
    echo "Uzycie: $0 wersja";
    echo "Musisz podać wersję do zainstalowania np. 7.0";
    exit 3;
}

[ "$#" -lt 1 ] && usage

dotnet_version="$1"

apt-get install -y lsb-release

os-version=$(lsb_release -sr)

# Zainstaluj klucze do podpisywania pakietów microsoft
apt-get install -y gpg
cd /tmp
wget -O - https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o microsoft.asc.gpg
mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/
wget https://packages.microsoft.com/config/ubuntu/'$os-version'/prod.list
mv prod.list /etc/apt/sources.list.d/microsoft-prod.list
chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg
chown root:root /etc/apt/sources.list.d/microsoft-prod.list

# Aktualizacja apt
apt-get update

# Instalacja dotnet-sdk
apt-get install -y dotnet-sdk-"$dotnet_version"

# Instalacia środwiska uruchomieniowego platfromy ASP.NET Core
apt-get install -y aspnetcore-runtime-"$dotnet_version"

# Lub alternatywa: ASP.NET zmiast ASP.NET Core
# sudo apt-get install -y dotnet-runtime-"$dotnet_version"
