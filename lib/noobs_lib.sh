#!/bin/bash
# =============================================================================
# noobs_lib.sh - Wspolna biblioteka dla projektu noobs
# =============================================================================
# Autor: noobs community
# Wersja: 1.0.0
# Licencja: MIT
#
# Uzycie:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1
# =============================================================================

# Zapobiegaj wielokrotnemu ladowaniu
[[ -n "${_NOOBS_LIB_LOADED:-}" ]] && return 0
readonly _NOOBS_LIB_LOADED=1

# Wersja biblioteki
readonly NOOBS_LIB_VERSION="2.0.0"

# =============================================================================
# SEKCJA 1: Kolory i komunikaty
# =============================================================================

# Kolory ANSI
readonly _C_RESET='\e[0m'
readonly _C_RED='\e[31m'
readonly _C_GREEN='\e[32m'
readonly _C_YELLOW='\e[33m'
readonly _C_BLUE='\e[34m'
readonly _C_BOLD='\e[1m'

# Inicjalizacja zmiennych kolorow (eksport dla zaawansowanych skryptow)
noobs_colors_init() {
    export NOOBS_C_RESET="${_C_RESET}"
    export NOOBS_C_RED="${_C_RED}"
    export NOOBS_C_GREEN="${_C_GREEN}"
    export NOOBS_C_YELLOW="${_C_YELLOW}"
    export NOOBS_C_BLUE="${_C_BLUE}"
    export NOOBS_C_BOLD="${_C_BOLD}"
}

# Format: [INFO] tekst (niebieski)
msg_info() {
    echo -e "${_C_BLUE}[INFO]${_C_RESET} $1"
}

# Format: [OK] tekst (zielony)
msg_ok() {
    echo -e "${_C_GREEN}[OK]${_C_RESET} $1"
}

# Format: [ERR] tekst (czerwony, do stderr)
msg_error() {
    echo -e "${_C_RED}[ERR]${_C_RESET} $1" >&2
}

# Format: [WARN] tekst (zolty)
msg_warn() {
    echo -e "${_C_YELLOW}[WARN]${_C_RESET} $1"
}

# Format: [x] tekst (zielony, styl z chce_zerotier.sh)
msg_status() {
    echo -e "${_C_GREEN}[x] ${_C_BOLD}${_C_GREEN}$1${_C_RESET}"
}

# Debug - tylko gdy DEBUG=1
msg_debug() {
    [[ "${DEBUG:-0}" == "1" ]] && echo -e "${_C_YELLOW}[DEBUG]${_C_RESET} $1"
}

# Naglowek sekcji
header_info() {
    local app_name="${1:-Skrypt}"
    echo -e "\n=== $app_name ===\n"
}

# Linia rozdzielajaca
print_separator() {
    local char="${1:--}"
    local width="${2:-60}"
    printf '%*s\n' "$width" '' | tr ' ' "$char"
}

# =============================================================================
# SEKCJA 2: Sprawdzanie uprawnien
# =============================================================================

# Sprawdza czy root (bez wyjscia)
check_root() {
    [[ $EUID -eq 0 ]]
}

# Wymaga roota - konczy skrypt jesli nie
require_root() {
    if [[ $EUID -ne 0 ]]; then
        msg_error "Ten skrypt wymaga uprawnien administratora."
        msg_error "Uruchom jako root lub uzyj: sudo $0"
        exit 1
    fi
}

# Wymaga NIE-roota
require_non_root() {
    if [[ $EUID -eq 0 ]]; then
        msg_error "Uruchamianie jako root jest niebezpieczne. Uzyj zwyklego uzytkownika."
        exit 1
    fi
}

# Sprawdza uprawnienia sudo
require_sudo() {
    if ! sudo --validate 2>/dev/null; then
        msg_error "Nie masz uprawnien do uruchamiania komend jako root."
        msg_error "Dodaj '$USER' do grupy 'sudoers'."
        exit 1
    fi
}

# =============================================================================
# SEKCJA 3: Menedzer pakietow
# =============================================================================

# Zmienna globalna przechowujaca wykryty menedzer
_NOOBS_PKG_MANAGER=""

# Wykrywa menedzer pakietow
detect_package_manager() {
    if [[ -n "$_NOOBS_PKG_MANAGER" ]]; then
        echo "$_NOOBS_PKG_MANAGER"
        return 0
    fi

    if command -v apt &>/dev/null; then
        _NOOBS_PKG_MANAGER="apt"
    elif command -v dnf &>/dev/null; then
        _NOOBS_PKG_MANAGER="dnf"
    elif command -v yum &>/dev/null; then
        _NOOBS_PKG_MANAGER="yum"
    elif command -v pacman &>/dev/null; then
        _NOOBS_PKG_MANAGER="pacman"
    else
        msg_error "Nie znaleziono obslugiwanego menedzera pakietow."
        return 1
    fi

    echo "$_NOOBS_PKG_MANAGER"
}

# Aktualizuje liste pakietow
pkg_update() {
    local pm
    pm=$(detect_package_manager) || return 1

    msg_info "Aktualizowanie listy pakietow..."
    case "$pm" in
        apt)    sudo apt update ;;
        dnf)    sudo dnf check-update || true ;;
        yum)    sudo yum check-update || true ;;
        pacman) sudo pacman -Sy ;;
    esac
    msg_ok "Lista pakietow zaktualizowana."
}

# Instaluje pakiety
pkg_install() {
    local pm
    pm=$(detect_package_manager) || return 1

    [[ $# -eq 0 ]] && { msg_error "Nie podano pakietow do instalacji."; return 1; }

    msg_info "Instalowanie pakietow: $*"
    case "$pm" in
        apt)    sudo apt install -y "$@" ;;
        dnf)    sudo dnf install -y "$@" ;;
        yum)    sudo yum install -y "$@" ;;
        pacman) sudo pacman -S --noconfirm "$@" ;;
    esac
}

# Usuwa pakiet
pkg_remove() {
    local pm
    pm=$(detect_package_manager) || return 1

    [[ -z "$1" ]] && { msg_error "Nie podano pakietu do usuniecia."; return 1; }

    msg_info "Usuwanie pakietu: $1"
    case "$pm" in
        apt)    sudo apt remove -y "$1" ;;
        dnf)    sudo dnf remove -y "$1" ;;
        yum)    sudo yum remove -y "$1" ;;
        pacman) sudo pacman -R --noconfirm "$1" ;;
    esac
}

