#!/bin/bash
# rbenv + ruby
# Autor: Mikołaj Kamiński (mikolaj-kaminski.com)

if [[ $EUID -ne 0 ]]; then
    echo -e "W celu instalacji tego pakietu potrzebujesz wyzszych uprawnien! Uzyj polecenia \033[1;31msudo ./chce_ruby.sh\033[0m lub zaloguj sie na konto roota i wywolaj skrypt ponownie."
    exit 1
fi

# Instalacja rbenv
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer | bash

# Konfiguracja rbenv
if [ -n "$ZSH_VERSION" ]; then
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc
    echo 'eval "$(rbenv init -)"' >> ~/.zshrc
    source ~/.zshrc
elif [ -n "$BASH_VERSION" ]; then
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc
    source ~/.bashrc
else
    echo "Uzywasz powloki innej niz Zsh i Bash. Do poprawnego dzialania rbenv koniecznie jest dodanie do skryptu uruchomieniowego Twojej powloki nastepujacych polecen:"
    echo "export PATH=\"\$HOME/.rbenv/bin:\$PATH\""
    echo "eval \"\$(rbenv init -)\""
fi

latest_ruby_version=`rbenv install -l | grep -v - | tail -1`

# Instalacja najnowszej wersji Ruby
rbenv install $latest_ruby_version

# Ustawienie najnowszej wersji Ruby jako domyślnej
rbenv global $latest_ruby_version
