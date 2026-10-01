#!/usr/bin/env bash

# ==============================================================================
# Skriptnamn:     secure_network_check.sh
# Beskrivning:    Automatiserat verktyg för nätverks- och systemobservationer.
# Säkerhetsgräns: Alla kontroller utförs enbart mot localhost, lokal gateway och
#                 säkra/godkända domäner. Ingen extern portskanning utförs.
# Författare:     Philip Kwarteng (ITSX26)
# ==============================================================================

# --- Variabler ---
LOG_DIR="./logs"
LOG_FILE="${LOG_DIR}/network_check_$(date +'%Y%m%d_%H%M%S').log"
TEMP_PORT=8080
TEST_DOMAIN="google.com"
PYTHON_PID=""

# Räknare för slutsammanfattning
PASSED_CHECKS=0
FAILED_CHECKS=0

# --- Skapa loggkatalog ---
mkdir -p "${LOG_DIR}"

# --- Funktioner ---

# Loggningsfunktion (Formattering & Filutskrift)
log_message() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp="$(date +'%Y-%m-%d %H:%M:%S')"
    
    # Skriv till loggfil utan färgkodessekvenser
    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_FILE}"

    # Skriv till terminal med färger
    case "${level}" in
        "INFO")  echo -e "\e[34m[INFO]\e[0m ${message}" ;;
        "OK")    echo -e "\e[32m[OK]\e[0m ${message}" ;;
        "WARN")  echo -e "\e[33m[WARN]\e[0m ${message}" ;;
        "FAIL")  echo -e "\e[31m[FAIL]\e[0m ${message}" ;;
        *)       echo "[${level}] ${message}" ;;
    esac
}

# Cleanup-funktion för fällor (trap) och avslutning
cleanup() {
    log_message "INFO" "Rensar temporära resurser och processer..."
    if [ -n "${PYTHON_PID}" ] && kill -0 "${PYTHON_PID}" 2>/dev/null; then
        kill "${PYTHON_PID}" 2>/dev/null
        log_message "OK" "Stoppade den temporära testwebbservern (PID: ${PYTHON_PID})."
    fi
}
trap cleanup EXIT INT TERM

# Kontroll 1: Miljööversikt
check_environment() {
    log_message "INFO" "--- Startar Kontroll 1: Miljööversikt ---"
    
    local ip_info
    local default_route
    
    ip_info="$(hostname -I 2>/dev/null || ip address show | grep 'inet ' | awk '{print $2}')"
    default_route="$(ip route show | grep default | awk '{print $3}')"

    if [ -n "${ip_info}" ]; then
        log_message "OK" "Lokala adresser identifierade: ${ip_info}"
        ((PASSED_CHECKS++))
    else
        log_message "FAIL" "Kunde inte identifiera lokala IP-adresser."
        ((FAILED_CHECKS++))
    fi

    if [ -n "${default_route}" ]; then
        log_message "OK" "Default route identifierad via gateway: ${default_route}"
        ((PASSED_CHECKS++))
    else
        log_message "WARN" "Ingen default route hittades (kan vara förväntat i isolerade miljöer)."
        ((FAILED_CHECKS++))
    fi
}

# Kontroll 2: DNS-uppslag
check_dns() {
    local domain="$1"
    log_message "INFO" "--- Startar Kontroll 2: DNS-kontroll för '${domain}' ---"

    if [ -z "${domain}" ]; then
        log_message "FAIL" "DNS-kontroll misslyckades: Domännamn saknas (tom indata)."
        ((FAILED_CHECKS++))
        return 1
    fi

    if getent hosts "${domain}" >/dev/null 2>&1; then
        local resolved_ip
        resolved_ip="$(getent hosts "${domain}" | awk '{print $1}' | head -n 1)"
        log_message "OK" "DNS-uppslag lyckades för ${domain} -> ${resolved_ip}"
        ((PASSED_CHECKS++))
    else
        log_message "WARN" "DNS-uppslag misslyckades för '${domain}'."
        ((FAILED_CHECKS++))
    fi
}

# Kontroll 3: Lokal tjänstekontroll (med temporär HTTP-server)
check_local_service() {
    log_message "INFO" "--- Startar Kontroll 3: Lokal tjänstekontroll ---"

    # Starta temporär HTTP-server i bakgrunden
    if command -v python3 >/dev/null 2>&1; then
        python3 -m http.server "${TEMP_PORT}" --bind 127.0.0.1 >/dev/null 2>&1 &
        PYTHON_PID=$!
        sleep 1 # Ge servern tid att starta
    else
        log_message "WARN" "Python3 saknas. Kan inte starta automatisk testserver."
    fi

    # Testa anslutning med curl
    if curl -s --connect-timeout 2 "http://127.0.0.1:${TEMP_PORT}" >/dev/null; then
        log_message "OK" "Lokal testtjänst svarar korrekt på port ${TEMP_PORT}."
        ((PASSED_CHECKS++))
    else
        log_message "FAIL" "Ingen tjänst svarade på localhost:${TEMP_PORT}."
        ((FAILED_CHECKS++))
    fi
}

# Kontroll 4: Portöversikt (Loop över säkra portar)
check_ports() {
    log_message "INFO" "--- Startar Kontroll 4: Portöversikt ---"
    
    local ports_to_check=(22 80 443 "${TEMP_PORT}")
    
    log_message "INFO" "Skannar lokalt lyssnande portar med ss..."
    local listening_ports
    listening_ports="$(ss -tuln 2>/dev/null)"

    for port in "${ports_to_check[@]}"; do
        if echo "${listening_ports}" | grep -q ":${port} "; then
            log_message "OK" "Port ${port} är ÖPPEN och lyssnar."
            ((PASSED_CHECKS++))
        else
            log_message "INFO" "Port ${port} är STÄNGD / lyssnar inte."
        fi
    done
}

# Slutsammanfattning
show_summary() {
    log_message "INFO" "=========================================="
    log_message "INFO" "SLUTSAMMANFATTNING"
    log_message "INFO" "Kontroller som lyckades (OK): ${PASSED_CHECKS}"
    log_message "INFO" "Kontroller som misslyckades/varnade: ${FAILED_CHECKS}"
    log_message "INFO" "Fullständig logg finns sparad i: ${LOG_FILE}"
    log_message "INFO" "=========================================="
}

# --- Huvudprogram (Execution Flow) ---
main() {
    log_message "INFO" "Startar Secure Network Check v1.0..."
    
    check_environment
    check_dns "${TEST_DOMAIN}"
    check_local_service
    check_ports
    
    # Test av felhantering (Tom variabel)
    check_dns ""

    show_summary

    if [ "${FAILED_CHECKS}" -gt 0 ]; then
        exit 1
    fi
    exit 0
}

main "$@"