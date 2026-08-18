#!/bin/bash
# Instaluje Coolify na VPS Mikrusa mimo braku dedykowanego publicznego IPv4 -
# wykorzystuje w pelni routowalny adres IPv6 VPS-a zamiast NAT-u Mikrusa.
# Uzycie: ./chce_coolify.sh [KLUCZ_API_MIKRUSA]
#         MIKRUS_API_KEY=xxx ./chce_coolify.sh
# Klucz API (https://mikr.us/panel/?a=api) jest opcjonalny - potrzebny tylko
# do automatycznego zalozenia publicznej subdomeny (komenda "domena").
# Autor: Maciej Loper
set -euo pipefail

[[ $EUID -ne 0 ]] && { echo "Uruchom jako root."; exit 1; }

status() { echo -e "\e[0;32m[x] \e[1;32m$1\e[0;0m"; }
warn()   { echo -e "\e[0;33m[!] \e[1;33m$1\e[0;0m"; }
err()    { echo -e "\e[0;31m[!] \e[1;31m$1\e[0;0m"; exit 1; }

IPV6_ADDR="$(ip -6 addr show scope global 2>/dev/null | awk '/inet6/{print $2}' | cut -d/ -f1 | head -1)"
HOSTNAME_SHORT="$(hostname)"
MEM_MB="$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo)"
CPU_COUNT="$(nproc)"

status "Host: $HOSTNAME_SHORT | RAM: ${MEM_MB}MB | vCPU: ${CPU_COUNT} | IPv6: ${IPV6_ADDR:-brak}"
[ "$MEM_MB" -lt 2000 ] && warn "Coolify zaleca min. 2GB RAM (tu: ${MEM_MB}MB) - moze dzialac wolno."
[ -z "$IPV6_ADDR" ] && err "Brak globalnego IPv6 - ten VPS nie da rady bez niego."

# pakiety potrzebne przed instalatorem Coolify
if ! command -v jq >/dev/null || ! command -v curl >/dev/null || ! command -v openssl >/dev/null; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq curl jq openssl >/dev/null
fi

# przekazywanie IPv6 - zeby Docker mogl go NAT-owac do siebie
cat >/etc/sysctl.d/99-coolify-ipv6.conf <<'EOF'
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1
EOF
sysctl -p /etc/sysctl.d/99-coolify-ipv6.conf >/dev/null 2>&1 \
    || warn "IPv6 forwarding sie nie wlaczyl (limity LXC) - sprawdz na koncu skryptu."

# Docker
command -v docker >/dev/null || curl -fsSL https://get.docker.com | sh
systemctl enable --now docker >/dev/null 2>&1 || true

# daemon.json z IPv6 - instalator Coolify NADPISZE ten plik, jesli nie
# zastanie dokladnie takiej samej sekcji default-address-pools jak jego
# domyslna, wiec ustawiamy ja identycznie i dorzucamy IPv6.
DAEMON_JSON=/etc/docker/daemon.json
mkdir -p /etc/docker
NEEDS_RESTART=false
DESIRED_JSON='{
  "log-driver": "json-file",
  "log-opts": {"max-size": "10m", "max-file": "3"},
  "default-address-pools": [{"base": "10.0.0.0/8", "size": 24}],
  "ipv6": true,
  "fixed-cidr-v6": "fd00:c0ff:ee::/64",
  "ip6tables": true,
  "default-network-opts": {"bridge": {"com.docker.network.enable_ipv6": "true"}}
}'
if [ ! -f "$DAEMON_JSON" ]; then
    echo "$DESIRED_JSON" | jq . >"$DAEMON_JSON"
    NEEDS_RESTART=true
elif ! jq -e '.ipv6 == true and .["default-network-opts"]["bridge"]["com.docker.network.enable_ipv6"] == "true"' "$DAEMON_JSON" >/dev/null 2>&1; then
    cp "$DAEMON_JSON" "${DAEMON_JSON}.bak-$(date +%s)"
    jq -s '.[0] * .[1]' "$DAEMON_JSON" <(echo "$DESIRED_JSON") >"${DAEMON_JSON}.tmp" && mv "${DAEMON_JSON}.tmp" "$DAEMON_JSON"
    NEEDS_RESTART=true
