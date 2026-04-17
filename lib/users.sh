#!/bin/bash
# Zarzadzanie uzytkownikami - noobs_lib modul
[[ -n "${_NOOBS_USERS_LOADED:-}" ]] && return 0
readonly _NOOBS_USERS_LOADED=1

# Uzycie: create_system_user <username> [home_dir] [description]
create_system_user() {
    local username="$1"
    local home_dir="${2:-/var/lib/$username}"
    local description="${3:-$username service account}"

    [[ -z "$username" ]] && { msg_error "Nie podano nazwy uzytkownika."; return 1; }

    if user_exists "$username"; then
        msg_warn "Uzytkownik systemowy '$username' juz istnieje."
        return 0
    fi

    msg_info "Tworzenie uzytkownika systemowego: $username"

    useradd -r -s /bin/false -d "$home_dir" -m -c "$description" "$username"

    if [[ -d "$home_dir" ]]; then
        chown -R "${username}:${username}" "$home_dir"
        chmod 750 "$home_dir"
    fi

    msg_ok "Uzytkownik systemowy '$username' utworzony."
}

# Uzycie: set_web_permissions <path> [owner] [group]
set_web_permissions() {
    local path="$1"
    local owner="${2:-www-data}"
    local group="${3:-www-data}"

    [[ -z "$path" ]] && { msg_error "Nie podano sciezki."; return 1; }
    [[ ! -e "$path" ]] && { msg_error "Sciezka nie istnieje: $path"; return 1; }

    msg_info "Ustawianie uprawnien dla: $path"

    chown -R "${owner}:${group}" "$path"

    find "$path" -type d -exec chmod 755 {} \;
    find "$path" -type f -exec chmod 644 {} \;

    for writable_dir in "cache" "tmp" "var" "uploads" "files" "storage" "logs"; do
        if [[ -d "${path}/${writable_dir}" ]]; then
            chmod -R 775 "${path}/${writable_dir}"
            msg_debug "Katalog zapisywalny: ${path}/${writable_dir}"
        fi
    done

    msg_ok "Uprawnienia ustawione dla: $path"
}

# Uzycie: create_web_user <username> [home_dir] [shell] [chroot_ssh]
# Zwraca: haslo w REPLY
create_web_user() {
    local username="$1"
    local home_dir="${2:-/home/$username}"
    local shell="${3:-/bin/bash}"
    local chroot_ssh="${4:-false}"

    [[ -z "$username" ]] && { msg_error "Nie podano nazwy uzytkownika."; return 1; }

    if user_exists "$username"; then
        msg_warn "Uzytkownik '$username' juz istnieje."
        return 0
    fi

    msg_info "Tworzenie uzytkownika: $username"

    local password
    password=$(generate_password 12)

    useradd -m -d "$home_dir" -s "$shell" "$username"
    echo "${username}:${password}" | chpasswd

    msg_ok "Uzytkownik '$username' utworzony."

    if [[ "$chroot_ssh" == "true" ]]; then
        msg_info "Konfigurowanie chroot SSH dla $username"

        if ! grep -q "Match User $username" /etc/ssh/sshd_config; then
            cat >> /etc/ssh/sshd_config <<EOF

Match User $username
    ChrootDirectory $home_dir
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
EOF
            service_reload sshd 2>/dev/null || service_reload ssh 2>/dev/null
            msg_ok "Chroot SSH skonfigurowany dla $username"
        fi
    fi

    REPLY="$password"
    msg_info "Haslo uzytkownika: $password"
}

# Uzycie: delete_web_user <username> [remove_home]
delete_web_user() {
    local username="$1"
    local remove_home="${2:-false}"

    [[ -z "$username" ]] && { msg_error "Nie podano nazwy uzytkownika."; return 1; }

    if ! user_exists "$username"; then
        msg_warn "Uzytkownik '$username' nie istnieje."
        return 0
    fi

    msg_info "Usuwanie uzytkownika: $username"

    if [[ "$remove_home" == "true" ]]; then
        userdel -r "$username" 2>/dev/null
    else
        userdel "$username" 2>/dev/null
    fi

    if grep -q "Match User $username" /etc/ssh/sshd_config; then
        sed -i "/Match User $username/,/^Match\|^$/d" /etc/ssh/sshd_config
        service_reload sshd 2>/dev/null || service_reload ssh 2>/dev/null
    fi

    msg_ok "Uzytkownik '$username' usuniety."
}
