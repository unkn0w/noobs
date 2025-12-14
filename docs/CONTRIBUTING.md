# Przewodnik: Tworzenie Skryptów dla Self-Hosted Serwisów

> Przewodnik dla programistów chcących dodać nowy skrypt do projektu noobs.

---

## 1. Analiza Wymagań Serwisu

Przed napisaniem skryptu odpowiedz na pytania:

| Pytanie                             | Przykład dla Gitea                    |
| ----------------------------------- | ------------------------------------- |
| Jakie pakiety są potrzebne?         | git, mariadb-server                   |
| Czy wymaga bazy danych?             | Tak (MySQL/MariaDB/PostgreSQL/SQLite) |
| Czy potrzebuje PHP?                 | Nie                                   |
| Jaki serwer WWW?                    | Wbudowany / Nginx jako reverse proxy  |
| Skąd pobrać aplikację?              | https://dl.gitea.io/gitea/            |
| Jak uruchomić jako usługę?          | Systemd unit file                     |
| Jakie porty?                        | 3000 (HTTP), 22 (SSH)                 |
| Czy wymaga użytkownika systemowego? | Tak (git)                             |

---

## 2. Struktura Skryptu

```bash
#!/bin/bash
# Instalator [NAZWA_SERWISU]
# Autor: [TWOJE_IMIE]
# Wersja: 1.0.0

# ═══════════════════════════════════════════════════════════════
# SEKCJA 1: Załaduj bibliotekę noobs
# ═══════════════════════════════════════════════════════════════
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

# ═══════════════════════════════════════════════════════════════
# SEKCJA 2: Zmienne konfiguracyjne
# ═══════════════════════════════════════════════════════════════
APP_NAME="nazwa_aplikacji"
APP_VERSION="1.0.0"
APP_USER="appuser"
APP_HOME="/opt/${APP_NAME}"
APP_PORT="${1:-8080}"  # Domyślny port lub z argumentu

# ═══════════════════════════════════════════════════════════════
# SEKCJA 3: Walidacja
# ═══════════════════════════════════════════════════════════════
require_root
validate_port "$APP_PORT"

# ═══════════════════════════════════════════════════════════════
# SEKCJA 4: Instalacja zależności
# ═══════════════════════════════════════════════════════════════
msg_info "Instalacja pakietów"
pkg_update
pkg_install git curl wget

# ═══════════════════════════════════════════════════════════════
# SEKCJA 5: Tworzenie użytkownika (jeśli potrzebny)
# ═══════════════════════════════════════════════════════════════
msg_info "Tworzenie użytkownika systemowego"
create_system_user "$APP_USER" "$APP_HOME" "Użytkownik dla $APP_NAME"

# ═══════════════════════════════════════════════════════════════
# SEKCJA 6: Baza danych (jeśli potrzebna)
# ═══════════════════════════════════════════════════════════════
msg_info "Tworzenie bazy danych"
mysql_create_db_user "$APP_NAME" "$APP_USER"
DB_PASS="$REPLY"

# ═══════════════════════════════════════════════════════════════
# SEKCJA 7: Pobieranie i instalacja aplikacji
# ═══════════════════════════════════════════════════════════════
msg_info "Pobieranie $APP_NAME v$APP_VERSION"
download_and_extract \
    "https://example.com/${APP_NAME}-${APP_VERSION}.tar.gz" \
    "$APP_HOME" \
    1 \
    true

# ═══════════════════════════════════════════════════════════════
# SEKCJA 8: Konfiguracja
# ═══════════════════════════════════════════════════════════════
msg_info "Konfiguracja aplikacji"
cat > "${APP_HOME}/config.ini" <<EOF
[server]
port = $APP_PORT

[database]
host = localhost
name = $APP_NAME
user = $APP_USER
password = $DB_PASS
EOF

# ═══════════════════════════════════════════════════════════════
# SEKCJA 9: Uprawnienia
# ═══════════════════════════════════════════════════════════════
msg_info "Ustawianie uprawnień"
chown -R "${APP_USER}:${APP_USER}" "$APP_HOME"
chmod 750 "$APP_HOME"
secure_file "${APP_HOME}/config.ini" 600

# ═══════════════════════════════════════════════════════════════
# SEKCJA 10: Usługa Systemd
# ═══════════════════════════════════════════════════════════════
msg_info "Tworzenie usługi systemd"
cat > "/etc/systemd/system/${APP_NAME}.service" <<EOF
[Unit]
Description=$APP_NAME Service
After=network.target mariadb.service

[Service]
Type=simple
User=$APP_USER
WorkingDirectory=$APP_HOME
ExecStart=${APP_HOME}/bin/${APP_NAME}
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
service_enable_now "$APP_NAME"

# ═══════════════════════════════════════════════════════════════
# SEKCJA 11: Podsumowanie
# ═══════════════════════════════════════════════════════════════
IP=$(get_local_ip)
msg_ok "Instalacja zakończona pomyślnie!"
echo "════════════════════════════════════════"
echo "Adres:         http://${IP}:${APP_PORT}"
echo "Baza danych:   $APP_NAME"
echo "Użytkownik DB: $APP_USER"
echo "Hasło DB:      $DB_PASS"
echo "════════════════════════════════════════"

# Zapisz dane do pliku
cat > "${APP_NAME}_credentials.txt" <<EOF
URL: http://${IP}:${APP_PORT}
Database: $APP_NAME
DB User: $APP_USER
DB Password: $DB_PASS
EOF
msg_info "Dane zapisane w ${APP_NAME}_credentials.txt"
```

---

## 3. Lista Kontrolna Przed Publikacją

