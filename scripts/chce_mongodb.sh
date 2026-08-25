#!/bin/bash
#
# Authors: Kacper Adamczak, Janszczyrek
# Version: 1.1
#


# MongoDB 8.0+ crashuje na starcie ("Linux kernel versions 6.19 and newer has a known
# incompatibility", SERVER-121912/tcmalloc) na jądrach Proxmoksa z zakresu 6.19-7.0.13 - a
# Mikrus hostuje kontenery właśnie na takich jądrach (zweryfikowano na dev.mikr.us, kernel
# 7.0.2-6-pve). MongoDB 7.0 nie ma tego problemu i jest wspierane do 2027-08-31.
MONGO_LINE="7.0"
sudo apt-get install -y gnupg
wget -qO - https://www.mongodb.org/static/pgp/server-${MONGO_LINE}.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-${MONGO_LINE}.gpg && printf "Prawidłowo zaimportowano klucz do repozytorium MongoDB\n"

codename="$(lsb_release -cs)"
# repo.mongodb.org publikuje pakiety mongodb-org 7.0 tylko dla focal/jammy - na nowszych
# dystrybucjach (np. noble) używamy najbliższego wspieranego (jammy); pakiety instalują się
# i działają poprawnie także na noble (zweryfikowano).
case "$codename" in
    focal|jammy) repo_codename="$codename" ;;
    *) repo_codename="jammy" ;;
esac
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-${MONGO_LINE}.gpg ] https://repo.mongodb.org/apt/ubuntu ${repo_codename}/mongodb-org/${MONGO_LINE} multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-${MONGO_LINE}.list

sudo apt-get update

if ! sudo apt-get install -y mongodb-org; then
    printf "\nBLAD: instalacja pakietu mongodb-org nie powiodla sie (repo %s/mongodb-org/%s moze byc niewspierane).\n" "$repo_codename" "$MONGO_LINE"
    exit 1
fi

sudo systemctl daemon-reload
sudo systemctl enable --now mongod
# mongod.service ma Type=simple - "systemctl start" wraca natychmiast i NIE czeka na to,
# czy proces faktycznie wystartował, wiec sprawdzenie exit code samego "enable --now" nie
# wystarczy (i tak zwroci 0, nawet jesli mongod zaraz potem sie wywali).
sleep 3
if ! sudo systemctl is-active --quiet mongod; then
    printf "\nBLAD: mongod nie jest aktywny po probie uruchomienia - sprawdz: systemctl status mongod\n"
    exit 1
fi

printf "\nMongoDB jest poprawnie zainstalowana i uruchomiona\n"


if ! command -v npm &> /dev/null
then
    printf "\nAby zainstalowac mongo-express potrzebujesz npm\n"
    exit
else
    printf "\nInstaluje mongo-express...\n"
    sudo npm install -g mongo-express
    sudo cp /usr/lib/node_modules/mongo-express/config.default.js /usr/lib/node_modules/mongo-express/config.js

    ME_PASS=$(sudo < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
    sudo sed -i "s/password: getFileEnv(basicAuthPassword) || 'pass',/password: getFileEnv(basicAuthPassword) || '$ME_PASS',/g" /usr/lib/node_modules/mongo-express/config.js
    printf "\nHaslo dla admina mongo-express: $ME_PASS\n"

    printf "\nAby uruchomic mongo-express wpisz 'mongo-express --url mongodb://127.0.0.1:27017'\n"
    exit
fi