# Sprawdza czy pakiet jest zainstalowany
pkg_is_installed() {
    local pm
    pm=$(detect_package_manager) || return 1

    case "$pm" in
        apt)    dpkg -s "$1" &>/dev/null ;;
        dnf|yum) rpm -q "$1" &>/dev/null ;;
        pacman) pacman -Q "$1" &>/dev/null ;;
    esac
}

# Instaluje pakiet jesli brakuje
pkg_install_if_missing() {
    local pkg="$1"
    if ! pkg_is_installed "$pkg"; then
        msg_info "Pakiet '$pkg' nie jest zainstalowany. Instaluje..."
        pkg_install "$pkg"
    else
        msg_debug "Pakiet '$pkg' jest juz zainstalowany."
    fi
}

# =============================================================================
# SEKCJA 3.5: Zarzadzanie repozytoriami
# =============================================================================

# Importuje klucz GPG z URL
# Uzycie: import_gpg_key <key_url> [keyring_name]
# Przyklad: import_gpg_key "https://www.mongodb.org/static/pgp/server-5.0.asc" "mongodb"
import_gpg_key() {
    local key_url="$1"
    local keyring_name="${2:-$(basename "$key_url" .asc | tr '.' '-')}"
    local keyring_path="/usr/share/keyrings/${keyring_name}.gpg"

    [[ -z "$key_url" ]] && { msg_error "Nie podano URL klucza GPG."; return 1; }

    msg_info "Importowanie klucza GPG: $key_url"

    # Upewnij sie ze gnupg jest zainstalowany
    if ! command_exists gpg; then
        pkg_install gnupg
    fi

    # Pobierz i zaimportuj klucz
    if wget -qO - "$key_url" | gpg --dearmor -o "$keyring_path" 2>/dev/null; then
        chmod 644 "$keyring_path"
        msg_ok "Klucz GPG zaimportowany: $keyring_path"
        echo "$keyring_path"
        return 0
    else
        msg_error "Nie udalo sie zaimportowac klucza GPG."
        return 1
    fi
}

# Dodaje repozytorium PPA (Ubuntu)
# Uzycie: add_ppa_repo <ppa_name>
# Przyklad: add_ppa_repo "ondrej/php"
add_ppa_repo() {
    local ppa="$1"

    [[ -z "$ppa" ]] && { msg_error "Nie podano nazwy PPA."; return 1; }

    # Sprawdz czy to Ubuntu
    if ! grep -qi ubuntu /etc/os-release 2>/dev/null; then
        msg_warn "PPA sa obslugiwane tylko na Ubuntu. Pomijam: $ppa"
        return 1
    fi

    # Sprawdz czy software-properties-common jest zainstalowany
    if ! command_exists add-apt-repository; then
        msg_info "Instalowanie software-properties-common..."
        pkg_install software-properties-common
    fi

    msg_info "Dodawanie PPA: $ppa"

    # Normalizuj format PPA
    if [[ "$ppa" != ppa:* ]]; then
        ppa="ppa:$ppa"
    fi

    if add-apt-repository -y "$ppa" >/dev/null 2>&1; then
        msg_ok "PPA dodane: $ppa"
        return 0
    else
        msg_error "Nie udalo sie dodac PPA: $ppa"
        return 1
    fi
}

# Dodaje repozytorium zewnetrzne z kluczem GPG
# Uzycie: add_repository_with_key <repo_line> <list_file> <key_url> [arch]
# Przyklad: add_repository_with_key \
#   "https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" \
#   "mongodb-org-5.0" \
#   "https://www.mongodb.org/static/pgp/server-5.0.asc"
add_repository_with_key() {
    local repo_line="$1"
    local list_file="$2"
    local key_url="$3"
    local arch="${4:-amd64}"

    [[ -z "$repo_line" ]] && { msg_error "Nie podano linii repozytorium."; return 1; }
    [[ -z "$list_file" ]] && { msg_error "Nie podano nazwy pliku list."; return 1; }
    [[ -z "$key_url" ]] && { msg_error "Nie podano URL klucza."; return 1; }

    # Usun rozszerzenie .list jesli podane
    list_file="${list_file%.list}"

    local keyring_path
    keyring_path=$(import_gpg_key "$key_url" "$list_file") || return 1

    local list_path="/etc/apt/sources.list.d/${list_file}.list"

    msg_info "Dodawanie repozytorium: $list_file"

    # Utworz plik sources.list
    echo "deb [arch=${arch} signed-by=${keyring_path}] ${repo_line}" > "$list_path"

    if [[ -f "$list_path" ]]; then
        msg_ok "Repozytorium dodane: $list_path"
        pkg_update
        return 0
    else
        msg_error "Nie udalo sie utworzyc pliku repozytorium."
        return 1
    fi
}

# Usuwa repozytorium
# Uzycie: remove_repository <list_file>
remove_repository() {
    local list_file="$1"
    list_file="${list_file%.list}"

    local list_path="/etc/apt/sources.list.d/${list_file}.list"
    local keyring_path="/usr/share/keyrings/${list_file}.gpg"

    if [[ -f "$list_path" ]]; then
        rm -f "$list_path"
        msg_ok "Usunieto repozytorium: $list_path"
    fi

    if [[ -f "$keyring_path" ]]; then
        rm -f "$keyring_path"
        msg_ok "Usunieto klucz: $keyring_path"
    fi
}

# =============================================================================
# SEKCJA 4: Zarzadzanie uslugami
# =============================================================================

# Sprawdza czy usluga istnieje
service_exists() {
    local service="$1"
    [[ $(systemctl list-units --all -t service --full --no-legend "$service.service" | \
         sed 's/^\s*//g' | cut -f1 -d' ') == "$service.service" ]]
}

# Sprawdza czy usluga dziala
service_is_active() {
    systemctl is-active --quiet "$1"
}

# Uruchamia usluge
service_start() {
    msg_info "Uruchamianie uslugi: $1"
    if systemctl start "$1"; then
        msg_ok "Usluga '$1' uruchomiona."
    else
        msg_error "Nie udalo sie uruchomic uslugi '$1'."
        return 1
    fi
}

# Zatrzymuje usluge
service_stop() {
    msg_info "Zatrzymywanie uslugi: $1"
    if systemctl stop "$1" 2>/dev/null; then
        msg_ok "Usluga '$1' zatrzymana."
    else
        msg_warn "Usluga '$1' nie byla uruchomiona lub wystapil blad."
    fi
}

