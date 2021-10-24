#!/bin/bash

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

echo "Dodano pomyślnie"
