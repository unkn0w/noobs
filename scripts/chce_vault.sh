#!/usr/bin/env bash
# Vault installation script
#
# Author: Sebastian Matuszczyk
#

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

# Sprawdzenie uprawnien
require_root

# Instalacja wymaganych pakietow
pkg_install software-properties-common

# Dodanie repozytorium HashiCorp z kluczem GPG (nowoczesna metoda)
msg_info "Dodawanie repozytorium HashiCorp"
add_repository_with_key \
    "https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    "hashicorp" \
    "https://apt.releases.hashicorp.com/gpg"

# Update and install
pkg_update
pkg_install vault

# Verifying the installation
if vault -h ; then
    msg_ok "Vault zainstalowany."
else
    msg_error "Instalacja się nie powiodła."
fi