# Restartuje usluge
service_restart() {
    msg_info "Restartowanie uslugi: $1"
    if systemctl restart "$1"; then
        msg_ok "Usluga '$1' zrestartowana."
    else
        msg_error "Nie udalo sie zrestartowac uslugi '$1'."
        return 1
    fi
}

# Dodaje usluge do autostartu
service_enable() {
    msg_info "Dodawanie uslugi '$1' do autostartu..."
    systemctl enable "$1"
}

# Uruchamia i dodaje do autostartu
service_enable_now() {
    msg_info "Uruchamianie i dodawanie do autostartu: $1"
    systemctl enable --now "$1"
}

# Sprawdza czy usluga jest wlaczona w autostarcie
service_is_enabled() {
    systemctl is-enabled --quiet "$1" 2>/dev/null
}

# Zwraca status uslugi
service_status() {
    local service="$1"
    if service_exists "$service"; then
        systemctl status "$service" --no-pager
    else
        msg_error "Usluga '$service' nie istnieje."
        return 1
    fi
}

# Przeladowuje konfiguracje uslugi bez restartu
service_reload() {
    local service="$1"
    msg_info "Przeladowywanie konfiguracji uslugi: $service"
    if systemctl reload "$service" 2>/dev/null; then
        msg_ok "Konfiguracja uslugi '$service' przeladowana."
    else
        msg_warn "Usluga '$service' nie wspiera reload. Restartowanie..."
        service_restart "$service"
    fi
}

# Wylacza usluge z autostartu
service_disable() {
    msg_info "Wylaczanie uslugi '$1' z autostartu..."
    systemctl disable "$1"
}

# Zatrzymuje i wylacza z autostartu
service_disable_now() {
    msg_info "Zatrzymywanie i wylaczanie z autostartu: $1"
    systemctl disable --now "$1"
}

# =============================================================================
# SEKCJA 5: Interakcja z uzytkownikiem
# =============================================================================

# Prosi o tekst z opcjonalna wartoscia domyslna
ask_input() {
    local text="$1"
    local default="$2"

    if [[ -n "$default" ]]; then
        text="$text [domyslnie: $default]"
    fi

    echo -e -n "$text: ${_C_YELLOW}"
    read -r REPLY
    echo -e -n "${_C_RESET}"

    REPLY="${REPLY:-$default}"
}

# Pytanie tak/nie
ask_yes_no() {
    local question="$1"
    local default="${2:-n}"
    local prompt

    if [[ "$default" == "t" ]]; then
        prompt="[T/n]"
    else
        prompt="[t/N]"
    fi

    echo -e -n "$question $prompt: ${_C_YELLOW}"
    read -r REPLY
    echo -e -n "${_C_RESET}"

    REPLY="${REPLY:-$default}"
    [[ "$REPLY" =~ ^[tTyY]$ ]]
}

# Prosi o haslo (ukryte znaki)
ask_password() {
    local prompt="${1:-Podaj haslo}"
    echo -e -n "$prompt: "
    read -rs REPLY
    echo
}

# Prosi o haslo z potwierdzeniem
ask_password_confirm() {
    local password password_repeat

    while true; do
        echo -n "Podaj haslo (zostaw puste aby wygenerowac): "
        read -rs password
        echo

        if [[ -z "$password" ]]; then
            REPLY=$(generate_password 12)
            msg_info "Wygenerowane haslo: $REPLY"
            return 0
        fi

        echo -n "Powtorz haslo: "
        read -rs password_repeat
        echo

        if [[ "$password" == "$password_repeat" ]]; then
            REPLY="$password"
            return 0
        else
            msg_error "Hasla sie nie zgadzaja, sprobuj ponownie!"
        fi
    done
}

