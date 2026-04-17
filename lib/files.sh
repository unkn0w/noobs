#!/bin/bash
# Operacje na plikach i archiwach - noobs_lib modul
[[ -n "${_NOOBS_FILES_LOADED:-}" ]] && return 0
readonly _NOOBS_FILES_LOADED=1

# Uzycie: download_file <url> <output_path> [use_curl]
download_file() {
    local url="$1"
    local output="$2"
    local use_curl="${3:-false}"

    [[ -z "$url" ]] && { msg_error "Nie podano URL do pobrania."; return 1; }
    [[ -z "$output" ]] && { msg_error "Nie podano sciezki wyjsciowej."; return 1; }

    msg_info "Pobieranie: $url"

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

# Uzycie: extract_archive <archive_path> <output_dir> [strip_components]
extract_archive() {
    local archive="$1"
    local output_dir="$2"
    local strip="${3:-0}"

    [[ -z "$archive" ]] && { msg_error "Nie podano sciezki archiwum."; return 1; }
    [[ ! -f "$archive" ]] && { msg_error "Plik nie istnieje: $archive"; return 1; }
    [[ -z "$output_dir" ]] && { msg_error "Nie podano katalogu wyjsciowego."; return 1; }

    msg_info "Rozpakowywanie: $archive -> $output_dir"

    mkdir -p "$output_dir"

    local archive_type
    archive_type=$(detect_archive_type "$archive")

    case "$archive_type" in
        tar.gz)  tar -xzf "$archive" -C "$output_dir" --strip-components="$strip" ;;
        tar.bz2) tar -xjf "$archive" -C "$output_dir" --strip-components="$strip" ;;
        tar.xz)  tar -xJf "$archive" -C "$output_dir" --strip-components="$strip" ;;
        tar)     tar -xf  "$archive" -C "$output_dir" --strip-components="$strip" ;;
        zip)
            command_exists unzip || { msg_error "Brak unzip. Zainstaluj: pkg_install unzip"; return 1; }
            unzip -q "$archive" -d "$output_dir"
            ;;
        7z)
            command_exists 7z || { msg_error "Brak 7z. Zainstaluj: pkg_install p7zip-full"; return 1; }
            7z x "$archive" -o"$output_dir" -y >/dev/null
            ;;
        *)
            msg_error "Nieobslugiwany format archiwum: $archive"
            return 1
            ;;
    esac

    if [[ $? -eq 0 ]]; then
        msg_ok "Rozpakowano do: $output_dir"
    else
        msg_error "Blad podczas rozpakowywania archiwum."
        return 1
    fi
}

# Uzycie: download_and_extract <url> <output_dir> [strip_components] [cleanup]
download_and_extract() {
    local url="$1"
    local output_dir="$2"
    local strip="${3:-0}"
    local cleanup="${4:-true}"

    [[ -z "$url" ]] && { msg_error "Nie podano URL."; return 1; }
    [[ -z "$output_dir" ]] && { msg_error "Nie podano katalogu wyjsciowego."; return 1; }

    local filename
    filename=$(basename "$url" | sed 's/?.*//')
    local temp_file="/tmp/${filename}"

    download_file "$url" "$temp_file" || return 1

    extract_archive "$temp_file" "$output_dir" "$strip" || {
        rm -f "$temp_file"
        return 1
    }

    if [[ "$cleanup" == "true" ]]; then
        rm -f "$temp_file"
        msg_debug "Usunieto plik tymczasowy: $temp_file"
    fi
}
