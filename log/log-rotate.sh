#!/usr/bin/env bash

# =============================================================================
# Script Name : log-rotate.sh
# Author      : Alex Agbey
# usage       : ./log-rotate.sh [log_directory] [days_old] - Safely rotates logs older than specified days with Gzip compression and retention policy.
# example     : ./log-rotate.sh /var/log/myapp 7 - Rotates logs in /var/log/myapp that are older than 7 days, compresses them, and retains archives for 30 days.
# Description : Safe log rotation with Gzip compression and retention
# =============================================================================

set -euo pipefail

# --- Config ---
LOG_DIR=${1:-'/var/log/myapp'}
DAYS=${2:-7}
ARCHIVE_DIR="${LOG_DIR}/archive"
RETENTION_DAYS=30

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Validation
if [[ ! -d "$LOG_DIR" ]]; then
    echo -e "${YELLOW}Warning: Directory $LOG_DIR does not exist. Skipping...${NC}"
    exit 0
fi

mkdir -p "$ARCHIVE_DIR"

echo -e "${CYAN}🚀 Rotating logs in: $LOG_DIR (Older than $DAYS days)${NC}"

# 2. Rotation Logic
COUNT=0
while IFS= read -r logfile; do
    filename=$(basename "$logfile")
    timestamp=$(date +%Y%m%d_%H%M%S)
    dest="${ARCHIVE_DIR}/${filename}.${timestamp}.gz"
    
    # PRODUCTION SAFETY: Copy then truncate
    # This prevents the app from crashing if it's currently writing to the log
    if gzip -c "$logfile" > "$dest"; then
        cat /dev/null > "$logfile" # This empties the file without deleting it
        echo -e " ${GREEN}✔ Compressed & Reset: $filename${NC}"
        ((COUNT++))
    fi
done < <(find "$LOG_DIR" -maxdepth 1 -name '*.log' -type f -mtime +"$DAYS")

# 3. Retention Policy
echo -e "${CYAN}🧹 Cleaning up archives older than $RETENTION_DAYS days...${NC}"
find "$ARCHIVE_DIR" -name '*.gz' -mtime +"$RETENTION_DAYS" -delete

echo -e "\n${GREEN}Process Complete. $COUNT logs rotated.${NC}"