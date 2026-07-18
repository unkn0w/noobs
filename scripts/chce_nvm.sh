#!/bin/bash
# Node Version Manager
# Repozytorium: https://github.com/nvm-sh/nvm
# Autor: Jakub Suchenek (itsanon.xyz)

if ( ! command -v git > /dev/null 2>&1 ); then
    echo "Instalowanie 'git'..."
    sudo apt-get update && sudo apt-get install git
    if [[ $EUID -ne 0 ]]; then
        echo "Nie można zainstalować 'git'! Sprawdź co się stało powyżej."
        exit 1
    fi
fi

# Ręczna instalacja dla pewniejszych efektów, nie potrzebuje aktualizacji samego skryptu.
# https://github.com/nvm-sh/nvm#manual-install
echo "Pobieranie NVM..."
export NVM_DIR="$HOME/.nvm"
if [ ! -d $NVM_DIR ]; then
    git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
elif [ ! -d "$NVM_DIR/.git" ]; then
    echo "UWAGA: '$NVM_DIR' istnieje, ale nie jest repozytorium git. Usuń '$NVM_DIR' i uruchom ponownie skrypt."
    exit 1
fi
cd "$NVM_DIR"
# Istotne tylko dla aktualizacji wcześniej pobranego repozytorium (dla aktualizacji).
git fetch --tags origin
git checkout $(git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1))
if [[ $? -ne 0 ]]; then
    echo "Wystąpił problem przy pobieraniu NVM! Zobacz co się stało powyżej."
    exit 1
fi

echo "Przygotowywanie automatycznego ładowania..."
LOAD_STRING_FILE="/tmp/nvm_load_string.txt"
touch $LOAD_STRING_FILE
tee $LOAD_STRING_FILE <<EOF

export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh" # This loads nvm
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"  # This loads nvm bash_completion'
EOF

echo "Automatyczne ładowanie dla BASH..."
for SH_PROFILE in ".bashrc" ".profile" ; do
    if [ ! -f "$HOME/$SH_PROFILE" ]; then
        touch "$HOME/$SH_PROFILE"
    fi
    if ( ! grep "^export NVM_DIR=" "$HOME/$SH_PROFILE" > /dev/null 2>&1 ); then
        cat $LOAD_STRING_FILE >> "$HOME/$SH_PROFILE"
    fi
done

if ( command -v zsh > /dev/null 2>&1 ); then
    echo "Automatyczne ładowanie dla ZSH..."
    if [ ! -f "$HOME/.zshrc" ]; then
        touch "$HOME/.zshrc"
    fi
    if ( ! grep "^plugins=([a-z0-9 \-]*nvm" "$HOME/.zshrc" > /dev/null 2>&1 && ! grep "export NVM_DIR=" "$HOME/.zshrc" > /dev/null 2>&1 ); then
        cat $LOAD_STRING_FILE >> "$HOME/.zshrc"
    fi
fi

rm $LOAD_STRING_FILE

echo "Ładowanie NVM..."
source "$NVM_DIR/nvm.sh"
if [[ $? -ne 0 ]]; then
    echo "Nie można załadować NVM! Zobacz co się stało powyżej."
    exit 1
fi

echo "Instalowanie Node.js LTS..."
# '-b' do instalowania tylko z plików binarnych.
# NIE używać '-s', potrzebuje 20~30 GB RAM.
nvm install -b --lts --latest-npm --default
if [[ $? -ne 0 ]]; then
    echo "Instalowanie Node.js LTS się nie powiodło! Zobacz co się stało powyżej."
    exit 1
fi

echo ""
echo "***** Gotowe! *****"
echo "> Poprawnie zainstalowano NVM wraz z najnowszym Node.js LTS."
echo "> Aby zacząć korzystać, uruchom ponownie sesję (wyloguj i zaloguj)."
echo "> Korzytaj wpisując 'nvm' lub od razu 'npm'."
echo "> Używając '$0' ponownie, możesz zaktualizować NVM i Node.js."
echo ""
