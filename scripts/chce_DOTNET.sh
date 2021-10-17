#!/bin/bash
# Całość dokumentacji:
# https://docs.microsoft.com/pl-pl/dotnet/core/install/linux-ubuntu
#

# Zainstaluj klucze do podpisywania pakietów microsoft
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
sudo dpkg -i /tmp/packages-microsoft-prod.deb
rm /tmp/packages-microsoft-prod.deb

# Aktualizacja apt
sudo apt-get update;

# Instalacja dotnet-sdk-5.0
sudo apt-get install -y apt-transport-https && \
    sudo apt-get update && \
    sudo apt-get install -y dotnet-sdk-5.0

# Instalacia środwiska uruchomieniowego platfromy ASP.NET Core
sudo apt-get install -y apt-transport-https && \
    sudo apt-get update && \
    sudo apt-get install -y aspnetcore-runtime-5.0

# Lub alternatywa: ASP.NET zmiast ASP.NET Core
# sudo apt-get install -y dotnet-runtime-5.0
