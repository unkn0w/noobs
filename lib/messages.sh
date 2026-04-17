#!/bin/bash
# Kolory i komunikaty - noobs_lib modul
[[ -n "${_NOOBS_MESSAGES_LOADED:-}" ]] && return 0
readonly _NOOBS_MESSAGES_LOADED=1

readonly _C_RESET='\e[0m'
readonly _C_RED='\e[31m'
readonly _C_GREEN='\e[32m'
readonly _C_YELLOW='\e[33m'
readonly _C_BLUE='\e[34m'
readonly _C_BOLD='\e[1m'

noobs_colors_init() {
    export NOOBS_C_RESET="${_C_RESET}"
    export NOOBS_C_RED="${_C_RED}"
    export NOOBS_C_GREEN="${_C_GREEN}"
    export NOOBS_C_YELLOW="${_C_YELLOW}"
    export NOOBS_C_BLUE="${_C_BLUE}"
    export NOOBS_C_BOLD="${_C_BOLD}"
}

msg_info() {
    echo -e "${_C_BLUE}[INFO]${_C_RESET} $1"
}

msg_ok() {
    echo -e "${_C_GREEN}[OK]${_C_RESET} $1"
}

msg_error() {
    echo -e "${_C_RED}[ERR]${_C_RESET} $1" >&2
}

msg_warn() {
    echo -e "${_C_YELLOW}[WARN]${_C_RESET} $1"
}

msg_status() {
    echo -e "${_C_GREEN}[x] ${_C_BOLD}${_C_GREEN}$1${_C_RESET}"
}

msg_debug() {
    [[ "${DEBUG:-0}" == "1" ]] && echo -e "${_C_YELLOW}[DEBUG]${_C_RESET} $1"
}

header_info() {
    local app_name="${1:-Skrypt}"
    echo -e "\n=== $app_name ===\n"
}

print_separator() {
    local char="${1:--}"
    local width="${2:-60}"
    printf '%*s\n' "$width" '' | tr ' ' "$char"
}
