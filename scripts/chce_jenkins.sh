#!/bin/bash
# Jenkins na mikrusowym porcie
# Autor: Maciej Loper, Radoslaw Karasinski

status() {
    echo "[x] $1"
}

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
sudo sed -i 's|JENKINS_USER=$NAME|JENKINS_USER=root|' /etc/default/jenkins
sudo sed -i 's|HTTP_PORT=8080|HTTP_PORT=80|' /etc/default/jenkins
echo

status "uruchomienie"
sudo systemctl start jenkins
echo

echo "Gotowe. Jenkins nasłuchuje na porcie 80. Haslo poczatkowe: "
cat /var/lib/jenkins/secrets/initialAdminPassword