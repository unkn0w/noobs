#!/usr/bin/env bash
# asdf + ruby
# Autor: Mikołaj Kamiński (mikolaj-kaminski.com)

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

require_root

# Instalacja Git
pkg_update
pkg_install git

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
pkg_install autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev curl

# Instalacja najnowszej wersji Ruby
latest_ruby_version=`asdf latest ruby`
asdf install ruby $latest_ruby_version
asdf global ruby $latest_ruby_version

ruby -v