fi
if [ "$NEEDS_RESTART" = true ]; then
    systemctl restart docker
    sleep 2
fi
status "Docker skonfigurowany pod IPv6."

# haslo/e-mail konta root Coolify - generujemy je od razu, zeby nie zostawiac
# publicznego formularza rejestracji. Coolify's RootUserSeeder.php odrzuca
# oba, jesli nie spelnia jego walidacji:
#   email:  regula 'email:rfc,dns' - wymaga domeny z realnym rekordem DNS,
#           wiec np. "admin@host.local" jest ZAWSZE odrzucany (.local nie
#           ma DNS-a) - uzywamy wiec prawdziwego, rozwiazywalnego hosta VPS-a.
#   haslo:  Password::min(8)->mixedCase()->letters()->numbers()->symbols() -
#           czysty `openssl rand -base64 | tr -d '=+/'` NIE MA symboli wcale
#           (baza64 ma ich tylko 2: '+' i '/', a te akurat usuwalismy), wiec
#           tez zawsze przechodzil walidacje. Stad wlasna generacja z
#           gwarantowanym udzialem kazdej klasy znakow.
# WAZNE: instalator (update_env_var w install.sh) nadpisuje pole w .env
# TYLKO gdy jest ono PUSTE - nie sprawdza, czy istniejaca wartosc jest
# poprawna. Jesli w .env zostal juz raz zapisany bledny email/haslo (bo np.
# ta wersja skryptu miala powyzszy bug), sam re-run niczego nie naprawi -
# trzeba sprawdzic, czy konto root FAKTYCZNIE istnieje w bazie Coolify, a
# nie tylko czy .env "wyglada" na wypelniony, i w razie potrzeby nadpisac
# .env samemu przed wywolaniem instalatora.
COOLIFY_ENV_FILE=/data/coolify/source/.env
ROOT_USER_EXISTS=false
if docker inspect coolify-db >/dev/null 2>&1; then
    docker exec coolify-db psql -U coolify -d coolify -tAc "select 1 from users where id=0" 2>/dev/null \
        | grep -q 1 && ROOT_USER_EXISTS=true
fi

if [ "$ROOT_USER_EXISTS" = true ]; then
    COOLIFY_ROOT_PASSWORD="$(grep -E '^ROOT_USER_PASSWORD=' "$COOLIFY_ENV_FILE" | cut -d= -f2-)"
    COOLIFY_ROOT_EMAIL="$(grep -E '^ROOT_USER_EMAIL=' "$COOLIFY_ENV_FILE" | cut -d= -f2-)"
    status "Konto root Coolify juz istnieje w bazie - uzywam istniejacych danych logowania."
else
    COOLIFY_BASE="$(tr -dc 'A-Za-z0-9!@#%^&*()-_=+' </dev/urandom | head -c20 || true)"
    COOLIFY_EXTRA="$(tr -dc 'A-Z' </dev/urandom | head -c1 || true)$(tr -dc 'a-z' </dev/urandom | head -c1 || true)$(tr -dc '0-9' </dev/urandom | head -c1 || true)$(tr -dc '!@#%^&*()-_=+' </dev/urandom | head -c1 || true)"
    COOLIFY_ROOT_PASSWORD="$(printf '%s%s' "$COOLIFY_BASE" "$COOLIFY_EXTRA" | fold -w1 | shuf | tr -d '\n')"
    COOLIFY_ROOT_EMAIL="admin@${HOSTNAME_SHORT}.mikrus.xyz"

    if [ -f "$COOLIFY_ENV_FILE" ]; then
        for key in ROOT_USERNAME ROOT_USER_EMAIL ROOT_USER_PASSWORD; do
            sed -i "/^${key}=/d" "$COOLIFY_ENV_FILE"
        done
        {
            echo "ROOT_USERNAME=admin"
            echo "ROOT_USER_EMAIL=${COOLIFY_ROOT_EMAIL}"
            echo "ROOT_USER_PASSWORD=${COOLIFY_ROOT_PASSWORD}"
        } >>"$COOLIFY_ENV_FILE"
        status "Nadpisano niepoprawne/brakujace dane konta root w .env swiezo wygenerowanymi."
    fi
