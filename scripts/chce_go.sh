#!/bin/bash
# Download and install golang
# official docs https://go.dev/doc/install
# Author: Cloudziu

set -e

# Check version at: https://go.dev/dl/
GO_VERSION=$(curl -s "https://go.dev/VERSION?m=text")

GO_ARCHIVE_OUTPUT="/tmp/$GO_VERSION.linux-amd64.tar.gz"
GO_INSTALL_PATH="/usr/local"
GO_URL="https://go.dev/dl/$GO_VERSION.linux-amd64.tar.gz"

# Check for sudo priviliges
if [[ $EUID -ne 0 ]]; then
   echo -e "Skrypt powinien zostac uruchomiony z uprawnieniami sudo lub jako uzytkownik root. \033[1;31msudo ./chce_go.sh\033[0m"
   exit 1
fi

# Remove older version of Go if exist
if [ -d "/usr/local/go" ]; then
  echo -e "Znaleziono stara wersje Go. Zostanie ona usunieta.\n"
  rm -rf "/usr/local/go"
fi

# Download Go archive
echo -e "Pobieram $GO_VERSION.linux-amd64.tar.gz do katalogu $GO_ARCHIVE_OUTPUT\n"
wget -q -O $GO_ARCHIVE_OUTPUT "$GO_URL"

# Extract Go archive
echo -e "Wypakowuje $GO_ARCHIVE_OUTPUT do katalogu $GO_INSTALL_PATH\n"
tar -xf $GO_ARCHIVE_OUTPUT -C $GO_INSTALL_PATH

# Add PATH env
if [ $SUDO_USER ] && [ $SUDO_USER != "root" ] ; then
  export PROFILE_PATH="/home/$SUDO_USER/.profile"
else
  export PROFILE_PATH="$HOME/.profile"
fi

# If Go PATH export doesn't exist, add it
if ! grep 'export PATH=$PATH:/usr/local/go/bin' $PROFILE_PATH > /dev/null ; then
  echo -e "Dodaje Go do PATH w pliku $PROFILE_PATH\n"
  echo 'export PATH=$PATH:/usr/local/go/bin' >> $(ls $PROFILE_PATH)
fi

# Drop good news
echo -e "Instalacja zakonczona. Aby moc uruchomic Go, nalezy zaktualizowac zmienna PATH.\n"
echo -e "Wyloguj sie ze swojego uzytkownika i zaloguj ponownie, lub wpisz polecenie \033[1;31msource $PROFILE_PATH\033[0m"
echo -e "Uruchom \033[1;31mgo version\033[0m aby wyswietlic wersje Go\n"

echo -e "Jezeli chcesz uruchomic Go z poziomu innego uzytkownika, dodaj do pliku \033[1;31m.profile\033[0m"
echo -e "znajdujacego sie w katalogu domowym linijke: \033[1;31mexport PATH=\$PATH:/usr/local/go/bin\033[0m"
echo -e "i jesze raz wpisz polecenie \033[1;31msource $PROFILE_PATH\033[0m\n"