# Wybor z listy opcji
ask_choice() {
    local question="$1"
    shift
    local options=("$@")
    local i=1

    echo "$question"
    for opt in "${options[@]}"; do
        echo "  $i) $opt"
        ((i++))
    done

    echo -e -n "Wybierz [1-${#options[@]}]: ${_C_YELLOW}"
    read -r REPLY
    echo -e -n "${_C_RESET}"

    if [[ "$REPLY" =~ ^[0-9]+$ ]] && [[ "$REPLY" -ge 1 ]] && [[ "$REPLY" -le ${#options[@]} ]]; then
        REPLY="${options[$((REPLY-1))]}"
        return 0
    else
        msg_error "Nieprawidlowy wybor."
        return 1
    fi
}

# =============================================================================
# SEKCJA 6: Walidacja i sprawdzanie
# =============================================================================

# Sprawdza czy polecenie istnieje
command_exists() {
    command -v "$1" &>/dev/null
}

# Sprawdza czy plik istnieje
file_exists() {
    [[ -f "$1" ]]
}

# Sprawdza czy katalog istnieje
dir_exists() {
    [[ -d "$1" ]]
}

# Waliduje numer portu
is_port_valid() {
    local port="$1"
    [[ "$port" =~ ^[0-9]+$ ]] && (( port >= 1 && port <= 65535 ))
}

# Sprawdza czy port jest wolny
is_port_free() {
    local port="$1"
    ! netstat -tuln 2>/dev/null | grep -q ":$port " && \
    ! ss -tuln 2>/dev/null | grep -q ":$port "
}

# Sprawdza polaczenie z internetem
check_internet() {
    if ping -c 1 -W 3 8.8.8.8 &>/dev/null || \
       ping -c 1 -W 3 1.1.1.1 &>/dev/null; then
        return 0
    else
        msg_error "Brak polaczenia z internetem."
        return 1
    fi
}

# Sprawdza czy uzytkownik istnieje
user_exists() {
    id "$1" &>/dev/null
}

# Sprawdza czy grupa istnieje
group_exists() {
    getent group "$1" &>/dev/null
}

# =============================================================================
# SEKCJA 7: Generowanie i narzedzia
# =============================================================================

# Generuje losowe haslo
generate_password() {
    local length="${1:-16}"
    head -c255 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c "$length"
}

# Generuje losowy ciag znakow (male litery i cyfry)
generate_random_string() {
    local length="${1:-8}"
    cat /dev/urandom | tr -dc 'a-z0-9' | head -c "$length"
}

# Zwraca glowny adres IP (alias dla get_local_ip)
get_primary_ip() {
    hostname -I 2>/dev/null | awk '{print $1}'
}

# Zwraca lokalny adres IP
# Uzycie: get_local_ip
get_local_ip() {
    hostname -I 2>/dev/null | awk '{print $1}'
}

# Zwraca publiczny adres IP
# Uzycie: get_public_ip
# Przyklad: PUBLIC_IP=$(get_public_ip)
get_public_ip() {
    # Proba z roznych serwisow (fallback)
    local ip=""

    # Metoda 1: curl ifconfig.me
    if command_exists curl; then
        ip=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null)
        [[ -n "$ip" ]] && { echo "$ip"; return 0; }

        ip=$(curl -s --connect-timeout 5 ipinfo.io/ip 2>/dev/null)
        [[ -n "$ip" ]] && { echo "$ip"; return 0; }
    fi

    # Metoda 2: wget
    if command_exists wget; then
        ip=$(wget -qO- --timeout=5 ifconfig.me 2>/dev/null)
        [[ -n "$ip" ]] && { echo "$ip"; return 0; }
    fi

    # Metoda 3: dig (DNS)
    if command_exists dig; then
        ip=$(dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null)
        [[ -n "$ip" ]] && { echo "$ip"; return 0; }
    fi

    msg_warn "Nie udalo sie pobrac publicznego IP"
    return 1
}

# Zwraca adres IP bramy domyslnej (gateway)
# Uzycie: get_gateway_ip
get_gateway_ip() {
    ip route | awk '/default/ { print $3 }' | head -1
}

# Zwraca IP przez ktore laczymy sie z gatewayem
# Uzycie: get_routed_ip
get_routed_ip() {
    local gateway
    gateway=$(get_gateway_ip)
    [[ -z "$gateway" ]] && { msg_warn "Brak gateway"; return 1; }
    ip route get "$gateway" | grep -oP 'src \K[^ ]+' | head -1
}

# Wyciaga numer z nazwy hosta (mikrus pattern)
get_hostname_number() {
    local hostname
    hostname=$(hostname)
    echo "${hostname##*[!0-9]}"
}

# Tworzy kopie zapasowa pliku
backup_file() {
    local file="$1"
    local backup="${file}.bak.$(date +%Y%m%d_%H%M%S)"

    if [[ -f "$file" ]]; then
        cp "$file" "$backup"
        msg_info "Utworzono kopie zapasowa: $backup"
    fi
}

# Usuwa pliki tymczasowe
cleanup_temp() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        msg_info "Usuwanie plikow tymczasowych: $dir"
        rm -rf "$dir"
    fi
}

# =============================================================================
# SEKCJA 7.5: Operacje na plikach i archiwach
# =============================================================================

# Pobiera plik z URL
# Uzycie: download_file <url> <output_path> [use_curl]
# Przyklad: download_file "https://example.com/file.tar.gz" "/tmp/file.tar.gz"
download_file() {
    local url="$1"
    local output="$2"
    local use_curl="${3:-false}"

    [[ -z "$url" ]] && { msg_error "Nie podano URL do pobrania."; return 1; }
    [[ -z "$output" ]] && { msg_error "Nie podano sciezki wyjsciowej."; return 1; }

    msg_info "Pobieranie: $url"

    # Utworz katalog jesli nie istnieje
    mkdir -p "$(dirname "$output")"

    if [[ "$use_curl" == "true" ]] || ! command_exists wget; then
        if command_exists curl; then
            if curl -fsSL "$url" -o "$output"; then
                msg_ok "Pobrano: $output"
                return 0
            fi
        else
            msg_error "Brak wget ani curl. Zainstaluj jeden z nich."
            return 1
        fi
    else
        if wget -q "$url" -O "$output"; then
            msg_ok "Pobrano: $output"
            return 0
        fi
    fi

    msg_error "Nie udalo sie pobrac pliku: $url"
    return 1
}

# Wykrywa typ archiwum
# Uzycie: detect_archive_type <file_path>
detect_archive_type() {
    local file="$1"
    case "$file" in
        *.tar.gz|*.tgz)   echo "tar.gz" ;;
        *.tar.bz2|*.tbz2) echo "tar.bz2" ;;
        *.tar.xz|*.txz)   echo "tar.xz" ;;
        *.tar)            echo "tar" ;;
        *.zip)            echo "zip" ;;
        *.7z)             echo "7z" ;;
        *)                echo "unknown" ;;
    esac
}

# Rozpakowuje archiwum
# Uzycie: extract_archive <archive_path> <output_dir> [strip_components]
# Przyklad: extract_archive "/tmp/app.tar.gz" "/opt/app" 1
extract_archive() {
    local archive="$1"
    local output_dir="$2"
    local strip="${3:-0}"

    [[ -z "$archive" ]] && { msg_error "Nie podano sciezki archiwum."; return 1; }
    [[ ! -f "$archive" ]] && { msg_error "Plik nie istnieje: $archive"; return 1; }
    [[ -z "$output_dir" ]] && { msg_error "Nie podano katalogu wyjsciowego."; return 1; }

    msg_info "Rozpakowywanie: $archive -> $output_dir"

    # Utworz katalog wyjsciowy
    mkdir -p "$output_dir"

    local archive_type
    archive_type=$(detect_archive_type "$archive")

    case "$archive_type" in
        tar.gz)
            tar -xzf "$archive" -C "$output_dir" --strip-components="$strip"
            ;;
        tar.bz2)
            tar -xjf "$archive" -C "$output_dir" --strip-components="$strip"
            ;;
        tar.xz)
            tar -xJf "$archive" -C "$output_dir" --strip-components="$strip"
            ;;
        tar)
            tar -xf "$archive" -C "$output_dir" --strip-components="$strip"
            ;;
        zip)
            if command_exists unzip; then
                unzip -q "$archive" -d "$output_dir"
            else
                msg_error "Brak programu unzip. Zainstaluj: pkg_install unzip"
                return 1
            fi
            ;;
        7z)
            if command_exists 7z; then
                7z x "$archive" -o"$output_dir" -y >/dev/null
            else
                msg_error "Brak programu 7z. Zainstaluj: pkg_install p7zip-full"
                return 1
            fi
            ;;
        *)
            msg_error "Nieobslugiwany format archiwum: $archive"
            return 1
            ;;
    esac

    if [[ $? -eq 0 ]]; then
        msg_ok "Rozpakowano do: $output_dir"
        return 0
    else
        msg_error "Blad podczas rozpakowywania archiwum."
        return 1
    fi
}

