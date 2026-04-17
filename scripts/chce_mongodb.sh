#!/bin/bash
#
# Authors: Kacper Adamczak, Janszczyrek
# Version: 1.1
#


wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add - && { printf "Prawidłowo zaimportowano klucz do repozytorium MongoDB"; } || { sudo apt-get install gnupg; wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add - ;  printf "\nZainstalowano pakiet gnugp oraz prawidłowo zaimportowano klucz do repozytorium MongoDB\n";}

echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list

sudo apt-get update

sudo apt-get install -y mongodb-org

sudo systemctl start mongod && { printf "\nPrawidłowo uruchomiono MongoDB\n";} || { sudo systemctl daemon-reload; sudo systemctl start mongod
}

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