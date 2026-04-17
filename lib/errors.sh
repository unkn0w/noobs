#!/bin/bash
# Obsluga bledow i pomoc - noobs_lib modul
[[ -n "${_NOOBS_ERRORS_LOADED:-}" ]] && return 0
readonly _NOOBS_ERRORS_LOADED=1

die() {
    msg_error "$1"
    exit "${2:-1}"
}

trap_error() {
    trap 'msg_error "Blad w linii $LINENO. Kod wyjscia: $?"' ERR
}

safe_exit() {
    local code="${1:-0}"
    if [[ -n "${_NOOBS_TEMP_DIR:-}" ]] && [[ -d "$_NOOBS_TEMP_DIR" ]]; then
        cleanup_temp "$_NOOBS_TEMP_DIR"
    fi
    exit "$code"
}

run_or_die() {
    local cmd="$1"
    local error_msg="${2:-Blad podczas wykonywania: $cmd}"

    if ! eval "$cmd"; then
        die "$error_msg"
    fi
}

show_help_template() {
    local name="$1"
    local description="$2"
    shift 2

    echo "Uzycie: $name [opcje]"
    echo ""
    echo "$description"
    echo ""
    echo "Opcje:"
    for opt in "$@"; do
        echo "  $opt"
    done
}

show_version() {
    local name="$1"
    local version="$2"
    echo "$name wersja $version"
    echo "Biblioteka noobs_lib.sh wersja ${NOOBS_LIB_VERSION:-}"
}

# Aliasy wstecznej kompatybilnosci
_ask_input() { ask_input "$@"; }
_service_exists() { service_exists "$@"; }
status() { msg_status "$@"; }
err() { die "$@"; }