# Pobiera i rozpakowuje archiwum
# Uzycie: download_and_extract <url> <output_dir> [strip_components] [cleanup]
# Przyklad: download_and_extract "https://example.com/app.tar.gz" "/opt/app" 1 true
download_and_extract() {
    local url="$1"
    local output_dir="$2"
    local strip="${3:-0}"
    local cleanup="${4:-true}"

    [[ -z "$url" ]] && { msg_error "Nie podano URL."; return 1; }
    [[ -z "$output_dir" ]] && { msg_error "Nie podano katalogu wyjsciowego."; return 1; }

    # Utworz plik tymczasowy
    local filename
    filename=$(basename "$url" | sed 's/?.*//')
    local temp_file="/tmp/${filename}"

    # Pobierz
    download_file "$url" "$temp_file" || return 1

    # Rozpakuj
    extract_archive "$temp_file" "$output_dir" "$strip" || {
        rm -f "$temp_file"
        return 1
    }

    # Posprzataj
    if [[ "$cleanup" == "true" ]]; then
        rm -f "$temp_file"
        msg_debug "Usunieto plik tymczasowy: $temp_file"
    fi

    return 0
}

# =============================================================================
# SEKCJA 7.7: Operacje na plikach konfiguracyjnych
# =============================================================================

# Ustawia wartosc w pliku konfiguracyjnym (format: klucz=wartosc lub klucz wartosc)
# Uzycie: config_set_value <file> <key> <value> [delimiter]
# Przyklad: config_set_value "/etc/app.conf" "max_connections" "100" "="
config_set_value() {
    local file="$1"
    local key="$2"
    local value="$3"
    local delimiter="${4:-=}"

    [[ -z "$file" ]] && { msg_error "Nie podano pliku konfiguracyjnego."; return 1; }
    [[ -z "$key" ]] && { msg_error "Nie podano klucza."; return 1; }
    [[ ! -f "$file" ]] && { msg_error "Plik nie istnieje: $file"; return 1; }

    # Sprawdz czy klucz istnieje (zakomentowany lub nie)
    if grep -qE "^[#;]*\s*${key}\s*${delimiter}" "$file"; then
        # Zamien istniejaca linie (takze zakomentowana)
        sed -i "s|^[#;]*\s*${key}\s*${delimiter}.*|${key}${delimiter}${value}|" "$file"
        msg_debug "Zmieniono: ${key}${delimiter}${value} w $file"
    else
        # Dodaj na koniec pliku
        echo "${key}${delimiter}${value}" >> "$file"
        msg_debug "Dodano: ${key}${delimiter}${value} do $file"
    fi
}

# Dodaje linie do pliku jesli nie istnieje
# Uzycie: config_append_if_missing <file> <line>
# Przyklad: config_append_if_missing "/etc/hosts" "127.0.0.1 myapp.local"
config_append_if_missing() {
    local file="$1"
    local line="$2"

    [[ -z "$file" ]] && { msg_error "Nie podano pliku."; return 1; }
    [[ -z "$line" ]] && { msg_error "Nie podano linii."; return 1; }

    # Utworz plik jesli nie istnieje
    if [[ ! -f "$file" ]]; then
        touch "$file"
    fi

    # Sprawdz czy linia juz istnieje
    if ! grep -qF "$line" "$file"; then
        echo "$line" >> "$file"
        msg_debug "Dodano do $file: $line"
        return 0
    else
        msg_debug "Linia juz istnieje w $file"
        return 1
    fi
}

# Usuwa linie z pliku
# Uzycie: config_remove_line <file> <pattern>
# Przyklad: config_remove_line "/etc/hosts" "myapp.local"
config_remove_line() {
    local file="$1"
    local pattern="$2"

    [[ -z "$file" ]] && { msg_error "Nie podano pliku."; return 1; }
    [[ -z "$pattern" ]] && { msg_error "Nie podano wzorca."; return 1; }
    [[ ! -f "$file" ]] && { msg_error "Plik nie istnieje: $file"; return 1; }

    sed -i "/${pattern}/d" "$file"
    msg_debug "Usunieto linie pasujace do '$pattern' z $file"
}

# Komentuje linie w pliku
# Uzycie: config_comment_line <file> <pattern> [comment_char]
config_comment_line() {
    local file="$1"
    local pattern="$2"
    local comment="${3:-#}"

    [[ ! -f "$file" ]] && { msg_error "Plik nie istnieje: $file"; return 1; }

    sed -i "s|^\(${pattern}.*\)|${comment}\1|" "$file"
}

# Odkomentowuje linie w pliku
# Uzycie: config_uncomment_line <file> <pattern> [comment_char]
config_uncomment_line() {
    local file="$1"
    local pattern="$2"
    local comment="${3:-#}"

    [[ ! -f "$file" ]] && { msg_error "Plik nie istnieje: $file"; return 1; }

    sed -i "s|^${comment}\s*\(${pattern}.*\)|\1|" "$file"
}

# =============================================================================
# SEKCJA 7.8: Uprawnienia i bezpieczenstwo plikow
# =============================================================================

# Ustawia standardowe uprawnienia dla aplikacji webowej
# Uzycie: set_web_permissions <path> [owner] [group]
# Przyklad: set_web_permissions "/var/www/wordpress" "www-data" "www-data"
set_web_permissions() {
    local path="$1"
    local owner="${2:-www-data}"
    local group="${3:-www-data}"

    [[ -z "$path" ]] && { msg_error "Nie podano sciezki."; return 1; }
    [[ ! -e "$path" ]] && { msg_error "Sciezka nie istnieje: $path"; return 1; }

    msg_info "Ustawianie uprawnien dla: $path"

    # Zmien wlasciciela
    chown -R "${owner}:${group}" "$path"

    # Ustaw uprawnienia: 755 dla katalogow, 644 dla plikow
    find "$path" -type d -exec chmod 755 {} \;
    find "$path" -type f -exec chmod 644 {} \;

    # Katalogi wymagajace zapisu (typowe dla CMS)
    for writable_dir in "cache" "tmp" "var" "uploads" "files" "storage" "logs"; do
        if [[ -d "${path}/${writable_dir}" ]]; then
            chmod -R 775 "${path}/${writable_dir}"
            msg_debug "Katalog zapisywalny: ${path}/${writable_dir}"
        fi
    done

    msg_ok "Uprawnienia ustawione dla: $path"
}

# Tworzy uzytkownika systemowego (dla uslug/daemonow)
# Uzycie: create_system_user <username> [home_dir] [description]
# Przyklad: create_system_user "myapp" "/opt/myapp" "My Application Service"
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

    # Utworz uzytkownika systemowego (bez powloki, bez logowania)
    useradd -r -s /bin/false -d "$home_dir" -m -c "$description" "$username"

    # Ustaw odpowiednie uprawnienia do katalogu domowego
    if [[ -d "$home_dir" ]]; then
        chown -R "${username}:${username}" "$home_dir"
        chmod 750 "$home_dir"
    fi

    msg_ok "Uzytkownik systemowy '$username' utworzony."
}

