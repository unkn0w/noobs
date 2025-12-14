#!/bin/bash

###############################################
# Stirling-PDF Installer
# Autor: Patriocoz
#
# Ten skrypt instaluje i konfiguruje aplikację Stirling-PDF na systemach Linux.
# Zapewnia on automatyczne pobieranie najnowszej wersji aplikacji, budowanie,
# instalację oraz konfigurację usługi systemd.
#
# Wymagania:
# - System operacyjny: Debian, CentOS
# - Wymagane narzędzia: curl, wget, tar, java, systemctl
#   (Skrypt automatycznie wykryje niezbędne pakiety)
# - Dostęp do internetu
# - Uprawnienia roota lub sudo
#
# Instalacja:
# 1. Pobierz skrypt:
#    wget https://raw.githubusercontent.com/patriocoz/noobs/refs/heads/main/scripts/chce_stirlingpdf.sh
# 2. Nadaj prawa wykonywania:
#    chmod +x stirling-pdf-installer.sh
# 3. Uruchom skrypt:
#    sudo ./stirling-pdf-installer.sh
#
# Opcje:
# -i, --install    Instalacja Stirling-PDF
# -u, --update     Aktualizacja Stirling-PDF
# -r, --remove     Usunięcie Stirling-PDF
# -p, --port PORT  Ustaw niestandardowy port
# -h, --help       Wyświetlenie pomocy
#
# Przykładowe użycie:
# sudo ./stirling-pdf-installer.sh -i
# sudo ./stirling-pdf-installer.sh -i -p 8888
# sudo ./stirling-pdf-installer.sh -u
#
# Konfiguracja:
# Po instalacji aplikacja jest domyślnie dostępna pod adresem http://localhost:8080.
# Możesz zmienić port podczas instalacji używając opcji -p.
# Skrypt automatycznie konfiguruje usługę systemd, aby aplikacja była uruchamiana po restarcie systemu.
#
# Rozwiązywanie problemów:
# - Sprawdź dostęp do internetu
# - Upewnij się, że masz uprawnienia administratora
# - Sprawdź wersję Javy (zalecana wersja 8 lub nowsza)
# - Sprawdź status usługi: systemctl status stirlingpdf.service
# - Sprawdź logi systemd: journalctl -u stirlingpdf
# - Sprawdź, czy port nie jest zajęty: netstat -tuln | grep 8080
#
# Aktualizacja:
# sudo ./stirling-pdf-installer.sh -u
#
# Usuwanie:
# sudo ./stirling-pdf-installer.sh -r
###############################################

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

set -e  # Zatrzymaj skrypt przy pierwszym błędzie

APP="Stirling-PDF"
INSTALL_DIR="/opt/Stirling-PDF"
TEMP_DIR="/tmp/stirling-pdf"
SERVICE_FILE="/etc/systemd/system/stirlingpdf.service"
JAVA_VERSION="17"
CUSTOM_PORT=""

REQUIRED_TOOLS=("curl" "wget" "tar" "systemctl")

# Funkcje pomocnicze
header_info() {
  echo -e "\n=== Instalacja/Aktualizacja ${APP} ===\n"
}

# Sprawdzenie uprawnień roota
require_root

# Instalacja pakietu
install_package() {
  if command -v apt &>/dev/null; then
    pkg_update && pkg_install "$1"
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y "$1"
  elif command -v yum &>/dev/null; then
    sudo yum install -y "$1"
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm "$1"
  else
    msg_error "Nie znaleziono obsługiwanego menedżera pakietów."
    return 1
  fi
}

update_package_manager() {
  if command -v apt &>/dev/null; then
    pkg_update
  elif command -v dnf &>/dev/null; then
    sudo dnf check-update
  elif command -v yum &>/dev/null; then
    sudo yum check-update
  elif command -v pacman &>/dev/null; then
    sudo pacman -Sy
  else
    msg_error "Nie znaleziono obsługiwanego menedżera pakietów."
    return 1
  fi
  msg_ok "Menedżer pakietów został zaktualizowany."
}

