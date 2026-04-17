#!/bin/bash
# Uslugi Systemd - noobs_lib modul
[[ -n "${_NOOBS_SYSTEMD_LOADED:-}" ]] && return 0
readonly _NOOBS_SYSTEMD_LOADED=1

# Uzycie: create_systemd_service <name> <description> <exec_start> [user] [after] [restart]
create_systemd_service() {
    local service_name="$1"
    local description="$2"
    local exec_start="$3"
    local user="${4:-root}"
    local after="${5:-network.target}"
    local restart="${6:-on-failure}"

    [[ -z "$service_name" ]] && { msg_error "Nie podano nazwy uslugi."; return 1; }
    [[ -z "$description" ]] && { msg_error "Nie podano opisu."; return 1; }
    [[ -z "$exec_start" ]] && { msg_error "Nie podano komendy uruchomienia."; return 1; }

    local service_file="/etc/systemd/system/${service_name}.service"

    msg_info "Tworzenie uslugi systemd: $service_name"

    cat > "$service_file" <<EOF
[Unit]
Description=${description}
After=${after}

[Service]
Type=simple
User=${user}
ExecStart=${exec_start}
Restart=${restart}
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload

    msg_ok "Usluga systemd utworzona: $service_file"
}

# Uzycie: create_systemd_timer <name> <on_calendar> <description>
create_systemd_timer() {
    local timer_name="$1"
    local on_calendar="$2"
    local description="${3:-Timer for $timer_name}"

    [[ -z "$timer_name" ]] && { msg_error "Nie podano nazwy timera."; return 1; }
    [[ -z "$on_calendar" ]] && { msg_error "Nie podano harmonogramu."; return 1; }

    local timer_file="/etc/systemd/system/${timer_name}.timer"

    msg_info "Tworzenie timera systemd: $timer_name"

    cat > "$timer_file" <<EOF
[Unit]
Description=${description}

[Timer]
OnCalendar=${on_calendar}
Persistent=true

[Install]
WantedBy=timers.target
EOF

    systemctl daemon-reload

    msg_ok "Timer systemd utworzony: $timer_file"
}

# Uzycie: delete_systemd_service <name>
delete_systemd_service() {
    local service_name="$1"

    [[ -z "$service_name" ]] && { msg_error "Nie podano nazwy uslugi."; return 1; }

    local service_file="/etc/systemd/system/${service_name}.service"
    local timer_file="/etc/systemd/system/${service_name}.timer"

    msg_info "Usuwanie uslugi systemd: $service_name"

    systemctl stop "${service_name}.service" 2>/dev/null
    systemctl disable "${service_name}.service" 2>/dev/null

    rm -f "$service_file"
    rm -f "$timer_file"

    systemctl daemon-reload

    msg_ok "Usluga systemd usunieta: $service_name"
}
