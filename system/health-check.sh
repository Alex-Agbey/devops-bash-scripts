#!/usr/bin/env bash

# =============================================================================
# Script Name : health-check.sh
# Description : Professional System Health Monitoring Script
# Author      : Alex Agbey
# Usage       : ./health-check.sh- Performs comprehensive health checks on CPU, Memory, Disk, and critical services, with a clean and informative output.
# example     : ./health-check.sh - Executes a health check on the system, reporting CPU, Memory, Disk usage, and service statuses in a clear format with color-coded results.
# =============================================================================

set -euo pipefail

# --- Configuration ---
readonly CPU_THRESHOLD=80
readonly MEM_THRESHOLD=85
readonly DISK_THRESHOLD=80
readonly SERVICES=("docker" "ssh")

# --- Colours ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

log_info() { echo -e "${GREEN}[INFO]${NC} $(date '+%H:%M:%S') $*"; }

check_status() {
    local name="$1" status="$2" value="$3"
    if [[ "$status" == 'ok' ]]; then
        echo -e "  ${GREEN}[PASS]${NC} ${name}: ${value}"
        ((PASS++)) || true
    else
        echo -e "  ${RED}[FAIL]${NC} ${name}: ${value}"
        ((FAIL++)) || true
    fi
}

cleanup() {
    echo -e "\n${YELLOW}--- Summary ---${NC}"
    echo -e "  ${GREEN}Passed: ${PASS}${NC} | ${RED}Failed: ${FAIL}${NC}"
    log_info "Health check completed."
}

main() {
    trap cleanup EXIT
    log_info "Starting Health Check on $(hostname)"
    echo -e "${YELLOW}=============================${NC}"

    # 1. CPU Usage
    local cpu_idle cpu_used
    cpu_idle=$(top -bn1 | grep "Cpu(s)" | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | cut -d. -f1)
    cpu_used=$((100 - cpu_idle))
    if [[ $cpu_used -lt $CPU_THRESHOLD ]]; then
        check_status "CPU" "ok" "${cpu_used}%"
    else
        check_status "CPU" "fail" "${cpu_used}%"
    fi

    # 2. Memory Usage
    local mem_total mem_used mem_pct
    # Use '|| true' to prevent WSL from killing the script on minor 'free' errors
    mem_total=$(free | awk '/^Mem:/ {print $2}' || echo 0)
    mem_used=$(free | awk '/^Mem:/ {print $3}' || echo 0)
    
    if [[ -n "$mem_total" && "$mem_total" -gt 0 ]]; then
        mem_pct=$(( mem_used * 100 / mem_total ))
        if [[ $mem_pct -lt $MEM_THRESHOLD ]]; then
            check_status "Memory" "ok" "${mem_pct}%"
        else
            check_status "Memory" "fail" "${mem_pct}%"
        fi
    else
        check_status "Memory" "fail" "N/A"
    fi

    # 3. Disk Usage
    local disk_line pct mount
    # Only check actual physical disks to avoid WSL system errors
    while read -r disk_line; do
        pct=$(echo "$disk_line" | awk '{print $5}' | tr -d '%')
        mount=$(echo "$disk_line" | awk '{print $6}')
        if [[ $pct -lt $DISK_THRESHOLD ]]; then
            check_status "Disk ($mount)" "ok" "${pct}%"
        else
            check_status "Disk ($mount)" "fail" "${pct}%"
        fi
    done < <(df -h | grep '^/dev/' || true)

    # 4. Services
    local svc
    for svc in "${SERVICES[@]}"; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            check_status "Service ($svc)" "ok" "Running"
        else
            check_status "Service ($svc)" "fail" "Stopped"
        fi
    done

    [[ $FAIL -eq 0 ]] || exit 1
}

main "$@"