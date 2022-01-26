#!/bin/bash
# asdf + ruby
# Autor: Mikołaj Kamiński (mikolaj-kaminski.com)

if [[ $EUID -ne 0 ]]; then
    echo -e "W celu instalacji tego pakietu potrzebujesz wyzszych uprawnien! Uzyj polecenia \033[1;31msudo ./chce_ruby.sh\033[0m lub zaloguj sie na konto roota i wywolaj skrypt ponownie."
    exit 1
fi

# Instalacja Git
apt update
apt install -y git

# Instalacja asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.8.1

# Konfiguracja asdf
if [ -n "$ZSH_VERSION" ]; then
    echo '. $HOME/.asdf/asdf.sh' >> ~/.zshrc
    echo '. $HOME/.asdf/completions/asdf.bash' >> ~/.zshrc
    source ~/.zshrc
elif [ -n "$BASH_VERSION" ]; then
    echo '. $HOME/.asdf/asdf.sh' >> ~/.bashrc
    echo '. $HOME/.asdf/completions/asdf.bash' >> ~/.bashrc
    source ~/.bashrc
else
    echo "Uzywasz powloki innej niz Zsh i Bash. Do poprawnego dzialania rbenv koniecznie jest dodanie do skryptu uruchomieniowego Twojej powloki nastepujacych polecen:"
    echo '. $HOME/.asdf/asdf.sh'
    echo '. $HOME/.asdf/completions/asdf.bash'
fi

. $HOME/.asdf/asdf.sh
. $HOME/.asdf/completions/asdf.bash

# Dodanie pluginu Ruby do asdf
asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git

# Instalacja zależności dla Ruby
apt install -y autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev curl

# Instalacja najnowszej wersji Ruby
latest_ruby_version=`asdf latest ruby`
asdf install ruby $latest_ruby_version
asdf global ruby $latest_ruby_version

ruby -v