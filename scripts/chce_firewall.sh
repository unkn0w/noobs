#!/bin/bash
#
# firewall
# Wersja: 1.1
# Autorzy: Kacper Adamczak, Mariusz Gumienny

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

# Skrypt do konfiguracji firewalla UFW.

# Użycie:
#   sudo ~/noobs/scripts/chce_firewall.sh [port1] [port2] ...


msg_info "Aktualizowanie listy pakietów..."
pkg_update

msg_info "Instalowanie wymaganych pakietów (ufw, ipset)..."
pkg_install ufw ipset

add_port() {
    local port_to_add=$1
    if sudo ufw allow "$port_to_add"; then
        msg_ok "Do reguł firewalla poprawnie dodano port $port_to_add"
    else
        msg_error "Błąd dodawania portu $port_to_add do reguł firewalla."
    fi
}

msg_info "Konfigurowanie domyślnych polityk UFW..."
sudo ufw default deny incoming
sudo ufw default allow outgoing

msg_info "Dodawanie standardowych reguł..."
add_port "OpenSSH"
add_port "ssh"

host_num="$(hostname)"
host_num="${host_num##*[!0-9]}" # Wyciąga sam numer z nazwy hosta (np. zygfryd123 -> 123)

if [[ -n "$host_num" ]]; then
    port1=$((10000 + host_num))
    port2=$((20000 + host_num))
    port3=$((30000 + host_num))

    msg_info "Dodawanie standardowych portów Mikrus (host $host_num)..."
    add_port "$port1"
    add_port "$port2"
    add_port "$port3"
else
    echo "⚠️  Ostrzeżenie: Nie udało się automatycznie ustalić numeru hosta. Pomijam dodawanie portów Mikrus."
fi

if [ "$#" -gt 0 ]; then
    msg_info "Dodawanie dodatkowych portów z linii poleceń..."
    for extra_port in "$@"; do
        if [[ "$extra_port" =~ ^[0-9]+$ ]] && (( extra_port >= 1 && extra_port <= 65535 )); then
            add_port "$extra_port"
        else
            echo "⚠️  Ostrzeżenie: Argument '$extra_port' nie jest poprawnym numerem portu (1-65535) i został zignorowany."
        fi
    done
fi

msg_info "Finalizowanie konfiguracji..."

sudo ufw enable

msg_ok "Firewall został włączony."

msg_info "Konfigurowanie ipset do ochrony przed skanowaniem portów..."
sudo ipset destroy port_scanners &>/dev/null
sudo ipset destroy scanned_ports &>/dev/null
sudo ipset create port_scanners hash:ip family inet hashsize 32768 maxelem 65536 timeout 600
sudo ipset create scanned_ports hash:ip,port family inet hashsize 32768 maxelem 65536 timeout 60

if ! sudo iptables -C INPUT -m state --state INVALID -j DROP &>/dev/null; then
    sudo iptables -A INPUT -m state --state INVALID -j DROP
    sudo iptables -A INPUT -m state --state NEW -m set ! --match-set scanned_ports src,dst -m hashlimit --hashlimit-above 1/hour --hashlimit-burst 5 --hashlimit-mode srcip --hashlimit-name portscan --hashlimit-htable-expire 10000 -j SET --add-set port_scanners src --exist
    sudo iptables -A INPUT -m state --state NEW -m set --match-set port_scanners src -j DROP
    sudo iptables -A INPUT -m state --state NEW -j SET --add-set scanned_ports src,dst
    msg_ok "Dodano reguły iptables do ochrony przed skanowaniem."
else
    echo "ℹ️  Reguły iptables do ochrony przed skanowaniem już istnieją."
fi

msg_info "Konfiguracja firewalla zakończona."
