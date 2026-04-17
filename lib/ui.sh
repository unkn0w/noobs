#!/bin/bash
# Interakcja z uzytkownikiem - noobs_lib modul
[[ -n "${_NOOBS_UI_LOADED:-}" ]] && return 0
readonly _NOOBS_UI_LOADED=1

ask_input() {
    local text="$1"
    local default="$2"

    if [[ -n "$default" ]]; then
        text="$text [domyslnie: $default]"
    fi

    echo -e -n "$text: ${_C_YELLOW}"
    read -r REPLY
    echo -e -n "${_C_RESET}"

    REPLY="${REPLY:-$default}"
}

ask_yes_no() {
    local question="$1"
    local default="${2:-n}"
    local prompt

    if [[ "$default" == "t" ]]; then
        prompt="[T/n]"
    else
        prompt="[t/N]"
    fi

    echo -e -n "$question $prompt: ${_C_YELLOW}"
    read -r REPLY
    echo -e -n "${_C_RESET}"

    REPLY="${REPLY:-$default}"
    [[ "$REPLY" =~ ^[tTyY]$ ]]
}

ask_password() {
    local prompt="${1:-Podaj haslo}"
    echo -e -n "$prompt: "
    read -rs REPLY
    echo
}

ask_password_confirm() {
    local password password_repeat

    while true; do
        echo -n "Podaj haslo (zostaw puste aby wygenerowac): "
        read -rs password
        echo

        if [[ -z "$password" ]]; then
            REPLY=$(generate_password 12)
            msg_info "Wygenerowane haslo: $REPLY"
            return 0
        fi

        echo -n "Powtorz haslo: "
        read -rs password_repeat
        echo

        if [[ "$password" == "$password_repeat" ]]; then
            REPLY="$password"
            return 0
        else
            msg_error "Hasla sie nie zgadzaja, sprobuj ponownie!"
        fi
    done
}

ask_choice() {
    local question="$1"
    shift
    local options=("$@")
    local i=1

    echo "$question"
    for opt in "${options[@]}"; do
        echo "  $i) $opt"
        ((i++))
    done

    echo -e -n "Wybierz [1-${#options[@]}]: ${_C_YELLOW}"
    read -r REPLY
    echo -e -n "${_C_RESET}"

    if [[ "$REPLY" =~ ^[0-9]+$ ]] && [[ "$REPLY" -ge 1 ]] && [[ "$REPLY" -le ${#options[@]} ]]; then
        REPLY="${options[$((REPLY-1))]}"
        return 0
    else
        msg_error "Nieprawidlowy wybor."
        return 1
    fi
}
