#!/bin/bash
# Instalacja MIKRUS-CLI
# Autor: Artur Stefanski

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

_maybe_show_help() {
  if [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ -z $1 ]; then
    printf "
Chce MIKRUS-CLI
Autor: Artur Stefanski \n

sposob uzycia: ./chce_mikrus_cli.sh -s [nazwa_serwera] -k [api_key]
\t-s | --srv \tnazwa serwera mikrus (x999)
\t-k | --key \tAPI Key (https://mikr.us/panel/?a=api)

przyklady:
\t./chce_mikrus_cli.sh -s x999 -k 4f5771adbb050c3cd103ce5372149f0b3620ad81
\t./chce_mikrus_cli.sh --srv x999 --key 4f5771adbb050c3cd103ce5372149f0b3620ad81

"
    exit 1
  fi
}

first_arg="$1"

_maybe_show_help $first_arg

SRV="unset"
KEY="unset"
REMOVE="false"

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -s|--srv)
      SRV="$2"
      shift # past argument
      shift # past value
      ;;
    -k|--key)
      KEY="$2"
      shift # past argument
      shift # past value
      ;;
    --remove)
      REMOVE="true"
      shift # past argument
      ;;
    *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done

if [ $REMOVE == "true" ]; then
  [ -t 0 ] && unalias mikrus
  rm ~/.mikrus_cli.conf
  sudo rm /usr/bin/mikrus
  exit
fi

if [ $SRV == "unset" ] && [ $KEY == "unset" ]; then
  printf "\nWymagane uzycie dwoch parametrow --srv --key\nSprawdz ./chce_mikrus_cli --help\n"
  exit
else

  if [ -f ~/.mikrus_cli.conf ]; then
      echo "Plik konfiguracyjny już istnieje"
      echo "Aby kontynuwoac usun plik ~/.mikrus_cli.conf lub uzyj ./chce_mikrus_cli.sh --remove"
      exit 2
  else
      printf "master_srv=$SRV\nmaster_key=$KEY\n"> ~/.mikrus_cli.conf
      if [ -f ~/.mikrus_cli.conf ]; then
        echo "Utworzono plik konfiguracyjny ~/.mikrus_cli.conf"
      else
        echo "Nie udalo sie utworzyc pliku konfiguracyjnego ~/.mikrus_cli.conf!"
        exit 3
      fi
      SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
      sudo cp ${SCRIPTPATH}/../mikrus-cli/mikrus /usr/bin/mikrus
      sudo chmod +x /usr/bin/mikrus
      pkg_update
      pkg_install jq
      printf "
Przyklady uzycia MIKRUS-CLI:
\tmikrus --help
\tmikrus info
\tmikrus servers -f
"
  fi

fi
