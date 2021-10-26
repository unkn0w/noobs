#!/bin/bash
# jekyll
# Autor: Mikołaj Kamiński (mikolaj-kaminski.com)

# Sprawdź, czy jest zainstalowany Ruby
command -v ruby >/dev/null 2>&1 || { echo >&2 "Aby zainstalować Jekyll musisz najpierw zainstalować Ruby. Możesz to zrobić przy użyciu skryptu chce_ruby.sh"; exit 1; }

# Zainstaluj potrzebne zależności
apt install -y build-essential zlib1g-dev

# Konfiguracja RubyGems
if [ -n "$ZSH_VERSION" ]; then
    echo 'export GEM_HOME="$HOME/gems"' >> ~/.zshrc
    echo 'export PATH="$HOME/gems/bin:$PATH"' >> ~/.zshrc
    source ~/.zshrc
elif [ -n "$BASH_VERSION" ]; then
    echo 'export GEM_HOME="$HOME/gems"' >> ~/.bashrc
    echo 'export PATH="$HOME/gems/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
else
    echo "Uzywasz powloki innej niz Zsh i Bash. Do poprawnego dzialania RubyGems koniecznie jest dodanie do skryptu uruchomieniowego Twojej powloki nastepujacych polecen:"
    echo 'export GEM_HOME="$HOME/gems"'
    echo 'export PATH="$HOME/gems/bin:$PATH"'
fi

# Instalacja Jekyll i Bundler
gem install jekyll bundler