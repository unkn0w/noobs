#!/bin/bash
# =============================================================================
# noobs_lib.sh - Wspolna biblioteka dla projektu noobs
# =============================================================================
# Autor: Bartłomiej Zimny (github.com/jash90, bartlomiejzimny@outlook.com)
# Wersja: 2.0.0
# Licencja: MIT
#
# Uzycie:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1
# =============================================================================

[[ -n "${_NOOBS_LIB_LOADED:-}" ]] && return 0
readonly _NOOBS_LIB_LOADED=1
readonly NOOBS_LIB_VERSION="2.0.0"

_NOOBS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_noobs_source() {
    local module="${_NOOBS_LIB_DIR}/$1"
    if [[ -f "$module" ]]; then
        # shellcheck source=/dev/null
        source "$module" || { echo "[ERR] Nie udalo sie zaladowac: $module" >&2; return 1; }
    else
        echo "[ERR] Brakujacy modul: $module" >&2
        return 1
    fi
}

_noobs_source messages.sh
_noobs_source permissions.sh
_noobs_source packages.sh
_noobs_source repos.sh
_noobs_source services.sh
_noobs_source ui.sh
_noobs_source utils.sh
_noobs_source files.sh
_noobs_source config.sh
_noobs_source users.sh
_noobs_source errors.sh
_noobs_source mysql.sh
_noobs_source php.sh
_noobs_source apache.sh
_noobs_source nginx.sh
_noobs_source systemd.sh
