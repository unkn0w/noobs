# Przewodnik: Tworzenie Skryptów z AI (Claude Code)

> Szablony promptów do generowania skryptów noobs za pomocą Claude Code lub innych asystentów AI.

---

## 1. Prosty Prompt

```
Stwórz skrypt instalacyjny dla [NAZWA_SERWISU] w projekcie noobs.

Wymagania serwisu:
- Oficjalna strona: [URL]
- Zależności: [lista pakietów]
- Baza danych: [MySQL/PostgreSQL/SQLite/brak]
- Serwer WWW: [Apache/Nginx/wbudowany]
- Port domyślny: [PORT]

Skrypt MUSI:
1. Używać biblioteki noobs_lib.sh
2. Przyjmować port jako argument: ./chce_[nazwa].sh [port]
3. Generować bezpieczne hasła przez generate_password()
4. Tworzyć usługę systemd
5. Wyświetlać podsumowanie z danymi dostępowymi

Wzoruj się na istniejących skryptach w scripts/
```

---

## 2. Zaawansowany Prompt z Kontekstem

```
Przeanalizuj bibliotekę lib/noobs_lib.sh i istniejące skrypty w scripts/,
a następnie stwórz skrypt instalacyjny dla [NAZWA_SERWISU].

Kontekst techniczny:
- Architektura: [x86_64/ARM]
- System: Debian/Ubuntu
- Cel: [serwer domowy/VPS/produkcja]

Wymagania funkcjonalne:
1. [Wymóg 1]
2. [Wymóg 2]
3. [Wymóg 3]

Wymagania bezpieczeństwa:
- Osobny użytkownik systemowy
- Minimalne uprawnienia (775, nie 777)
- Konfiguracja firewall (opcjonalnie)
- Backup przed instalacją

Po napisaniu skryptu:
1. Sprawdź zgodność z wzorcami noobs
2. Zweryfikuj użycie funkcji bibliotecznych
3. Upewnij się, że nie ma problemów bezpieczeństwa
```

---

## 3. Przykłady Rzeczywiste

### Gitea (serwer Git)

```
Stwórz skrypt chce_gitea.sh dla projektu noobs.

Gitea to lekki serwer Git (alternatywa dla GitHub/GitLab).
- Strona: https://gitea.io
- Download: https://dl.gitea.io/gitea/
- Baza: MariaDB
- Port: 3000

Dodatkowe wymagania:
1. Użytkownik systemowy: git
2. Katalog domowy: /var/lib/gitea
3. Katalog danych: /var/lib/gitea/data
4. Konfiguracja w: /etc/gitea/app.ini
5. Reverse proxy Nginx (opcjonalny)

Skrypt powinien:
- Pobrać najnowszą wersję z API GitHub
- Stworzyć strukturę katalogów
- Wygenerować app.ini z bazowymi ustawieniami
- Utworzyć usługę systemd
- Wyświetlić URL do dokończenia instalacji w przeglądarce
```

### Uptime Kuma (monitoring)

```
Stwórz skrypt chce_uptime_kuma.sh dla projektu noobs.

Uptime Kuma to self-hosted monitoring tool.
- Strona: https://github.com/louislam/uptime-kuma
- Wymaga: Node.js 18+
- Baza: SQLite (wbudowana)
- Port: 3001

Wymagania:
1. Instalacja Node.js z NodeSource repo
2. Użytkownik systemowy: uptime-kuma
3. Katalog: /opt/uptime-kuma
4. Usługa systemd z automatycznym restartem
```

### Vaultwarden (menedżer haseł)

```
Stwórz skrypt chce_vaultwarden.sh dla projektu noobs.

Vaultwarden to self-hosted Bitwarden server.
- Strona: https://github.com/dani-garcia/vaultwarden
- Instalacja: Docker lub binary
- Baza: SQLite (domyślnie)
- Port: 8000

Wymagania:
1. Preferuj instalację przez Docker
2. Wolumen na dane: /opt/vaultwarden/data
3. Zmienne środowiskowe w .env
4. HTTPS przez reverse proxy (opcjonalnie)
```

---

## 4. Prompt do Refaktoryzacji Istniejącego Skryptu

```
Zrefaktoryzuj skrypt scripts/chce_[nazwa].sh do używania biblioteki noobs_lib.sh.

Wykonaj następujące zmiany:
1. Dodaj import biblioteki na początku
2. Zamień echo -e na msg_info/msg_ok/msg_error
3. Zamień apt install -y na pkg_install
4. Zamień systemctl na service_* funkcje
5. Zamień ręczne sprawdzanie root na require_root
6. Zamień generowanie haseł na generate_password()
7. Napraw problemy bezpieczeństwa (chmod 777, apt-key, itp.)

Zachowaj oryginalną funkcjonalność skryptu.
```

---

## 5. Prompt do Analizy Bezpieczeństwa

```
Przeanalizuj skrypt scripts/chce_[nazwa].sh pod kątem bezpieczeństwa.

Sprawdź:
1. Czy używa deprecated apt-key?
2. Czy używa chmod 777?
3. Czy używa curl | bash?
4. Czy generuje hasła przez $RANDOM?
5. Czy używa /etc/init.d/ zamiast systemd?
6. Czy hardkoduje hasła lub tokeny?

Zaproponuj poprawki używając funkcji z noobs_lib.sh.
```

---

## 6. Prompt do Generowania Dokumentacji

```
Na podstawie skryptu scripts/chce_[nazwa].sh wygeneruj:

1. Krótki opis co skrypt instaluje (1-2 zdania)
2. Lista wymagań (system, pakiety, porty)
3. Składnia użycia z przykładami
4. Zmienne konfiguracyjne (jeśli są)
5. Dane dostępowe po instalacji
6. Troubleshooting - najczęstsze problemy

Format: Markdown
```

---

## 7. Wskazówki dla AI

### Co Agent MUSI zrobić:

1. **Zawsze** zaczynać skrypt od:
   ```bash
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1
   ```

2. **Zawsze** sprawdzać uprawnienia:
   ```bash
   require_root
   ```

3. **Zawsze** używać funkcji bibliotecznych zamiast bezpośrednich poleceń:
   - `pkg_install` zamiast `apt install`
   - `service_*` zamiast `systemctl`
   - `msg_*` zamiast `echo -e`
   - `generate_password` zamiast `$RANDOM`

### Czego Agent NIE MOŻE robić:

1. ❌ `chmod 777` - używaj `chmod 775` + `usermod -aG www-data`
2. ❌ `apt-key add` - używaj `add_repository_with_key()`
3. ❌ `curl URL | bash` - pobierz plik, zweryfikuj, wykonaj
4. ❌ `echo $RANDOM | md5sum` - używaj `generate_random_string()`
5. ❌ `/etc/init.d/xxx start` - używaj `service_start xxx`

---

## 8. Weryfikacja Wygenerowanego Skryptu

Po wygenerowaniu skryptu przez AI, sprawdź:

```bash
# Składnia bash
bash -n scripts/chce_nazwa.sh

# Shellcheck
shellcheck scripts/chce_nazwa.sh

# Czy używa biblioteki
grep -q "source.*noobs_lib.sh" scripts/chce_nazwa.sh

# Czy nie ma zabronionych wzorców
grep -E "chmod 777|apt-key add|curl.*\| bash|\$RANDOM" scripts/chce_nazwa.sh && echo "BŁĄD!"
```

---

*Zobacz też: [CONTRIBUTING.md](CONTRIBUTING.md) - ręczne tworzenie skryptów*
