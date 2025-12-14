#!/bin/bash
# Dodanie do aktualnego $PS1 statusu repozytorium gita bieżącego katalogu
# Autorzy: Tomasz Wiśniewski, krystofair @ 2025-09-22

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

msg_info "Jeśli twoja wybrana powłoka nie zadziała, to spróbuj zainstalować do 'bash'."
sleep 1

if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

GIT_PROMPT_FILE=/tmp/git-prompt.sh

# 1. Parametr - wybrana powłoka
# 2. Parametr - wybrany sposób instalacji
# Zmianna 'ipath' przechowuje zwracaną wartość
get_install_path_for_specific_shell() {
  if [[ $2 == system ]]; then
    case $1 in
      bash) ipath=/etc/profile.d/git-ps1.sh ;;
      csh) ipath=/etc/csh.cshrc ;;
      zsh) ipath=/etc/zsh/zshrc.d/git-ps1.zsh ;;
    esac
  elif [[ $2 == user ]]; then
    case $1 in
      bash) ipath=$HOME/.bashrc ;;
      csh) ipath=$HOME/.cshrc ;;
      zsh) ipath=$HOME/.zshrc ;;
    esac
  fi

  if test -n "$ipath"
  then
    echo $ipath
    return 0
  fi
  return 1;
}

# Miejsce instalacji - katalog domowy użytkownika lub /etc/.profile = system wide.
# Jeśli użytkownik wykonujący skrypt ma UID 0 - jest root'em to opcja jest domyślnie
# dla wszystkich ponieważ ma on odpowiednie uprawnienia. W pozostałych przypadkach
# instalacja będzie w /home/$USER.
choose_installation_place() {
  all_user_install_hint="y/N"
  def_val=n
  if test $UID = 0; then
    all_user_install_hint="Y/n";
    def_val=y
  fi
  read -p "Czy zainstalować dla wszystkich użytkowników? ${all_user_install_hint}: " \
  all_user_install
  case ${all_user_install:-$def_val} in
    y|Y|1|yes) install_place='system';;
    n|N|0|no) install_place='user';;
    *)
        if test -n "$(echo $install_place_hint | grep -o Y)"
        then install_place='system'
        else install_place='user'
        fi
      ;;
  esac
  unset def_val
  unset all_user_install_hint
  unset all_user_install

  echo $install_place
  unset install_place
  return 0
}

# XXX: Przeczytaj plik z repozytorium gita,
#      jeśli chcesz dodać jeszcze jakieś funkcjonalności.
choose_features() {
  read -p "Czy wyświetlać stan kiedy występuje konflikt podczas 'merge'u itp? y/N: " r
  if test -n "$(echo $r | grep -i y)"; then
    echo "export GIT_PS1_SHOWCONFLICTSTATE=$r;"
  fi
  unset r

  read -p "Czy wyświetlać tzw dirty state (pliki zmodyfikowane itp)? Y/n: " r
  if test -n "$(echo ${r:-y} | grep -i y)"; then
    echo "export GIT_PS1_SHOWDIRTYSTATE=${r:-y};"
  fi
  unset r

  read -p "Czy wyświetlać symbol \$ kiedy są pliki w 'git stash'? y/N: " r
  if test -n "$(echo $r | grep -i y)"; then
    echo "export GIT_PS1_SHOWSTASHSTATE=$r;"
  fi
  unset r

  read -p "Czy ukrywać status kiedy folder jest ignorowany przez GITa? Y/n: " r
  if test -n "$(echo ${r:-y} | grep -i y)"; then
    echo "export GIT_PS1_HIDE_IF_PWD_IGNORED=${r:-y};"
  fi
  unset r

  read -p "Czy chcesz, aby status wyświetlał się w różnym kolorze w zależności od stanu? Y/n: " r
  if test -n "$(echo ${r:-y} | grep -i y)"; then
    echo "export GIT_PS1_SHOWCOLORHINTS=${r:-y};"
  fi
  unset r

  return 0
}

# Wypisuje powłoki z pliku /etc/shells - tam są trzymane wszystkie dostępne.
# Grepem wykluczam komentarze - linie rozpoczęte od '#'.
# Odwracam, aby w łatwy sposób wyciągnąć nazwy powłok, wycinam i biorę pierwsze pole.
# Przywracam tekst z lewej do prawej i sortuję ponieważ inaczej 'uniq' nie zadziała.
# Na końcu używam xargs, który tworzy ciąg nazw podzielonych spacją.
# Wszystko jest wczytane do tablicy "accessible_shells".
choose_shell() {
    all_shells=$(cat /etc/shells \
    | grep -Ev '^#' \
    | rev | tr -s ' ' | cut -d'/' -f1 \
    | rev | sort | uniq \
    | xargs | tr ' ' ','
  )

  def_sh=$(echo $SHELL | rev | cut -d'/' -f1 | rev)
  read -p "Wybierz powłokę[$def_sh] spośród $all_shells: " chosen_shell
  unset all_shells
  unset def_sh
  if test -z "$chosen_shell"; then chosen_shell='bash'; fi
  # Sprawdzenie obsługiwanych powłok.
  case $chosen_shell in
    sh|bash) chosen_shell='bash';;
    # tcsh) chosen_shell='csh';; XXX: tcsh ma inny plik ~/.tcshrc, ale system-wide wiem
    csh) chosen_shell='csh';;
    zsh) : ;;
    *)
      echo "Wybrana powłoka jest nieobsługiwana, przepraszamy."
      unset chosen_shell
      return -1
    ;;
  esac
  echo $chosen_shell
  unset chosen_shell
  return 0
}