# Zabezpiecza plik (ustaw wlasciciela root i restrykcyjne uprawnienia)
# Uzycie: secure_file <file> [mode]
# Przyklad: secure_file "/etc/myapp/secret.key" "600"
secure_file() {
    local file="$1"
    local mode="${2:-600}"

    [[ -z "$file" ]] && { msg_error "Nie podano pliku."; return 1; }
    [[ ! -f "$file" ]] && { msg_error "Plik nie istnieje: $file"; return 1; }

    chown root:root "$file"
    chmod "$mode" "$file"
    msg_debug "Zabezpieczono plik: $file (mode: $mode)"
}

# =============================================================================
# SEKCJA 8: Obsluga bledow
# =============================================================================

# Wyswietla blad i konczy skrypt
die() {
    msg_error "$1"
    exit "${2:-1}"
}

# Ustawia trap dla bledow
trap_error() {
    trap 'msg_error "Blad w linii $LINENO. Kod wyjscia: $?"' ERR
}

# Bezpieczne wyjscie z czyszczeniem
safe_exit() {
    local code="${1:-0}"
    if [[ -n "${_NOOBS_TEMP_DIR:-}" ]] && [[ -d "$_NOOBS_TEMP_DIR" ]]; then
        cleanup_temp "$_NOOBS_TEMP_DIR"
    fi
    exit "$code"
}

# Wykonuje polecenie lub konczy z bledem
run_or_die() {
    local cmd="$1"
    local error_msg="${2:-Blad podczas wykonywania: $cmd}"

    if ! eval "$cmd"; then
        die "$error_msg"
    fi
}

# =============================================================================
# SEKCJA 9: Pomoc
# =============================================================================

# Generuje standardowa pomoc
show_help_template() {
    local name="$1"
    local description="$2"
    shift 2

    echo "Uzycie: $name [opcje]"
    echo ""
    echo "$description"
    echo ""
    echo "Opcje:"
    for opt in "$@"; do
        echo "  $opt"
    done
}

# Wyswietla informacje o wersji
show_version() {
    local name="$1"
    local version="$2"
    echo "$name wersja $version"
    echo "Biblioteka noobs_lib.sh wersja $NOOBS_LIB_VERSION"
}

# =============================================================================
# SEKCJA 11: Bazy danych MySQL/MariaDB
# =============================================================================

# Wykonuje zapytanie MySQL
# Uzycie: mysql_query <query> [user] [password]
# Przyklad: mysql_query "SHOW DATABASES;"
mysql_query() {
    local query="$1"
    local user="${2:-root}"
    local password="${3:-}"

    [[ -z "$query" ]] && { msg_error "Nie podano zapytania SQL."; return 1; }

    if [[ -n "$password" ]]; then
        mysql -u"$user" -p"$password" -e "$query"
    else
        mysql -u"$user" -e "$query"
    fi
}

# Tworzy baze danych i uzytkownika MySQL
# Uzycie: mysql_create_db_user <db_name> [username] [password] [hostname] [charset]
# Zwraca: haslo w zmiennej REPLY
# Przyklad: mysql_create_db_user "wordpress" "wp_user"
mysql_create_db_user() {
    local db_name="$1"
    local username="${2:-$db_name}"
    local password="${3:-$(generate_password 16)}"
    local hostname="${4:-localhost}"
    local charset="${5:-utf8mb4}"
    local collation="${6:-utf8mb4_general_ci}"

    [[ -z "$db_name" ]] && { msg_error "Nie podano nazwy bazy danych."; return 1; }

    msg_info "Tworzenie bazy danych: $db_name"

    # Utworz baze danych
    mysql_query "CREATE DATABASE IF NOT EXISTS \`$db_name\` CHARACTER SET $charset COLLATE $collation;" || {
        msg_error "Nie udalo sie utworzyc bazy danych."
        return 1
    }

    msg_info "Tworzenie uzytkownika: $username@$hostname"

    # Utworz uzytkownika i nadaj uprawnienia
    mysql_query "CREATE USER IF NOT EXISTS '$username'@'$hostname' IDENTIFIED BY '$password';" || {
        msg_error "Nie udalo sie utworzyc uzytkownika."
        return 1
    }

    mysql_query "GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$username'@'$hostname';" || {
        msg_error "Nie udalo sie nadac uprawnien."
        return 1
    }

    mysql_query "FLUSH PRIVILEGES;"

    msg_ok "Baza danych '$db_name' i uzytkownik '$username' utworzeni."

    # Zwroc haslo
    REPLY="$password"
    return 0
}

# Usuwa baze danych i uzytkownika
# Uzycie: mysql_drop_db_user <db_name> [username] [hostname]
mysql_drop_db_user() {
    local db_name="$1"
    local username="${2:-$db_name}"
    local hostname="${3:-localhost}"

    [[ -z "$db_name" ]] && { msg_error "Nie podano nazwy bazy danych."; return 1; }

    msg_info "Usuwanie bazy danych i uzytkownika: $db_name, $username"

    mysql_query "DROP DATABASE IF EXISTS \`$db_name\`;"
    mysql_query "DROP USER IF EXISTS '$username'@'$hostname';"
    mysql_query "FLUSH PRIVILEGES;"

    msg_ok "Baza danych i uzytkownik usunieci."
}

# =============================================================================
# SEKCJA 12: Konfiguracja PHP
# =============================================================================

