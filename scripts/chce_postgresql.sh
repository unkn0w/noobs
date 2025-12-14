#!/bin/bash
# Instalator PostgreSQL
# Author: Janszczyrek
# Refactored: noobs community (v2.0.0)

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

msg_info "Sprawdzenie uprawnien"
require_root

msg_info "Dodawanie repozytorium PostgreSQL"
CODENAME=$(lsb_release -cs)
add_repository_with_key \
    "http://apt.postgresql.org/pub/repos/apt ${CODENAME}-pgdg main" \
    "pgdg.list" \
    "https://www.postgresql.org/media/keys/ACCC4CF8.asc"

msg_info "Instalacja PostgreSQL"
pkg_update
pkg_install postgresql

msg_info "Optymalizacja konfiguracji pamieci"
# Oblicz ilosc pamieci RAM w MB
ile_pamieci=$(free -t --mega | awk 'NR==2{print $2}')

# Oblicz zalecana ilosc pamieci
if [ "$ile_pamieci" -le 1000 ]; then
    # ok. 15% dla mniejszych maszyn
    shared_buffers=$((ile_pamieci / 7))
else
    # 25% dla wiekszych maszyn
    shared_buffers=$((ile_pamieci / 4))
fi
effective_cache_size=$((ile_pamieci / 2))

# Zastosuj dla kazdej zainstalowanej wersji Postgresa
for postgres_dir in /etc/postgresql/*; do
    if [[ -d "$postgres_dir" ]]; then
        config_path="$postgres_dir/main/postgresql.conf"
        if [[ -f "$config_path" ]]; then
            msg_info "Konfiguracja: $config_path"
            sed -i "s/shared_buffers = 128MB/shared_buffers = ${shared_buffers}MB/" "$config_path"
            sed -i "s/#effective_cache_size = 4GB/effective_cache_size = ${effective_cache_size}MB/" "$config_path"
        fi
    fi
done

service_restart postgresql

msg_ok "PostgreSQL zainstalowany pomyslnie!"
msg_info "shared_buffers: ${shared_buffers}MB, effective_cache_size: ${effective_cache_size}MB"
