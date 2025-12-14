#!/bin/bash
# MongoDB instalator
# Authors: Kacper Adamczak, Janszczyrek
# Refactored: noobs community (v2.0.0)

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

msg_info "Sprawdzenie uprawnien"
require_root

msg_info "Dodawanie repozytorium MongoDB"
add_repository_with_key \
    "[ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" \
    "mongodb-org-5.0.list" \
    "https://www.mongodb.org/static/pgp/server-5.0.asc"

msg_info "Instalacja MongoDB"
pkg_update
pkg_install mongodb-org

msg_info "Uruchamianie MongoDB"
if ! service_start mongod; then
    msg_info "Przeladowanie daemonow systemd..."
    systemctl daemon-reload
    service_start mongod
fi

msg_ok "MongoDB zainstalowana i uruchomiona!"

# Opcjonalna instalacja mongo-express
if command -v npm &> /dev/null; then
    msg_info "Instalacja mongo-express..."
    npm install -g mongo-express

    if [[ -f /usr/lib/node_modules/mongo-express/config.default.js ]]; then
        cp /usr/lib/node_modules/mongo-express/config.default.js /usr/lib/node_modules/mongo-express/config.js

        ME_PASS=$(generate_random_string 16)
        sed -i "s/password: getFileEnv(basicAuthPassword) || 'pass',/password: getFileEnv(basicAuthPassword) || '$ME_PASS',/g" \
            /usr/lib/node_modules/mongo-express/config.js

        msg_ok "mongo-express zainstalowany!"
        msg_info "Haslo admina mongo-express: $ME_PASS"
        msg_info "Uruchomienie: mongo-express --url mongodb://127.0.0.1:27017"
    fi
else
    msg_info "npm nie jest zainstalowany - pominieto instalacje mongo-express"
fi
