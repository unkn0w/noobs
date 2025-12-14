#!/bin/bash
# Author: Koliw (https://github.com/koliwbr/)
# Platformy: all
# Kompatybilne z serwerami frog

# Skrypt pobiera klucze podanego użytkownika z GitHub i dodaje je do zaufanych

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

if [[ ! "$1" =~ [a-z]{4,38} ]]; then
	msg_error "Jako paramert skryptu podaj nazwę użytkownika GitHub"
	msg_error "Na przykład $0 koliwbr pobiera klucze użytkownika koliwbr."
	msg_error "Koniecznie zamień na własną nazwę użytkownika!"
	exit 1
fi

TMPFILENAME=`mktemp`

if curl "https://github.com/$1.keys" -sf > $TMPFILENAME; then echo -n; else
	msg_error "Nie znaleziono użytkownika $1 na GitHub"
	rm $TMPFILENAME
	exit 2

fi

if [[ ! -s $TMPFILENAME ]]; then
	msg_error "Znaleziono użytkownika $1 na GitHub ale nie masz żadnich kluczy SSH"
	msg_error "Poniżej informacja jak je dodać do konta GitHub"
	msg_error "https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account#prerequisites"
	rm $TMPFILENAME
	exit 3

fi

mkdir $HOME/.ssh -p
cat $TMPFILENAME >> $HOME/.ssh/authorized_keys
msg_ok "Dodano `cat $TMPFILENAME | wc -l` klucz/e/y! Teraz możesz się logować swoimi kluczem/ami z GitHub!"
rm $TMPFILENAME
