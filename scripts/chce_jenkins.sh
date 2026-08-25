#!/bin/bash
# Jenkins na mikrusowym porcie
# Autor: Maciej Loper, Radoslaw Karasinski, pablowyourmind

status() {
    echo "[x] $1"
}

id="$(hostname)"; id="${id##*[!0-9]}"
read -p "Podaj port, na którym ma działać Jenkins. Brak podania numeru spowoduje ustawienie przydzielonego przez Mikrusa portu 30${id}:" port
port=${port:-30${id}}
status "Jenkins będzie nasłuchiwał na porcie $port"

status "instalacja wymaganych pakietow"
sudo apt install -y gnupg
echo

status "dodawanie repozytorium Jenkinsa"
# Klucz GPG Jenkinsa jest rotowany (nazwa pliku zawiera rok) - jesli sztywno wpisany rok
# jest przestarzały, apt update kończy się NO_PUBKEY i Jenkins nigdy się nie instaluje.
jenkins_key_url=$(curl -s https://pkg.jenkins.io/debian-stable/ | grep -oE 'jenkins\.io-[0-9]{4}\.key' | sort -u | tail -n1)
jenkins_key_url="https://pkg.jenkins.io/debian-stable/${jenkins_key_url:-jenkins.io-2023.key}"
wget -q -O - "$jenkins_key_url" | sudo gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg || { echo "Pobranie klucza GPG Jenkinsa nie powiodło się ($jenkins_key_url)."; exit 1; }
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] http://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list

status "aktualizacja repozytoriow"
if ! sudo apt update; then
    echo "apt update nie powiodło się - sprawdź czy klucz GPG Jenkinsa ($jenkins_key_url) jest aktualny." >&2
    exit 1
fi
echo

status "instalacja Jenkinsa i Javy JRE17"
sudo apt install -y openjdk-17-jre-headless || { echo "Instalacja Java 17 nie powiodła się."; exit 1; }
sudo apt install -y jenkins || { echo "Instalacja Jenkinsa nie powiodła się."; exit 1; }
echo

status "poprawki w konfiguracji"
sudo systemctl stop jenkins
sudo sed -i 's|User=jenkins|User=root|' /lib/systemd/system/jenkins.service
sudo sed -i "s|JENKINS_PORT=8080|JENKINS_PORT=$port|" /lib/systemd/system/jenkins.service
sudo sed -i 's|JAVA_OPTS=-Djava.awt.headless=true|JAVA_OPTS=-Djava.awt.headless=true -Xms256m -Xmx512m|' /lib/systemd/system/jenkins.service
sudo systemctl daemon-reload
echo

status "uruchomienie"
sudo systemctl start jenkins
echo

echo -n "Gotowe. Jenkins nasłuchuje na porcie $port. Hasło początkowe: "
sudo cat /var/lib/jenkins/secrets/initialAdminPassword