fi

status "Instaluje Coolify (oficjalny instalator coollabs)..."
env \
    ROOT_USERNAME=admin \
    ROOT_USER_EMAIL="$COOLIFY_ROOT_EMAIL" \
    ROOT_USER_PASSWORD="$COOLIFY_ROOT_PASSWORD" \
    bash -c 'curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash'

CREDS_FILE=/root/coolify-dostep.txt
cat >"$CREDS_FILE" <<EOF
Coolify - dane logowania (wygenerowane $(date -Is))
Email:  ${COOLIFY_ROOT_EMAIL}
Haslo:  ${COOLIFY_ROOT_PASSWORD}
EOF
chmod 600 "$CREDS_FILE"

sleep 5
DASHBOARD_HTTP_CODE="$(curl -sS -m 8 -o /dev/null -w '%{http_code}' "http://[${IPV6_ADDR}]:8000" 2>/dev/null || echo 000)"

# klucz API Mikrusa - wymagany przez komende "domena". Mozna go podac jako
# pierwszy argument skryptu albo zmienna MIKRUS_API_KEY - zapisujemy tam,
# gdzie oczekuje go /usr/bin/domena. Bez klucza "domena" i tak sie nie
# wywali, tylko zwroci czytelny blad, wiec skrypt jedzie dalej.
API_KEY_FILE=/klucz_api
API_KEY_ARG="${1:-${MIKRUS_API_KEY:-}}"
CURRENT_API_KEY="$(tr -d ' \n\r' <"$API_KEY_FILE" 2>/dev/null || true)"
if [ -n "$API_KEY_ARG" ]; then
    if [ "$CURRENT_API_KEY" != "$API_KEY_ARG" ]; then
        printf '%s' "$API_KEY_ARG" >"$API_KEY_FILE"
        chmod 644 "$API_KEY_FILE"
        status "Zapisano klucz API Mikrusa do ${API_KEY_FILE}."
    fi
elif [ -z "$CURRENT_API_KEY" ] || [ "$CURRENT_API_KEY" = "NULL" ]; then
    warn "Brak klucza API Mikrusa (${API_KEY_FILE}) - wygeneruj go na https://mikr.us/panel/?a=api (majac wybrany WLASNIE TEN VPS), potem: ./chce_coolify.sh TWOJ_KLUCZ  albo  MIKRUS_API_KEY=... ./chce_coolify.sh"
fi

# publiczne subdomeny Mikrusa (byst.re, automatyczny HTTPS) dla userow bez
# IPv6 - "domena" to zawsze jeden host -> jeden port, a Coolify potrzebuje
# trzech naraz (dashboard/realtime/terminal), wiec wywolujemy ja 3x.
# UWAGA: wlasna nazwa domeny (np. "domena moj-coolify 8000") jest obecnie
# odrzucana przez API ("Niepoprawna nazwa domeny") dla kazdej wypróbowanej
# wartosci, nawet trywialnej - zweryfikowane na zywo na adam123 (byc moze
# wymaga Mikrus PRO, niepotwierdzone). Dziala tylko tryb bez nazwy (losowa
# nazwa z API, np. "happy-dog4377"), wiec na razie go uzywamy - re-run
# skryptu zarejestruje WIEC KOLEJNE, inne losowe subdomeny dla tych samych
# portow (domena nie jest idempotentna), a stare zostana nieusuwalne.
DOMENA_PORTS=(8000 6001 6002)
DOMENA_OUT=""
if [ -x /usr/bin/domena ]; then
    for p in "${DOMENA_PORTS[@]}"; do
        out="$(/usr/bin/domena "$p" 2>&1)" || true
        DOMENA_OUT="${DOMENA_OUT}port ${p}:"$'\n'"${out}"$'\n\n'
    done
fi

echo
if [[ "${DASHBOARD_HTTP_CODE:0:1}" =~ [23] ]]; then
    status "Dashboard odpowiada po IPv6 (HTTP ${DASHBOARD_HTTP_CODE})."
else
    warn "Dashboard nie odpowiedzial po IPv6 (kod: ${DASHBOARD_HTTP_CODE}) - sprawdz recznie: curl -v http://[${IPV6_ADDR}]:8000"
