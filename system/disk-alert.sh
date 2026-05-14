#!/usr/bin/env bash

# =============================================================================
# Script Name : disk-alert.sh
# Description : Production-grade disk monitoring (CI/CD + SRE ready)
# Author      : Alex Agbey
# Usage       : ./disk-alert.sh- Checks disk usage against a threshold and sends alerts via Slack and email.
# example     : ./disk-alert.sh - Executes a disk usage check, logs results in JSON format, and sends alerts if usage exceeds 80%.
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

readonly THRESHOLD="${DISK_THRESHOLD:-80}"
readonly ALERT_LOG="${HOME}/disk-alert.log"
readonly METRICS_FILE="${HOME}/disk-metrics.prom"

# Alert channels
readonly SLACK_WEBHOOK="${SLACK_WEBHOOK_URL:-}"
readonly ADMIN_EMAIL="${ADMIN_EMAIL:-your-email@example.com}"

# =============================================================================
# UI COLORS (TTY only)
# =============================================================================

if [[ -t 1 ]]; then
    readonly RED='\033[0;31m'
    readonly YELLOW='\033[1;33m'
    readonly GREEN='\033[0;32m'
    readonly NC='\033[0m'
else
    readonly RED='' YELLOW='' GREEN='' NC=''
fi

# =============================================================================
# LOGGING (JSON format)
# =============================================================================

log_json() {
    local level="$1"
    local message="$2"

    printf '{"timestamp":"%s","level":"%s","message":"%s"}\n' \
        "$(date '+%Y-%m-%dT%H:%M:%S')" "$level" "$message" >> "$ALERT_LOG"
}

# =============================================================================
# ALERTING
# =============================================================================

send_slack_alert() {
    local message="$1"

    if [[ -n "$SLACK_WEBHOOK" ]]; then
        curl -s -X POST "$SLACK_WEBHOOK" \
            -H 'Content-type: application/json' \
            --data "{\"text\":\"🚨 $message\"}" > /dev/null
    fi
}

send_email_alert() {
    local message="$1"

    if command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "🚨 Disk Alert on $(hostname)" "$ADMIN_EMAIL"
    else
        log_json "WARN" "mail command not found. Email alert skipped."
    fi
}

send_alert() {
    local message="$1"

    send_slack_alert "$message"
    send_email_alert "$message"
}

# =============================================================================
# METRICS EXPORT (Prometheus)
# =============================================================================

write_metric() {
    local mount="$1"
    local usage="$2"

    local safe_mount
    safe_mount=$(echo "$mount" | sed 's/[^a-zA-Z0-9]/_/g')

    echo "disk_usage_percent{mount=\"$safe_mount\"} $usage" >> "$METRICS_FILE"
}

# =============================================================================
# CORE FUNCTION
# =============================================================================

check_disk() {
    local alert_count=0

    echo -e "${YELLOW}=== Disk Usage Check (Threshold: ${THRESHOLD}%) ===${NC}"

    : > "$METRICS_FILE"

    while IFS= read -r line; do
        local device usage mount

        device=$(awk '{print $1}' <<< "$line")
        usage=$(awk '{print $2}' <<< "$line" | tr -d '%')
        mount=$(awk '{print $3}' <<< "$line")

        write_metric "$mount" "$usage"

        if (( usage >= THRESHOLD )); then
            local msg="Disk ${device} mounted on ${mount} is at ${usage}%"

            echo -e " ${RED}[FAIL]${NC} $msg"

            log_json "ERROR" "$msg"
            send_alert "$msg"

            ((alert_count++))
        else
            echo -e " ${GREEN}[PASS]${NC} ${mount}: ${usage}%"
        fi

    done < <(df -h --output=source,pcent,target | tail -n +2)

    return "$alert_count"
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    touch "$ALERT_LOG"

    if check_disk; then
        echo -e "\n${GREEN}✔ All disks are healthy.${NC}"
        log_json "INFO" "All disks within threshold"
        exit 0
    else
        local failed_count=$?

        local msg="CRITICAL: ${failed_count} disk(s) exceeded ${THRESHOLD}%"

        echo -e "\n${RED}✘ $msg${NC}"
        echo -e "${YELLOW}Logs: ${ALERT_LOG}${NC}"

        log_json "CRITICAL" "$msg"
        send_alert "$msg"

        exit 1
    fi
}

main "$@"