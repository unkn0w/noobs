#!/bin/bash
# Author: Piotr Koska

# Zmienne
currentDate=$(date +"%F") # Data Date
currentTime=$(date +"%T") # Czas Time
log="/var/log/noobs-${currentDate}.log"

# Funkcje
function apt_install_software () {
    # [PL] Funkcja ta sprawdza czy jest zainstalowany pakiet. W przypadku braku pakiety przystepuje do instalacji.
	  # [ENG] This function checks if the package is installed. In the absence of packages, it is included in the installation.
    
    # Pętla do instalacji wskazanych pakietów / nazwa - używamy apt_install_software <nazwa_pakietu> <druga_nazwa_pakietu> [...]
    for software in "$@";
    do
      # Sprawdzamy czy pakiet już nie jest zainstalowany - nie wykonany update jeżeli już mamy.
      echo "${currentDate} ${currentTime}  |  Rozpoczecie instalacji pakietu - sprawdzam czy jest na liście, jezeli go niema zostanie ziosnatlowany pakiet: ${software}"
      dpkg -s ${software} &> /dev/null
       
	    if [ $? -eq 0 ]; then
    	  echo "${currentDate} ${currentTime}  |  Pakiet ${software} jest już zainstalowany!" |& tee -a ${log}
	    else
        # Brak pakietu instaluje.
    	  echo "${currentDate} ${currentTime}  |  Pakiet ${software} nie jest zainstalowany, przystępuje do instalacji!" |& tee -a ${log}
		    apt-get install -y ${software} |& tee -a ${log}
        if [ $? -eq 0 ]; then
          echo "${currentDate} ${currentTime}  |  Pakiet ${software} zinstalowany." |& tee -a ${log}
        else
          echo "${currentDate} ${currentTime}  |  Pakiet ${software} niezinstalowany sprawdz log: ${log}" |& tee -a ${log}
        fi
	    fi
    done
}

function apt_update() {
  # Logowanie aktualizacji pakietów.
  echo "${currentDate} ${currentTime}  |  Aktualizacja listy pakietów!" |& tee -a ${log}
  apt-get update |& tee -a ${log}
  if [ $? -eq 0 ]; then
    echo "${currentDate} ${currentTime}  |  Aktualizacja listy pakietów wykonana prawidłowo." |& tee -a ${log}
  else
    echo "${currentDate} ${currentTime}  |  Aktualizacja listy pakietów nie powiodła się sprawdz logi: ${log}" |& tee -a ${log}
  fi
}

function apt_add_repository() {
  for repository in "$@";
    do
      # Dodawanie dodatkowych repozytoroiów - nazwy podawać w "<nazwa>" i oddzielone spacją jezeli chcemy kilka.
      echo "${currentDate} ${currentTime}  |  Dodanie repozytorium ${repository}"
		  add-apt-repository --yes --update ${repository} |& tee -a ${log}
      if [ $? -eq 0 ]; then
        echo "${currentDate} ${currentTime}  |  Repozytorium ${repository} dodane." |& tee -a ${log}
      else
        echo "${currentDate} ${currentTime}  |  Repozytorium ${repository} nie dodane, sprawdz log: ${log}" |& tee -a ${log}
      fi
    done
}

[[ $_ != $0 ]] && echo "" || echo "To jest funkcja możesz ja dołaczyć w swoim skrypcie po przez: . $0"