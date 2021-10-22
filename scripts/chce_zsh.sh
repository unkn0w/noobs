#!/bin/bash
# Skrypt instaluje powłokę ZSH, dodatek oh-my-zsh, paczkę dodatkowych pluginów i aktywuje te rozszerzenia które mogą ułatwić pracę początkującycm
# Autor: Jakub 'unknow' Mrugalski

sudo apt update && sudo apt install zsh git

# instalacja oh-my-zsh
wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O- | sh

# instalacja zewnętrznych, niestandardowych rozszerzeń
git clone https://github.com/agkozak/zsh-z ~/.oh-my-zsh/plugins/zsh-z
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/plugins/zsh-syntax-highlighting

# aktywujemy
sed -i 's|plugins=.*|plugins=(git zsh-z docker docker-compose sudo zsh-syntax-highlighting ufw ubuntu screen)|' ~/.zshrc

# ustawienie ZSH jako domyślnego shella dla aktualnego użytkownika
sudo chsh -s /bin/zsh "$USER"