# Instaluje pakiety PHP dla danej wersji
# Uzycie: php_install_packages <version> <packages...>
# Przyklad: php_install_packages "8.1" fpm mysql gd curl mbstring
php_install_packages() {
    local php_version="$1"
    shift
    local packages=("$@")

    [[ -z "$php_version" ]] && { msg_error "Nie podano wersji PHP."; return 1; }
    [[ ${#packages[@]} -eq 0 ]] && { msg_error "Nie podano pakietow PHP."; return 1; }

    msg_info "Instalowanie PHP $php_version z pakietami: ${packages[*]}"

    # Buduj liste pakietow z prefiksem wersji
    local full_packages=()
    for pkg in "${packages[@]}"; do
        # Sprawdz czy to pakiet bazowy czy rozszerzenie
        if [[ "$pkg" == "php" ]]; then
            full_packages+=("php${php_version}")
        else
            full_packages+=("php${php_version}-${pkg}")
        fi
    done

    pkg_install "${full_packages[@]}"
}

# Modyfikuje ustawienie w php.ini
# Uzycie: php_configure <version> <setting> <value> [type: fpm|cli|apache2]
# Przyklad: php_configure "8.1" "memory_limit" "512M" "fpm"
php_configure() {
    local php_version="$1"
    local setting="$2"
    local value="$3"
    local type="${4:-fpm}"

    [[ -z "$php_version" ]] && { msg_error "Nie podano wersji PHP."; return 1; }
    [[ -z "$setting" ]] && { msg_error "Nie podano ustawienia."; return 1; }
    [[ -z "$value" ]] && { msg_error "Nie podano wartosci."; return 1; }

    local ini_path="/etc/php/${php_version}/${type}/php.ini"

    if [[ ! -f "$ini_path" ]]; then
        msg_error "Plik php.ini nie istnieje: $ini_path"
        return 1
    fi

    msg_info "Ustawianie PHP: $setting = $value"

    # Backup
    backup_file "$ini_path"

    # Zmien ustawienie
    sed -i "s|^;*\s*${setting}\s*=.*|${setting} = ${value}|" "$ini_path"

    msg_ok "Zmieniono: $setting = $value w $ini_path"
}

# Tworzy pule PHP-FPM
# Uzycie: php_fpm_create_pool <version> <pool_name> <user> [pm_max_children]
# Przyklad: php_fpm_create_pool "8.1" "wordpress" "www-data" 10
php_fpm_create_pool() {
    local php_version="$1"
    local pool_name="$2"
    local user="$3"
    local group="${4:-$user}"
    local pm_max="${5:-5}"

    [[ -z "$php_version" ]] && { msg_error "Nie podano wersji PHP."; return 1; }
    [[ -z "$pool_name" ]] && { msg_error "Nie podano nazwy puli."; return 1; }
    [[ -z "$user" ]] && { msg_error "Nie podano uzytkownika."; return 1; }

    local pool_dir="/etc/php/${php_version}/fpm/pool.d"
    local pool_file="${pool_dir}/${pool_name}.conf"
    local socket_path="/run/php/${pool_name}.sock"

    [[ ! -d "$pool_dir" ]] && { msg_error "Katalog PHP-FPM nie istnieje: $pool_dir"; return 1; }

    msg_info "Tworzenie puli PHP-FPM: $pool_name"

    cat > "$pool_file" <<EOF
[$pool_name]
user = $user
group = $group
listen = $socket_path
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

pm = dynamic
pm.max_children = $pm_max
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3

php_admin_value[error_log] = /var/log/php-fpm/${pool_name}-error.log
php_admin_flag[log_errors] = on
EOF

    # Utworz katalog na logi
    mkdir -p /var/log/php-fpm

    msg_ok "Pula PHP-FPM utworzona: $pool_file"
    msg_info "Socket: $socket_path"

    # Zwroc sciezke socketa
    REPLY="$socket_path"
}

# =============================================================================
# SEKCJA 13: Konfiguracja serwerow WWW
# =============================================================================

# Tworzy VirtualHost Apache
# Uzycie: apache_create_vhost <name> <document_root> [port] [server_name]
# Przyklad: apache_create_vhost "wordpress" "/var/www/wordpress" 80
apache_create_vhost() {
    local vhost_name="$1"
    local doc_root="$2"
    local port="${3:-80}"
    local server_name="${4:-_}"

    [[ -z "$vhost_name" ]] && { msg_error "Nie podano nazwy vhosta."; return 1; }
    [[ -z "$doc_root" ]] && { msg_error "Nie podano document root."; return 1; }

    local vhost_file="/etc/apache2/sites-available/${vhost_name}.conf"

    msg_info "Tworzenie Apache VirtualHost: $vhost_name"

    cat > "$vhost_file" <<EOF
<VirtualHost *:${port}>
    ServerName ${server_name}
    DocumentRoot ${doc_root}

    <Directory ${doc_root}>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/${vhost_name}_error.log
    CustomLog \${APACHE_LOG_DIR}/${vhost_name}_access.log combined
</VirtualHost>
EOF

    msg_ok "VirtualHost utworzony: $vhost_file"
}

# Tworzy Alias Apache
# Uzycie: apache_create_alias <alias_name> <alias_url> <directory_path>
# Przyklad: apache_create_alias "nextcloud" "/nextcloud" "/var/www/nextcloud"
apache_create_alias() {
    local alias_name="$1"
    local alias_url="$2"
    local dir_path="$3"

    [[ -z "$alias_name" ]] && { msg_error "Nie podano nazwy aliasu."; return 1; }
    [[ -z "$alias_url" ]] && { msg_error "Nie podano URL aliasu."; return 1; }
    [[ -z "$dir_path" ]] && { msg_error "Nie podano sciezki katalogu."; return 1; }

    local alias_file="/etc/apache2/sites-available/${alias_name}.conf"

    msg_info "Tworzenie Apache Alias: $alias_name"

    cat > "$alias_file" <<EOF
Alias ${alias_url} "${dir_path}/"

<Directory ${dir_path}/>
    Satisfy Any
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews

    <IfModule mod_dav.c>
        Dav off
    </IfModule>
</Directory>
EOF

    msg_ok "Alias utworzony: $alias_file"
}

# Tworzy server block Nginx
# Uzycie: nginx_create_server_block <name> <root_path> <php_socket> [app_type]
# app_type: generic|drupal|moodle|wordpress
# Przyklad: nginx_create_server_block "drupal" "/var/www/drupal" "/run/php/drupal.sock" "drupal"
nginx_create_server_block() {
    local block_name="$1"
    local root_path="$2"
    local php_socket="${3:-/var/run/php/php-fpm.sock}"
    local app_type="${4:-generic}"

    [[ -z "$block_name" ]] && { msg_error "Nie podano nazwy bloku."; return 1; }
    [[ -z "$root_path" ]] && { msg_error "Nie podano sciezki root."; return 1; }

    local block_file="/etc/nginx/sites-available/${block_name}"

    msg_info "Tworzenie Nginx server block: $block_name"

    # Naglowek wspolny
    cat > "$block_file" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name _;
    root ${root_path};
    index index.php index.html index.htm;

EOF

    # Konfiguracja specyficzna dla aplikacji
    case "$app_type" in
        drupal)
            cat >> "$block_file" <<EOF
    location / {
        try_files \$uri /index.php?\$query_string;
    }

    location @rewrite {
        rewrite ^ /index.php;
    }

    location ~ '\.php\$|^/update.php' {
        fastcgi_split_path_info ^(.+?\.php)(|/.*)\$;
        try_files \$fastcgi_script_name =404;
        include fastcgi_params;
        fastcgi_param HTTP_PROXY "";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_intercept_errors on;
        fastcgi_pass unix:${php_socket};
    }
EOF
            ;;
        moodle|wordpress)
            cat >> "$block_file" <<EOF
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(.*)\$;
        fastcgi_index index.php;
        fastcgi_pass unix:${php_socket};
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }
EOF
            ;;
        *)
            cat >> "$block_file" <<EOF
    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${php_socket};
    }
