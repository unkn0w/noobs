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
    for software in "$@";
    do
      echo "Rozpoczecie instalacji pakietu - sprawdzam czy jest na liście, jezeli go niema zostanie ziosnatlowany pakiet: ${software}"
      dpkg -s ${software} &> /dev/null

	    if [ $? -eq 0 ]; then
    	  echo "${currentDate} ${currentTime}  |  Pakiet ${software} jest już zainstalowany!" |& tee -a ${log}
	    else
    	  echo "${currentDate} ${currentTime}  |  Pakiet ${software} nie jest zainstalowany, przystępuje do instalacji!" |& tee -a ${log}
		    sudo apt-get install -y ${software} |& tee -a ${log}
        if [ $? -eq 0 ]; then
          echo "${currentDate} ${currentTime}  |  Pakiet ${software} zinstalowany" |& tee -a ${log}
        else
          echo "${currentDate} ${currentTime}  |  Pakiet ${software} niezinstalowany sprawdz log: ${log}" |& tee -a ${log}
        fi
	    fi
    done
}

function apt_update() {
  echo "${currentTime}  |  Aktualizacja listy pakietów!" |& tee -a ${log}
  apt update |& tee -a ${log}
  if [ $? -eq 0 ]; then
    echo "${currentDate} ${currentTime}  |  Aktualizacja listy pakietów wykonana prawidłowo" |& tee -a ${log}
  else
    echo "${currentDate} ${currentTime}  |  Aktualizacja listy pakietów nie powiodła się sprawdz logi: ${log}" |& tee -a ${log}
  fi
}

function apt_add_repository() {
  for repository in "$@";
    do
		  add-apt-repository --yes --update ${repository} |& tee -a ${log}
      if [ $? -eq 0 ]; then
        echo "${currentDate} ${currentTime}  |  Pakiet zinstalowany" |& tee -a ${log}
      else
        echo "${currentDate} ${currentTime}  |  Pakiet niezinstalowany sprawdz log: ${log}" |& tee -a ${log}
      fi
    done
}

[[ $_ != $0 ]] && echo "" || echo "To jest funkcja możesz ja dołaczyć w swoim skrypcie po przez: . $0"