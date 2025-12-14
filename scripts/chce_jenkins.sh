#!/bin/bash
# Jenkins na mikrusowym porcie
# Autor: Maciej Loper, Radoslaw Karasinski, pablowyourmind
# Refactored: noobs community (v2.0.0)

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

msg_info "Sprawdzenie uprawnien"
require_root

# Pobranie portu od uzytkownika
read -p "Podaj port dla Jenkins (domyslnie 80): " port
port=${port:-80}
msg_info "Jenkins bedzie nasluchiwac na porcie $port"

msg_info "Instalacja wymaganych pakietow"
pkg_install gnupg

msg_info "Dodawanie repozytorium Jenkins"
add_repository_with_key \
    "http://pkg.jenkins.io/debian-stable binary/" \
    "jenkins.list" \
    "https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key"

msg_info "Instalacja Java JRE17 i Jenkins"
pkg_update
pkg_install openjdk-17-jre-headless jenkins

msg_info "Konfiguracja Jenkins"
service_stop jenkins

# Modyfikacja konfiguracji
backup_file /lib/systemd/system/jenkins.service
sed -i 's|User=jenkins|User=root|' /lib/systemd/system/jenkins.service
sed -i "s|JENKINS_PORT=8080|JENKINS_PORT=$port|" /lib/systemd/system/jenkins.service
sed -i 's|JAVA_OPTS=-Djava.awt.headless=true|JAVA_OPTS=-Djava.awt.headless=true -Xms256m -Xmx512m|' /lib/systemd/system/jenkins.service

systemctl daemon-reload

msg_info "Uruchamianie Jenkins"
service_start jenkins

msg_ok "Jenkins zainstalowany pomyslnie!"
msg_info "Port: $port"

if [[ -f /var/lib/jenkins/secrets/initialAdminPassword ]]; then
    msg_info "Haslo poczatkowe: $(cat /var/lib/jenkins/secrets/initialAdminPassword)"
fi