EOF
            ;;
    esac

    # Zakonczenie
    cat >> "$block_file" <<EOF

    location ~ /\.ht {
        deny all;
    }

    error_log /var/log/nginx/${block_name}_error.log;
    access_log /var/log/nginx/${block_name}_access.log;
}
EOF

    msg_ok "Server block utworzony: $block_file"
}

# Wlacza site dla Apache lub Nginx
# Uzycie: webserver_enable_site <server_type> <site_name>
# Przyklad: webserver_enable_site "apache" "wordpress"
webserver_enable_site() {
    local server_type="$1"
    local site_name="$2"

    [[ -z "$server_type" ]] && { msg_error "Nie podano typu serwera."; return 1; }
    [[ -z "$site_name" ]] && { msg_error "Nie podano nazwy strony."; return 1; }

    msg_info "Wlaczanie strony: $site_name ($server_type)"

    case "$server_type" in
        apache)
            a2ensite "$site_name" >/dev/null 2>&1
            service_reload apache2
            ;;
        nginx)
            ln -sf "/etc/nginx/sites-available/${site_name}" \
                   "/etc/nginx/sites-enabled/${site_name}"
            service_reload nginx
            ;;
        *)
            msg_error "Nieznany typ serwera: $server_type"
            return 1
            ;;
    esac

    msg_ok "Strona wlaczona: $site_name"
}

# Wylacza site
# Uzycie: webserver_disable_site <server_type> <site_name>
webserver_disable_site() {
    local server_type="$1"
    local site_name="$2"

    [[ -z "$server_type" ]] && { msg_error "Nie podano typu serwera."; return 1; }
    [[ -z "$site_name" ]] && { msg_error "Nie podano nazwy strony."; return 1; }

    msg_info "Wylaczanie strony: $site_name ($server_type)"

    case "$server_type" in
        apache)
            a2dissite "$site_name" >/dev/null 2>&1
            service_reload apache2
            ;;
        nginx)
            rm -f "/etc/nginx/sites-enabled/${site_name}"
            service_reload nginx
            ;;
        *)
            msg_error "Nieznany typ serwera: $server_type"
            return 1
            ;;
    esac

    msg_ok "Strona wylaczona: $site_name"
}

# =============================================================================
# SEKCJA 14: Zarzadzanie uzytkownikami Web
# =============================================================================

# Tworzy uzytkownika dla aplikacji webowej
# Uzycie: create_web_user <username> [home_dir] [shell] [chroot_ssh]
# Zwraca: haslo w REPLY
# Przyklad: create_web_user "wordpress" "/var/www/wordpress" "/bin/bash" true
create_web_user() {
    local username="$1"
    local home_dir="${2:-/home/$username}"
    local shell="${3:-/bin/bash}"
    local chroot_ssh="${4:-false}"

    [[ -z "$username" ]] && { msg_error "Nie podano nazwy uzytkownika."; return 1; }

    # Sprawdz czy uzytkownik istnieje
    if user_exists "$username"; then
        msg_warn "Uzytkownik '$username' juz istnieje."
        return 0
    fi

    msg_info "Tworzenie uzytkownika: $username"

    # Wygeneruj haslo
    local password
    password=$(generate_password 12)

    # Utworz uzytkownika
    useradd -m -d "$home_dir" -s "$shell" "$username"
    echo "${username}:${password}" | chpasswd

    msg_ok "Uzytkownik '$username' utworzony."

    # Opcjonalne chroot SSH
    if [[ "$chroot_ssh" == "true" ]]; then
        msg_info "Konfigurowanie chroot SSH dla $username"

        # Dodaj konfiguracje do sshd_config jesli nie istnieje
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

    # Zwroc haslo
    REPLY="$password"
    msg_info "Haslo uzytkownika: $password"
}

# Usuwa uzytkownika web
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

    # Usun konfiguracje SSH jesli istnieje
    if grep -q "Match User $username" /etc/ssh/sshd_config; then
        sed -i "/Match User $username/,/^Match\|^$/d" /etc/ssh/sshd_config
        service_reload sshd 2>/dev/null || service_reload ssh 2>/dev/null
    fi

    msg_ok "Uzytkownik '$username' usuniety."
}

# =============================================================================
# SEKCJA 15: Uslugi Systemd
# =============================================================================

# Tworzy plik uslugi systemd
# Uzycie: create_systemd_service <name> <description> <exec_start> [user] [after] [restart]
# Przyklad: create_systemd_service "myapp" "My Application" "/usr/bin/myapp" "www-data" "network.target"
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

    # Przeladuj daemon
    systemctl daemon-reload

    msg_ok "Usluga systemd utworzona: $service_file"
}

# Tworzy timer systemd
# Uzycie: create_systemd_timer <name> <on_calendar> <description>
# Przyklad: create_systemd_timer "backup" "daily" "Daily backup timer"
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

# Usuwa usluge systemd
# Uzycie: delete_systemd_service <name>
delete_systemd_service() {
    local service_name="$1"

    [[ -z "$service_name" ]] && { msg_error "Nie podano nazwy uslugi."; return 1; }

    local service_file="/etc/systemd/system/${service_name}.service"
    local timer_file="/etc/systemd/system/${service_name}.timer"

    msg_info "Usuwanie uslugi systemd: $service_name"

    # Zatrzymaj i wylacz
    systemctl stop "${service_name}.service" 2>/dev/null
    systemctl disable "${service_name}.service" 2>/dev/null

    # Usun pliki
    rm -f "$service_file"
    rm -f "$timer_file"

    systemctl daemon-reload

    msg_ok "Usluga systemd usunieta: $service_name"
}

# =============================================================================
# SEKCJA 16: Aliasy dla wstecznej kompatybilnosci (deprecated)
# =============================================================================

# Aliasy dla starych skryptow - zostana usuniete w wersji 2.0
_ask_input() { ask_input "$@"; }
_service_exists() { service_exists "$@"; }
status() { msg_status "$@"; }
err() { die "$@"; }
