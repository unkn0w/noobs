#!/bin/bash
# Całość dokumentacji:
# https://docs.microsoft.com/pl-pl/dotnet/core/install/linux-ubuntu
#

# Zainstaluj klucze do podpisywania pakietów microsoft
latest_version = curl --silent https://packages.microsoft.com/config/ubuntu/ | grep -o 'href=".*">' | sed 's/href="//;s/\/">//' | tail -n 1
wget https://packages.microsoft.com/config/ubuntu/${latest_version}/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
sudo dpkg -i /tmp/packages-microsoft-prod.deb
rm /tmp/packages-microsoft-prod.deb

dotnet_version = 6.0
# Aktualizacja apt
sudo apt-get update;

# Instalacja dotnet-sdk
sudo apt-get install -y apt-transport-https && \
    sudo apt-get update && \
    sudo apt-get install -y dotnet-sdk-${dotnet_version}

# Instalacia środwiska uruchomieniowego platfromy ASP.NET Core
sudo apt-get install -y apt-transport-https && \
    sudo apt-get update && \
    sudo apt-get install -y aspnetcore-runtime-${dotnet_version}

# Lub alternatywa: ASP.NET zmiast ASP.NET Core
# sudo apt-get install -y dotnet-runtime-${dotnet_version}