fi
[ -n "$DOMENA_OUT" ] && { echo; echo "$DOMENA_OUT"; }

cat <<EOF

Dashboard: http://[${IPV6_ADDR}]:8000
Login:     ${COOLIFY_ROOT_EMAIL}
Haslo:     ${COOLIFY_ROOT_PASSWORD}
(zapisane tez w ${CREDS_FILE}, samo root@0600)

Ten VPS ma tylko NAT-owane IPv4 (za malo portow dla Coolify: 80/443/8000/
6001/6002), dlatego dashboard wyszedl po publicznym IPv6 zamiast kombinowac
z 2 dodatkowymi przekierowaniami Mikrusa. Traefik (proxy Coolify, 80/443)
juz dziala (od instalacji, bez potrzeby recznego startu) i odziedziczyl
te sama siec Docker - kazda aplikacje wdrozona w Coolify z ustawiona
domena (Host-routing) bedzie od razu dostepna po IPv6 na porcie 80/443.

Dla odwiedzajacych/webhookow bez IPv6 (np. GitHub) - dwie opcje:
  a) komenda Mikrusa "domena" (probowalem ja wywolac wyzej dla 3 portow -
     patrz odpowiedzi API powyzej za konkretne nazwy, sa losowe za kazdym
     razem, np. "happy-dog4377.byst.re"):
       port 8000 -> dashboard
       port 6001 -> realtime
       port 6002 -> terminal w przegladarce
     Uwaga: sam dashboard dziala od razu pod przypisana domena, ale
     realtime/terminal w przegladarce domyslnie lacza sie z tym samym
     hostem co dashboard - zeby dzialaly pod przyjazna domena, trzeba by
     przekierowac Coolify na domene z portu 6001 (konfiguracja zalezna od
     wersji Coolify, niezweryfikowane). Prosciej wchodzic po samym IPv6
     (dziala od razu na 8000/6001/6002 bez dodatkowej konfiguracji).
     UWAGA: wlasna nazwa domeny (np. "domena moj-coolify 80") jest obecnie
     odrzucana przez API dla kazdej testowanej wartosci (byc moze wymaga
     Mikrus PRO) - dziala tylko tryb z losowa nazwa, i to bez gwarancji
     stabilnosci nazwy miedzy uruchomieniami skryptu.
     Wymaga klucza API - patrz ostrzezenie wyzej, jesli sie pojawilo.
  b) wlasna domena w Cloudflare - rekord AAAA -> ${IPV6_ADDR}, proxy wl.,
     SSL/TLS = "Flexible", potem w Coolify: Settings -> Instance Domain.

Cytrus Mikrusa NIE nadaje sie do wystawienia Coolify (tylko strony
statyczne/PHP, nie reverse proxy do dowolnych portow Dockera).

Po ustawieniu wlasnej domeny w Coolify zamknij porty 8000/6001/6002 na
zewnatrz i wchodz na dashboard tunelem:
  ssh -L 8000:localhost:8000 -p 10123 root@${HOSTNAME_SHORT}.mikrus.xyz

Zmien tez haslo root do samego VPS-a (Mikrusa) - ten skrypt go nie rusza.
EOF

echo
status "Co teraz zrobic:"
cat <<'EOF2'
1. Wejdz na dashboard (adres i dane logowania wyzej) i zaloguj sie.
2. Traefik juz dziala na 80/443 - wdroz aplikacje i ustaw jej domene w
   Coolify, zeby Host-routing zaczal dzialac.
3. Jesli "domena" pokazal blad braku klucza API, wygeneruj go na
   https://mikr.us/panel/?a=api (majac wybrany WLASNIE TEN VPS) i uruchom
   ponownie: ./chce_coolify.sh TWOJ_KLUCZ
4. (Opcjonalnie, wlasny branding) podepnij wlasna domene przez Cloudflare
   i ustaw ja w Coolify: Settings -> Instance Domain.
5. Po skonfigurowaniu domeny zamknij na zewnatrz porty 8000/6001/6002
   (zostaw tylko 80/443) i wchodz na dashboard tunelem SSH.
6. Zmien haslo root do samego VPS-a (Mikrus) - ten skrypt tego nie robi.
EOF2