ch_shell=$(choose_shell)
if [[ ! $? -eq 0 ]]; then echo $ch_shell; exit -1; fi

installation_type=$(choose_installation_place)
install_path=$(get_install_path_for_specific_shell $ch_shell $installation_type)
if [[ ! $? -eq 0 ]]; then msg_error "Coś poszło nie tak."; exit -1; fi


if [[ ! -e $GIT_PROMPT_FILE ]]
then
    # https://anotheruiguy.gitbooks.io/gitforeveryone/content/auto/README.html
    GIT_PROMPT_FILE_URL="https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh"
    msg_info "Pobieram plik $GIT_PROMPT_FILE_URL"
    curl -o $GIT_PROMPT_FILE "$GIT_PROMPT_FILE_URL"
fi

features="$(choose_features)"

if [[ -e $(dirname $install_path)/git-prompt.sh ]]; then
  rm $(dirname $install_path)/git-prompt.sh
fi

if [[ $installation_type == system ]]; then FILENAME=git-prompt.sh
else FILENAME=.git-prompt.sh
fi

# W tym miejscu nie ma sprawdzenia czy plik już istnieje,
# ze względu na to, że jeżeli użytkownik namiesza w oryginalnym pliku,
# to uruchomienie skryptu po raz drugi naprawi mu ten plik.
msg_info "Instaluję plik $FILENAME w katalogu $(dirname $install_path)"
install -m 0644 $GIT_PROMPT_FILE $(dirname $install_path)/$FILENAME

if test -e $install_path && test -n "$(cat $install_path | grep __git_ps1)"
then
  msg_info "Masz to już zainstalowane."
  unset ch_shell
  unset installation_type
  unset install_path
  exit -1
fi

# Wykorzystuje "features" z globalnego kontekstu
choose_ps1_format() {
  echo "Możliwe formaty, \\e... to escape dla oznaczenia koloru" 1>&2
  FORMATS=$'
1.(<GIT-STATUS>)[<USER>@<HOST>] <PWD><ONL>$
2.(<GIT-STATUS>) [<USER>@<HOST>] <PWD><ONL>$
3.<USER>@<HOST> <PWD> (<GIT-STATUS>)<ONL>$
4.<USER>@<HOST> \\e[33m<PWD>\\e[00m (<GIT-STATUS>)<ONL>$
5.<USER>@<HOST> \\e[33m<PWD>\\e[00m <GIT-STATUS><ONL>$
6.<USER>@<HOST> \\e[33m<PWD>\\e[00m <GIT-STATUS><ONL><DATE>$
'
  echo "$FORMATS" 1>&2
  read -p "Wybierz format: " format_nr
  case $format_nr in
    1|2|3|4|5|6) : ;;
    *) echo "Niepoprawny wybor." 1>&2; return -1 ;;
  esac
  format=$(echo "$FORMATS" | grep -F $format_nr.)
  format=${format##??}
  read -p "Czy chcesz mieć znak zachęty w nowej linii? Y/n: " r
  ONL=${r:-y}; unset r
  if test "$ONL" = y;
  then format=${format/"<ONL>"/\\n};
  else format=${format/"<ONL>"/}
  fi

  unset FORMATS
  unset ONL
  unset DOT

  #### BUILD PS1 FROM FORMAT ####
  format=${format/"<USER>"/\\u}
  format=${format/"<HOST>"/\\h}
  format=${format/"<PWD>"/\\w}
  format=${format/"<GIT-STATUS>"/'$(__git_ps1 %s)'}
  if test $format_nr -eq '6'
  then
    format=${format/"<DATE>"/'$(date +[%H:%M])'}
  fi

  echo $format
  unset format

  return 0
}

if test $ch_shell = bash || test $ch_shell = csh
then
  new_ps1=$(choose_ps1_format)
  if [[ ! $? -eq 0 ]]; then
    msg_error "Wybrano zły format, nie robię nic, kończę."
    msg_info "Uruchom mnie ponownie."
    exit 0
  fi
fi

msg_info "Dodaję nowe instrukcje do pliku $install_path"
echo "# === Dodane przez skrypt 'chce_git_status_PS1.sh'. ===" >> $install_path
echo "$features" >> $install_path
echo 'if [[ -z $(declare -F | grep __git_ps1) ]]; then' >> $install_path
echo "source $(dirname $install_path)/$FILENAME" >> $install_path
echo 'fi' >> $install_path
case $ch_shell in
  bash|csh)
    echo $"export PS1='$new_ps1 '" >> $install_path
    # echo $'export PS1=\'$(__git_ps1 \(%s%s\))[\u@\h \w]\n$ \'' >> $install_path
  ;;
  zsh)
    echo $'setopt PROMPT_SUBST; PS1=\'[%n@%m %c$(__git_ps1 \" (%s)\")]\$ \'' >> $install_path
  ;;
esac
echo "# =====================================================" >> $install_path

# not going to work
# source $install_path  # apply immediately

unset install_path
unset ch_shell
unset installation_type
unset features
unset FILENAME
rm -f $GIT_PROMPT_FILE

exit 0
