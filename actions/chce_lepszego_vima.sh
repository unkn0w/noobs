#!/usr/bin/env bash

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

if [[ -n "$(grep 'map <silent> <F5> :!python3 %<CR>' ~/.vimrc)" ]]; then
    msg_info "Już zaktualizowano Twoją konfigurację vima"
    exit 0
fi

echo 'syntax on
set autoindent
set background=dark
set incsearch
set hlsearch

map <silent> <F5> :!python3 %<CR>

set pastetoggle=<F2>

set tabstop=4
set shiftwidth=4
set expandtab' >>~/.vimrc

msg_ok "Dodano pomyślnie"
