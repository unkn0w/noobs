#!/bin/bash
# Node Version Manager
# Repozytorium: https://github.com/nvm-sh/nvm
# Autor: Jakub Suchenek (itsanon.xyz)

# Dozwól uruchamianie jako 'root', ale tylko wtedy, kiedy jest to jedyne konto.
DEFAULT_USER=$(getent passwd 1000 | cut -d ":" -f 1)
if [[ $EUID -eq 0 && -n $DEFAULT_USER ]]; then
    echo -e "UWAGA: skrypt uruchomiony jako 'root'. Spróbuj jeszcze raz, ale bez 'sudo'."
    exit 1
fi

if [[ ! command -v git > /dev/null 2>&1 ]]; then
    echo "Instalowanie 'git'..."
    sudo apt-get update && sudo apt-get install git
fi

# Ręczna instalacja dla pewniejszych efektów, nie potrzebuje aktualizacji skryptu.
# https://github.com/nvm-sh/nvm#manual-install
echo "Pobieranie NVM..."
NVM_DIR="$HOME/.nvm"
git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
cd "$NVM_DIR"
git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`

LOAD_STRING=$(cat <<EOF
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
EOF
)

echo "Automatycznie ładowanie dla BASH..."
for SH_PROFILE in ".bashrc", ".profile"; do
    $LOAD_STRING >> "~/$SH_PROFILE"
done

if [[ command -v zsh > /dev/null 2>&1 ]]; then
    echo "Automatycznie ładowanie dla ZSH..."
    $LOAD_STRING >> "~/.zshrc",
fi

source "$NVM_DIR/nvm.sh"
if [[ $? -ne 0 ]]; then
    echo "Nie można załadować NVM! Zobacz co się stało powyżej."
    exit 1
fi

echo "Instalowanie Node.js LTS..."
nvm install -b --lts --latest-npm --default
if [[ $? -ne 0 ]]; then
    echo "Instalowanie Node.js LTS się nie powiodło! Zobacz co się stało powyżej."
    exit 1
fi

echo ""
echo "***** Gotowe! *****"
echo "Poprawnie zainstalowano NVM wraz z najnowszych Node.js LTS."
echo "Możesz zacząć korzytasz wpisując 'nvm' lub od razu 'npm'."
echo ""
