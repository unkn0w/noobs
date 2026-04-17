#!/bin/bash
# Zarzadzanie uslugami systemd - noobs_lib modul
[[ -n "${_NOOBS_SERVICES_LOADED:-}" ]] && return 0
readonly _NOOBS_SERVICES_LOADED=1

service_exists() {
    local service="$1"
    [[ $(systemctl list-units --all -t service --full --no-legend "$service.service" | \
         sed 's/^\s*//g' | cut -f1 -d' ') == "$service.service" ]]
}

service_is_active() {
    systemctl is-active --quiet "$1"
}

service_start() {
    msg_info "Uruchamianie uslugi: $1"
    if systemctl start "$1"; then
        msg_ok "Usluga '$1' uruchomiona."
    else
        msg_error "Nie udalo sie uruchomic uslugi '$1'."
        return 1
    fi
}

service_stop() {
    msg_info "Zatrzymywanie uslugi: $1"
    if systemctl stop "$1" 2>/dev/null; then
        msg_ok "Usluga '$1' zatrzymana."
    else
        msg_warn "Usluga '$1' nie byla uruchomiona lub wystapil blad."
    fi
}

service_restart() {
    msg_info "Restartowanie uslugi: $1"
    if systemctl restart "$1"; then
        msg_ok "Usluga '$1' zrestartowana."
    else
        msg_error "Nie udalo sie zrestartowac uslugi '$1'."
        return 1
    fi
}

service_enable() {
    msg_info "Dodawanie uslugi '$1' do autostartu..."
    systemctl enable "$1"
}

service_enable_now() {
    msg_info "Uruchamianie i dodawanie do autostartu: $1"
    systemctl enable --now "$1"
}

service_is_enabled() {
    systemctl is-enabled --quiet "$1" 2>/dev/null
}

service_status() {
    local service="$1"
    if service_exists "$service"; then
        systemctl status "$service" --no-pager
    else
        msg_error "Usluga '$service' nie istnieje."
        return 1
    fi
}

service_reload() {
    local service="$1"
    msg_info "Przeladowywanie konfiguracji uslugi: $service"
    if systemctl reload "$service" 2>/dev/null; then
        msg_ok "Konfiguracja uslugi '$service' przeladowana."
    else
        msg_warn "Usluga '$service' nie wspiera reload. Restartowanie..."
        service_restart "$service"
    fi
}

service_disable() {
    msg_info "Wylaczanie uslugi '$1' z autostartu..."
    systemctl disable "$1"
}

service_disable_now() {
    msg_info "Zatrzymywanie i wylaczanie z autostartu: $1"
    systemctl disable --now "$1"
}
