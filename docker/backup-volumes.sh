#!/usr/bin/env bash

# =============================================================================
# Script Name : backup-volumes.sh
# Author      : Alex Agbey
# Description : Containerized backup of Docker volumes with retention
# Usage       : ./backup-volumes.sh [volume_name] - Backs up specified volume or all volumes if no argument is given, with automatic cleanup of old backups.
# example     : ./backup-volumes.sh mydata - Backs up the 'mydata' volume to a timestamped archive in the user's home directory under 'docker-backups'.
# =============================================================================

set -euo pipefail

# --- Configuration ---
BACKUP_DIR="${HOME}/docker-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7  # Keep backups for 1 week
GREEN='\033[0;32m' 
CYAN='\033[0;36m' 
RED='\033[0;31m'
NC='\033[0m'

mkdir -p "$BACKUP_DIR"

backup_volume() {
    local vol="$1"
    local out_file="${vol}_${TIMESTAMP}.tar.gz"
    
    echo -e " ${CYAN}📦 Processing: $vol${NC}"
    
    # Run helper container to tar the data
    if docker run --rm \
        -v "${vol}:/data:ro" \
        -v "${BACKUP_DIR}:/backup" \
        alpine tar czf "/backup/${out_file}" -C /data . ; then
        
        echo -e " ${GREEN}✔ Success: ${out_file}${NC}"
    else
        echo -e " ${RED}✘ Failed to backup: $vol${NC}"
        return 1
    fi
}

# --- Execution ---

if [[ $# -eq 1 ]]; then
    backup_volume "$1"
else
    echo -e "${CYAN}Starting full backup of all volumes...${NC}"
    # Filter out 'tmpfs' or local drivers if necessary
    for vol in $(docker volume ls --format '{{.Name}}'); do
        backup_volume "$vol"
    done
fi

# --- Retention: The SRE Touch ---
echo -e "\n${CYAN}Cleaning up backups older than ${RETENTION_DAYS} days...${NC}"
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +"$RETENTION_DAYS" -delete

echo -e "\n${GREEN}Final Backup Inventory (${BACKUP_DIR}):${NC}"
ls -lh "$BACKUP_DIR"