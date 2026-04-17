#!/bin/bash

if [[ -n "$(grep 'policz' ~/.bash_aliases)" ]]; then
    echo "Już dodano aliasy z tego pliku"
    exit 0
fi

echo '
alias ..="cd .."
alias ...="cd ../../"
alias ....="cd ../../../"
alias .4="cd ../../../"
alias .5="cd ../../../../"

alias l="ls -CF"
alias l.="ls -d .* --color=auto"
alias la="ls -A"
alias ll="ls -alF"

function doprzodu() {
    SPECIFIED_BRANCH=$1
    if [[ -z "$SPECIFIED_BRANCH" ]]; then
        echo "Nie podano nazwy gałęzi - podaj ją jako argument"
        return
    fi
    COMMIT_TO_CHECKOUT="$(git rev-list --topo-order HEAD.."$1" | tail -1)"
    if [[ -z "$COMMIT_TO_CHECKOUT" ]]; then
        echo "Brak następnych commitów"
        git checkout "$SPECIFIED_BRANCH"
        return
    else
        git checkout "$COMMIT_TO_CHECKOUT"
    fi
}

alias gs="git status"
# Pokaż *całą* historię gita w przejrzystej formie
alias gsall="git log --branches --remotes --tags --graph --oneline --decorate"

alias ipe="curl ipinfo.io/ip; echo"
alias ports="netstat -tulanp"
alias policz="du -m --max-depth 1 | sort -n"
alias jsonf="python -m json.tool"
alias losuj="python -c '\''from os import urandom; from base64 import b64encode; print(b64encode(urandom(32)).decode(\"utf-8\"))'\''"
' >>~/.bash_aliases

echo "Pomyślnie dodano aliasy!"
echo "Upewnij się, że plik ~/.bash_aliases jest ładowany przy tworzeniu nowego basha."
