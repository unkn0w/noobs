#!/bin/bash
# Jenkins na mikrusowym porcie
# Autor: Maciej Loper, Radoslaw Karasinski

status() {
    echo "[x] $1"
}
JENKINS_PORT = 80
status "instalacja wymaganych pakietow"
sudo apt install -y gnupg
echo

status "dodawanie repozytorium Jenkinsa"
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

status "aktualizacja repozytoriow"
sudo apt update
echo

status "instalacja Jenkinsa i Javy JRE11"
sudo apt install -y openjdk-11-jre-headless
sudo apt install -y jenkins
echo

status "poprawki w konfiguracji"
sudo systemctl stop jenkins
sed -i 's|User=jenkins|User=root|' /lib/systemd/system/jenkins.service
sed -i 's|JENKINS_PORT=8080|JENKINS_PORT=${JENKINS_PORT}|' /lib/systemd/system/jenkins.service
sudo systemctl daemon-reload
echo

status "uruchomienie"
sudo systemctl start jenkins
echo

echo -n "Gotowe. Jenkins nasłuchuje na porcie 80. Haslo poczatkowe: "
cat /var/lib/jenkins/secrets/initialAdminPassword

