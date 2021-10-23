#!/bin/bash
# Dodanie do aktualnego $PS1 statusu repozytorium gita bieżącego katalogu
# Autor: Tomasz Wiśniewski

if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

ALL_FUNCTIONS="$(declare -F)"

if [[ "$ALL_FUNCTIONS" == *"__git_ps1"* ]]; then
    echo "Funkcja __git_ps1 jest rozpoznawana"
else
    # https://anotheruiguy.gitbooks.io/gitforeveryone/content/auto/README.html
    GIT_PROMPT_FILE_URL="https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh"
    echo "Pobieram plik $GIT_PROMPT_FILE_URL"
    curl -o ~/.git-prompt.sh "$GIT_PROMPT_FILE_URL"
    echo 'source ~/.git-prompt.sh' >>~/.bashrc
fi

TRIMMED_DOLLAR_SIGN_PS1="${PS1/\\$/}"
TRIMMED_PS1="${TRIMMED_DOLLAR_SIGN_PS1%%*( )}"

if [[ "$TRIMMED_PS1" == *"__git_ps1"* ]]; then
    echo "Prawdopodobnie masz już ustawione docelowe \$PS1"
    return
fi

GIT_PART='$([[ -z $(git status -s 2>/dev/null) ]] && echo "\[\e[32m\]" || echo "\[\e[31m\]")$(__git_ps1 "(%s)")\[\e[00m\]\$ '
PS1="$TRIMMED_PS1$GIT_PART"
echo "Ustawię \$PS1 na $PS1"
echo "export PS1='$PS1'" >>~/.bashrc
echo "Dodano pomyślnie"
