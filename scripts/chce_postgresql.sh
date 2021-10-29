#!/bin/bash
# Instalator PostgreSQL
# Author: Janszczyrek
#

# Dodaj repozytorium postgresql
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Zaimportuj klucze repozytorium
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Zaktualizuj liste pakietow i zainstaluj postgresql
sudo apt-get update
sudo apt-get -y install postgresql

# Zapisz do zmiennej ilosc pamieci ram w mb
let ile_pamieci=$(free -t --mega | awk 'NR==2{print $2}')

# Oblicz zalecana ilosc pamieci
if [ $ile_pamieci -le 1000 ]
then
    # ok.15%
    let shared_buffers=$ile_pamieci/7
else
    # 25%
    let shared_buffers=$ile_pamieci/4
fi
let effective_cache_size=$ile_pamieci/2


# Zastosuj dla kazdej zainstalowanej wersji Postgresa
for postgres_dir in /etc/postgresql/*; do
    config_path=$postgres_dir"/main/postgresql.conf"

    # Zmiana ilosci dostepnej pamieci
    sudo sed -i "s/shared_buffers = 128MB/shared_buffers = $shared_buffers\MB/" $config_path
    sudo sed -i "s/#effective_cache_size = 4GB/effective_cache_size = $effective_cache_size\MB/" $config_path
done


sudo systemctl restart postgresql