# Sprawdzenie wersji Java
check_java() {
  if ! command -v java &> /dev/null; then
    return 1
  fi
  local version
  version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
  if [[ $version -lt $JAVA_VERSION ]]; then
    msg_error "Wymagana Java w wersji ${JAVA_VERSION} lub nowszej. Znaleziono wersję: $version"
    return 1
  fi
}

# Instalacja Java
install_java() {
  msg_info "Instalacja Java ${JAVA_VERSION}..."

  if [ -f /etc/redhat-release ]; then
    CENTOS_MAJOR=$(grep -oP '[0-9]+' /etc/redhat-release | head -1)

    if [[ $CENTOS_MAJOR -eq 7 ]]; then
      msg_info "Wykryto CentOS/RHEL 7 - instalacja OpenJDK 17"

      # Dodanie repozytorium
      sudo yum install -y epel-release
      sudo yum install -y https://cdn.azul.com/zulu/bin/zulu-repo-1.0.0-1.noarch.rpm

      # Instalacja OpenJDK 17
      sudo yum install -y zulu17-jdk

      # Ustawienie Java 17 jako domyślnej
      sudo alternatives --set java /usr/lib/jvm/zulu17/bin/java
      sudo alternatives --set javac /usr/lib/jvm/zulu17/bin/javac

      # Ustawienie JAVA_HOME
      echo "export JAVA_HOME=/usr/lib/jvm/zulu17" | sudo tee -a /etc/profile.d/java.sh
      source /etc/profile.d/java.sh

      return 0
    fi
  fi

  # Standardowa instalacja dla innych dystrybucji
  if command -v apt &>/dev/null; then
    pkg_install openjdk-${JAVA_VERSION}-jdk
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y java-${JAVA_VERSION}-openjdk-devel
  elif command -v yum &>/dev/null; then
    sudo yum install -y java-${JAVA_VERSION}-openjdk-devel
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm jdk-openjdk
  else
    msg_error "Nie znaleziono obsługiwanego menedżera pakietów."
    return 1
  fi

  # Aktualizacja alternatyw dla Javy
  if command -v update-alternatives &>/dev/null; then
    sudo update-alternatives --set java /usr/lib/jvm/java-${JAVA_VERSION}-openjdk-*/bin/java
  fi
}

# Sprawdzenie i instalacja wymaganych narzędzi
check_and_install_tools() {
  # Sprawdź Java osobno ze względu na wymaganą wersję
  update_package_manager
  if ! check_java; then
    read -p "Java ${JAVA_VERSION}+ nie jest zainstalowana. Zainstalować teraz? (t/n): " choice
    if [[ $choice == "t" || $choice == "T" ]]; then
      install_java
    else
      msg_error "Java ${JAVA_VERSION}+ jest wymagana. Instalacja przerwana."
      exit 1
    fi
  fi

  # Sprawdź pozostałe narzędzia
  for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v $tool &> /dev/null; then
      msg_info "$tool nie jest zainstalowany."
      read -p "Czy chcesz zainstalować $tool? (t/n): " choice
      if [[ $choice == "t" || $choice == "T" ]]; then
        if ! install_package $tool; then
          msg_error "Błąd podczas instalacji $tool. Sprawdź połączenie internetowe i uprawnienia."
          exit 1
        fi
      else
        msg_error "Narzędzie $tool jest wymagane do działania skryptu. Instalacja przerwana."
        exit 1
      fi
    fi
  done
  msg_ok "Wszystkie wymagane narzędzia są zainstalowane."
}

# Automatyczne sprawdzenie i instalacja narzędzi
check_and_install_tools_auto() {
  update_package_manager
  if ! check_java; then
    install_java
  fi

  for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v $tool &> /dev/null; then
      msg_info "$tool nie jest zainstalowany. Instaluję automatycznie."
      if ! install_package $tool; then
        msg_error "Błąd podczas instalacji $tool. Sprawdź połączenie internetowe i uprawnienia."
        exit 1
      fi
    fi
  done
  msg_ok "Wszystkie wymagane narzędzia są zainstalowane."
}

