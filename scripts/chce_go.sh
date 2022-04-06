#!/bin/bash
# Download and install golang
# official docs https://go.dev/doc/install
# Author: Cloudziu

set -e

# Check version at: https://go.dev/dl/
GO_VERSION="1.18"

GO_ARCHIVE_OUTPUT="/tmp/go$GO_VERSION.linux-amd64.tar.gz"
GO_INSTALL_PATH="/usr/local"
GO_URL="https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz"

# Check for sudo priviliges
if [[ $EUID -ne 0 ]]; then
   echo -e "Skrypt powinien zostac uruchomiony z uprawnieniami sudo lub jako uzytkownik root. \033[1;31msudo ./chce_go.sh\033[0m"
   exit 1
fi

# Remove older version of Go if exist
if [ -d $GO_INSTALL_PATH/go ]; then
  echo -e "Znaleziono stara wersje Go. Zostanie ona usunieta.\n"
  rm -rf "/usr/local/go"
fi

# Download Go archive
echo -e "Pobieram go$GO_VERSION.linux-amd64.tar.gz do katalogu $GO_ARCHIVE_OUTPUT\n"
wget -q -O $GO_ARCHIVE_OUTPUT "$GO_URL"

# Extract Go archive
echo -e "Wypakowuje $GO_ARCHIVE_OUTPUT do katalogu $GO_INSTALL_PATH\n"
tar -xf $GO_ARCHIVE_OUTPUT -C $GO_INSTALL_PATH

# Add Go to PATH environment if do not exist
if ! grep 'export PATH=$PATH:/usr/local/go/bin' /home/$SUDO_USER/.profile > /dev/null ; then
  echo -e "Dodaje Go do PATH w pliku /home/$SUDO_USER/.profile\n"
  echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/$SUDO_USER/.profile
fi

# Drop good news
echo -e "Instalacja zakonczona. Aby moc uruchomic Go, nalezy zaktualizowac zmienna PATH.\n"
echo -e "Wyloguj sie ze swojego uzytkownika i zaloguj ponownie, lub wpisz polecenie \033[1;31msource /home/$SUDO_USER/.profile\033[0m"
echo -e "Uruchom \033[1;31mgo version\033[0m aby wyswietlic wersje Go"

