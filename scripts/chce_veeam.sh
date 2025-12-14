#!/bin/bash

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

msg_info "Sprawdzenie uprawnień"
require_root

msg_info "Pobieranie paczki z Veeam"
wget https://download2.veeam.com/veeam-release-deb_1.0.8_amd64.deb -O /tmp/veeam.deb

msg_info "Aktualizacja pakietów"
pkg_update

msg_info "Instalacja xorriso i cifs-utils"
pkg_install xorriso cifs-utils

msg_info "Instalacja paczki"
dpkg -i /tmp/veeam.deb

msg_info "Aktualizacja pakietów"
pkg_update

msg_info "Instalacja Veeam"
pkg_install veeam

msg_info "Dodanie możliwości tworzenia recovery ISO"
mkdir /etc/systemd/system/veeamservice.service.d
echo "[Service]" >> /etc/systemd/system/veeamservice.service.d/override.conf
echo "LimitNOFILE=524288" >> /etc/systemd/system/veeamservice.service.d/override.conf
echo "LimitNOFILESoft=524288" >> /etc/systemd/system/veeamservice.service.d/override.conf
systemctl daemon-reload
service_restart veeamservice

msg_ok "Veeam uruchomisz poprzez: sudo veeam"