- [ ] Skrypt używa `noobs_lib.sh`
- [ ] Wszystkie komunikaty przez `msg_*`
- [ ] Sprawdzenie uprawnień przez `require_root`
- [ ] Instalacja pakietów przez `pkg_install`
- [ ] Usługi przez `service_*`
- [ ] Hasła przez `generate_password()`
- [ ] Brak hardkodowanych ścieżek specyficznych dla dystrybucji
- [ ] Brak `chmod 777`
- [ ] Brak `apt-key add`
- [ ] Brak `curl | bash`

---

## 4. Mapowanie Typów Serwisów na Funkcje Biblioteczne

| Typ serwisu           | Funkcje do użycia                                                                                    |
| --------------------- | ---------------------------------------------------------------------------------------------------- |
| **Aplikacja PHP**     | `php_install_packages`, `php_fpm_create_pool`, `nginx_create_server_block` lub `apache_create_vhost` |
| **Aplikacja Node.js** | `pkg_install nodejs npm`, `create_system_user`, usługa systemd                                       |
| **Aplikacja Python**  | `pkg_install python3 python3-pip python3-venv`, `create_system_user`                                 |
| **Aplikacja Go**      | `download_and_extract` (binary), `create_system_user`                                                |
| **Baza danych**       | `add_repository_with_key`, `pkg_install`, `service_enable_now`                                       |
| **Kontener Docker**   | `pkg_install docker.io`, `service_enable_now docker`                                                 |
| **VPN/Sieć**          | `config_set_value`, `config_append_if_missing`, `service_enable_now`                                 |

---

## 5. Wzorce dla Popularnych Kategorii

### Wzorzec A: CMS/Aplikacja PHP (WordPress, Drupal, Nextcloud)

```bash
require_root
pkg_update
add_ppa_repo "ondrej/php"
pkg_install nginx mariadb-server
php_install_packages "8.2" fpm mysql gd curl mbstring xml zip

mysql_create_db_user "$APP_NAME" "$APP_USER"
create_web_user "$APP_USER" "/var/www/$APP_NAME"
download_and_extract "$URL" "/var/www/$APP_NAME" 1 true
set_web_permissions "/var/www/$APP_NAME" "$APP_USER" "www-data"
php_fpm_create_pool "8.2" "$APP_NAME" "$APP_USER"
nginx_create_server_block "$APP_NAME" "/var/www/$APP_NAME" "$PHP_SOCKET" "generic"
webserver_enable_site "nginx" "$APP_NAME"
```

### Wzorzec B: Aplikacja binarna (Gitea, Minio, Vault)

```bash
require_root
pkg_update
pkg_install curl wget

create_system_user "$APP_USER" "$APP_HOME" "$APP_NAME service"
download_file "$BINARY_URL" "$APP_HOME/bin/$APP_NAME"
chmod +x "$APP_HOME/bin/$APP_NAME"
# Utwórz systemd unit file
service_enable_now "$APP_NAME"
```

### Wzorzec C: Usługa z repozytorium (MongoDB, PostgreSQL, Docker)

```bash
require_root
pkg_update
pkg_install software-properties-common gnupg

add_repository_with_key \
    "$REPO_URL" \
    "$REPO_NAME" \
    "$GPG_KEY_URL"

pkg_update
pkg_install "$PACKAGE_NAME"
service_enable_now "$SERVICE_NAME"
```

---

## 6. Debugowanie i Testowanie

### Tryb debug

```bash
# Na początku skryptu dodaj:
DEBUG=1  # Włącza msg_debug()

# Lub uruchom z:
DEBUG=1 ./chce_nazwa.sh
```

### Testowanie na świeżym systemie

```bash
# Użyj kontenera Docker:
docker run -it --rm debian:12 bash

# Wewnątrz kontenera:
apt update && apt install -y git
git clone https://github.com/user/noobs.git
cd noobs
./scripts/chce_nazwa.sh
```

### Walidacja skryptu

```bash
# Sprawdź składnię bash:
bash -n scripts/chce_nazwa.sh

# Użyj shellcheck:
shellcheck scripts/chce_nazwa.sh

# Sprawdź czy używa biblioteki:
grep -q "source.*noobs_lib.sh" scripts/chce_nazwa.sh && echo "OK"
```

---

## 7. Przydatne Funkcje Biblioteczne

### Komunikaty
```bash
msg_info "Informacja"      # [INFO] niebieski
msg_ok "Sukces"            # [OK] zielony
msg_error "Błąd"           # [ERR] czerwony
msg_warn "Ostrzeżenie"     # [WARN] żółty
msg_debug "Debug"          # [DEBUG] tylko gdy DEBUG=1
```

### Pakiety
```bash
pkg_update                 # Aktualizacja listy
pkg_install pkg1 pkg2      # Instalacja
pkg_is_installed pkg       # Sprawdzenie
```

### Usługi
```bash
service_start nazwa        # Uruchom
service_stop nazwa         # Zatrzymaj
service_restart nazwa      # Restart
service_enable_now nazwa   # Uruchom + autostart
```

### Baza danych
```bash
mysql_create_db_user "baza" "user"
DB_PASS="$REPLY"
```

### Użytkownicy
```bash
create_system_user "user" "/home/user" "Opis"
create_web_user "user" "/var/www/user"
USER_PASS="$REPLY"
```

### Pobieranie
```bash
download_file "URL" "/sciezka/plik"
download_and_extract "URL" "/katalog" 1 true
```

### Hasła
```bash
password=$(generate_password 16)
random_id=$(generate_random_string 8)
```

---

*Zobacz też: [AGENT_PROMPTS.md](AGENT_PROMPTS.md) - jak używać AI do tworzenia skryptów*
