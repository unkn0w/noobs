#!/usr/bin/env bash
# Całość dokumentacji:
# https://docs.microsoft.com/pl-pl/dotnet/core/install/linux-ubuntu
#

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

# określenie wersji systemu

usage (){
    echo "Uzycie: $0 wersja";
    echo "Musisz podać wersję do zainstalowania np. 7.0";
    exit 3;
}

[ "$#" -lt 1 ] && usage

dotnet_version="$1"

pkg_install lsb-release

OS_VERSION="$(lsb_release -sr)"

# Zainstaluj klucze do podpisywania pakietów microsoft
pkg_install gpg
cd /tmp
wget -O - https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o microsoft.asc.gpg
mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/
wget https://packages.microsoft.com/config/ubuntu/'$OS_VERSION'/prod.list
mv prod.list /etc/apt/sources.list.d/microsoft-prod.list
chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg
chown root:root /etc/apt/sources.list.d/microsoft-prod.list

# Aktualizacja apt
pkg_update

# Instalacja dotnet-sdk
pkg_install dotnet-sdk-"$dotnet_version"

# Instalacia środwiska uruchomieniowego platfromy ASP.NET Core
pkg_install aspnetcore-runtime-"$dotnet_version"

# Lub alternatywa: ASP.NET zmiast ASP.NET Core
# sudo apt-get install -y dotnet-runtime-"$dotnet_version"

# sprawdzenie wersji i poprawnosci instalacji
/usr/bin/dotnet --info
