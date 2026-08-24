#!/bin/bash
# Skrypt instaluje powłokę ZSH, dodatek oh-my-zsh, paczkę dodatkowych pluginów i aktywuje te rozszerzenia które mogą ułatwić pracę początkującym
# Autor: Jakub 'unknow' Mrugalski

sudo apt update && sudo apt install -y zsh git

# instalacja oh-my-zsh (RUNZSH=no, zeby instalator nie podmienil powloki i nie przerwal skryptu)
wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O- | RUNZSH=no sh

# instalacja zewnętrznych, niestandardowych rozszerzeń
git clone https://github.com/agkozak/zsh-z ~/.oh-my-zsh/plugins/zsh-z
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/plugins/zsh-syntax-highlighting

# aktywujemy
sed -i 's|plugins=.*|plugins=(git zsh-z docker docker-compose sudo zsh-syntax-highlighting ufw ubuntu screen)|' ~/.zshrc

# ustawienie ZSH jako domyślnego shella dla aktualnego użytkownika
sudo chsh -s /bin/zsh "$USER"