# Pobieranie i budowanie aplikacji
download_and_build() {
  RELEASE=$(curl -s https://api.github.com/repos/Stirling-Tools/Stirling-PDF/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ -z "$RELEASE" ]]; then
    msg_error "Nie udało się uzyskać informacji o najnowszej wersji."
    exit 1
  fi
  msg_info "Pobieranie wersji ${RELEASE}"

  mkdir -p ${TEMP_DIR}
  wget -q https://github.com/Stirling-Tools/Stirling-PDF/archive/refs/tags/v${RELEASE}.tar.gz -O ${TEMP_DIR}/v${RELEASE}.tar.gz || { msg_error "Nie udało się pobrać archiwum"; exit 1; }
  tar -xzf ${TEMP_DIR}/v${RELEASE}.tar.gz -C ${TEMP_DIR} || { msg_error "Nie udało się rozpakować archiwum"; exit 1; }

  CURRENT_DIR=$(pwd)
  cd ${TEMP_DIR}/Stirling-PDF-${RELEASE} || { msg_error "Nie znaleziono rozpakowanego katalogu"; exit 1; }
  chmod +x ./gradlew
  ./gradlew build -x test || { msg_error "Błąd podczas budowania aplikacji"; exit 1; }
  cd "$CURRENT_DIR"
}

# Instalacja plików aplikacji
install_files() {
  msg_info "Instalacja plików aplikacji"

  mkdir -p ${INSTALL_DIR}
  cp -r ${TEMP_DIR}/Stirling-PDF-${RELEASE}/build/libs/Stirling-PDF-*.jar ${INSTALL_DIR}/
  cp -r ${TEMP_DIR}/Stirling-PDF-${RELEASE}/scripts ${INSTALL_DIR}/

  ln -sf ${INSTALL_DIR}/Stirling-PDF-*.jar ${INSTALL_DIR}/Stirling-PDF.jar
}

# Tworzenie usługi systemd
create_systemd_service() {
  msg_info "Tworzenie usługi systemd"

  useradd -r -s /bin/false stirlingpdf 2>/dev/null || true

  # Najpierw tworzę plik serwisu
  cat <<EOF >${SERVICE_FILE}
[Unit]
Description=Stirling-PDF Service
After=network.target

[Service]
Type=simple
User=stirlingpdf
Group=stirlingpdf
WorkingDirectory=${INSTALL_DIR}
ExecStart=/usr/bin/java -Xmx512m -jar ${INSTALL_DIR}/Stirling-PDF.jar
Restart=always
ProtectSystem=full
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

  # Teraz zmień uprawnienia
  chown -R stirlingpdf:stirlingpdf ${INSTALL_DIR}

  systemctl daemon-reload
  service_enable stirlingpdf
}

# Tworzenie pliku custom_settings.yml
create_custom_settings() {
  if [[ -n "$CUSTOM_PORT" ]]; then
    local config_dir="${INSTALL_DIR}/configs"
    local config_file="${config_dir}/custom_settings.yml"

    mkdir -p "$config_dir"
    echo "server:" > "$config_file"
    echo "  port: $CUSTOM_PORT" >> "$config_file"

    chmod 644 "$config_file"

    msg_info "Utworzono plik custom_settings.yml z portem: $CUSTOM_PORT"
  fi
}

# Konfiguracja firewalla
configure_firewall() {
  local port="${CUSTOM_PORT:-8080}"
  if command -v firewall-cmd &> /dev/null; then
    sudo firewall-cmd --zone=public --add-port=${port}/tcp --permanent
    sudo firewall-cmd --reload
    msg_ok "Port ${port} został otwarty w firewallu (firewalld)."
  elif command -v iptables &> /dev/null; then
    sudo iptables -A INPUT -p tcp --dport ${port} -j ACCEPT
    sudo service iptables save
    sudo service iptables restart
    msg_ok "Port ${port} został otwarty w firewallu (iptables)."
  else
    msg_error "Nie znaleziono obsługiwanego firewalla (firewalld lub iptables)."
  fi
}

# Czyszczenie plików tymczasowych
cleanup_temp_files() {
  msg_info "Czyszczenie plików tymczasowych"

  # Usunięcie repozytorium Zulu jeśli zostało dodane
  if [ -f /etc/yum.repos.d/zulu.repo ]; then
    sudo yum remove -y zulu-repo
    sudo rm -f /etc/yum.repos.d/zulu.repo
    sudo yum clean all
  fi

  rm -rf ${TEMP_DIR}
}

# Kopia zapasowa istniejącej instalacji
backup_existing() {
  if [[ -f ${INSTALL_DIR}/Stirling-PDF.jar ]]; then
    msg_info "Tworzenie kopii zapasowej bieżącej instalacji"
    mkdir -p ${INSTALL_DIR}/backup
    cp ${INSTALL_DIR}/Stirling-PDF.jar ${INSTALL_DIR}/backup/Stirling-PDF.jar.bak
  fi
}

# Instalacja Stirling-PDF
install_stirling_pdf() {
  msg_info "Rozpoczynam instalację ${APP}"

  download_and_build
  install_files
  if [[ -n "$CUSTOM_PORT" ]]; then
    create_custom_settings
  fi
  create_systemd_service
  configure_firewall

  service_start stirlingpdf || { msg_error "Nie udało się uruchomić usługi"; exit 1; }
  service_restart stirlingpdf || { msg_error "Nie udało się uruchomić usługi"; exit 1; }


  cleanup_temp_files
  local port="${CUSTOM_PORT:-8080}"
  msg_ok "Instalacja ${APP} zakończona pomyślnie!"
  msg_info "Aplikacja będzie dostępna pod adresem: http://$(hostname -I | awk '{print $1}'):${port}"
}

# Aktualizacja Stirling-PDF
update_stirling_pdf() {
  msg_info "Sprawdzanie dostępności aktualizacji..."

  if check_for_updates; then
    msg_info "Rozpoczynam aktualizację ${APP}"

    # Sprawdź, czy istnieje custom_settings.yml z portem
    if [[ -z "$CUSTOM_PORT" ]]; then
      local existing_port=$(read_custom_port)
      if [[ -n "$existing_port" ]]; then
        CUSTOM_PORT="$existing_port"
        msg_info "Znaleziono istniejący port konfiguracyjny: $CUSTOM_PORT"
      fi
    else
      msg_info "Zostanie użyty nowy port: $CUSTOM_PORT"
    fi

    service_stop stirlingpdf || { msg_error "Nie udało się zatrzymać usługi"; exit 1; }

    backup_existing
    download_and_build
    install_files
    if [[ -n "$CUSTOM_PORT" ]]; then
      create_custom_settings
    fi
    create_systemd_service
    configure_firewall

    service_start stirlingpdf || { msg_error "Nie udało się uruchomić usługi"; exit 1; }

    cleanup_temp_files
    local port="${CUSTOM_PORT:-8080}"
    msg_ok "Aktualizacja ${APP} zakończona pomyślnie!"
    msg_info "Aplikacja jest dostępna pod adresem: http://$(hostname -I | awk '{print $1}'):${port}"
  else
    msg_ok "Aktualizacja nie jest wymagana."
    return 0
  fi
}

read_custom_port() {
  local config_file="${INSTALL_DIR}/configs/custom_settings.yml"

  if [[ -f "$config_file" ]]; then
    local port=$(grep -oP "port: \K[0-9]+" "$config_file")
    if [[ -n "$port" ]]; then
      echo "$port"
      return 0
    fi
  fi

  return 1
}

get_installed_version() {
  # Próba odczytu wersji z nazwy pliku JAR
  if [[ -L "${INSTALL_DIR}/Stirling-PDF.jar" ]]; then
    local jar_path=$(readlink -f "${INSTALL_DIR}/Stirling-PDF.jar")
    local version=$(echo "$jar_path" | grep -oP "Stirling-PDF-\K[0-9]+\.[0-9]+\.[0-9]+" || echo "")

    if [[ -n "$version" ]]; then
      echo "$version"
      return 0
    fi
  fi

  # Próba odczytu wersji bezpośrednio z aplikacji JAR
  if [[ -f "${INSTALL_DIR}/Stirling-PDF.jar" ]]; then
    local version=$(java -jar "${INSTALL_DIR}/Stirling-PDF.jar" --version 2>/dev/null)

    if [[ -n "$version" && "$version" != *"Error"* ]]; then
      echo "$version" | grep -oP "[0-9]+\.[0-9]+\.[0-9]+" || echo "0.0.0"
      return 0
    fi
  fi

  # Próba użycia systemctl do sprawdzenia wersji
  if systemctl is-active --quiet stirlingpdf.service; then
    local version=$(curl -s "http://localhost:${CUSTOM_PORT:-8080}/version" 2>/dev/null | grep -oP '"version":\s*"\K[^"]+' || echo "")

    if [[ -n "$version" ]]; then
      echo "$version"
      return 0
    fi
  fi

  # Jeśli nie udało się odczytać wersji żadną z metod
  echo "0.0.0"
}


get_latest_version() {
  # Pobierz najnowszą wersję z API GitHuba
  curl -s "https://api.github.com/repos/Stirling-Tools/Stirling-PDF/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//'
}

check_for_updates() {
  local installed_version=$(get_installed_version)
  local latest_version=$(get_latest_version)

  if [[ "$installed_version" != "$latest_version" ]]; then
    msg_info "Dostępna jest nowa wersja: $latest_version (zainstalowana: $installed_version)"
    return 0
  else
    msg_info "Zainstalowana jest najnowsza wersja: $installed_version"
    return 1
  fi
}



# Usuwanie Stirling-PDF
remove_stirling_pdf() {
  msg_info "Usuwanie ${APP}"

  service_stop stirlingpdf 2>/dev/null || true
  systemctl disable stirlingpdf.service 2>/dev/null || true

  rm -f ${SERVICE_FILE}
  systemctl daemon-reload

  if [[ "$AUTO_ACCEPT" == true ]]; then
    rm -rf ${INSTALL_DIR}
    msg_ok "Aplikacja ${APP} została całkowicie usunięta."
  else
    read -p "Czy chcesz usunąć wszystkie pliki aplikacji? (t/n): " choice
    if [[ $choice == "t" || $choice == "T" ]]; then
      rm -rf ${INSTALL_DIR}
      msg_ok "Aplikacja ${APP} została całkowicie usunięta."
    else
      msg_info "Pliki aplikacji pozostały w ${INSTALL_DIR}"
    fi
  fi
}
restart_application() {
  msg_info "Uruchamianie aplikacji ${APP}"
  service_restart stirlingpdf || { msg_error "Nie udało się zrestartować usługi"; exit 1; }
  msg_ok "Aplikacja ${APP} została pomyślnie Uruchomiona"
}


# Wyświetlanie pomocy
show_help() {
  echo "Użycie: $0 [opcje]"
  echo "Opcje:"
  echo "  -i, --install    Instalacja Stirling-PDF"
  echo "  -u, --update     Aktualizacja Stirling-PDF"
  echo "  -r, --remove     Usunięcie Stirling-PDF"
  echo "  -p, --port PORT  Ustaw niestandardowy port"
  echo "  -h, --help       Wyświetl tę pomoc"
  exit 0
}

# Główna logika skryptu
main() {
  header_info

  AUTO_ACCEPT=false

  if [[ $# -eq 0 ]]; then
    show_help
    exit 0
  fi

  while [[ "$#" -gt 0 ]]; do
    case $1 in
      -i|--install)
        INSTALL=true
        if [[ "$2" == "y" ]]; then
          AUTO_ACCEPT=true
          shift
        fi
        ;;
      -u|--update)
        UPDATE=true
        if [[ "$2" == "y" ]]; then
          AUTO_ACCEPT=true
          shift
        fi
        ;;
      -r|--remove)
        REMOVE=true
        if [[ "$2" == "y" ]]; then
          AUTO_ACCEPT=true
          shift
        fi
        ;;
      -p|--port)
        CUSTOM_PORT="$2"
        shift
        ;;
      -h|--help) show_help ;;
      *) msg_error "Nieznana opcja: $1"; show_help ;;
    esac
    shift
  done

  if [[ "$REMOVE" == true ]]; then
    remove_stirling_pdf
  elif [[ "$INSTALL" == true ]] || [[ "$UPDATE" == true ]]; then
    if [[ "$AUTO_ACCEPT" == true ]]; then
      check_and_install_tools_auto
    else
      check_and_install_tools
    fi
    if [[ "$UPDATE" == true ]]; then
      update_stirling_pdf
    else
      install_stirling_pdf
    fi
    restart_application
  else
    show_help
  fi
}


# Uruchomienie skryptu
main "$@"
