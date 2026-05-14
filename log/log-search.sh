#!/usr/bin/env bash

# =============================================================================
# Script Name : log-search.sh
# Description : Deep-search through plain and compressed logs with context
# Author      : Alex Agbey
# Usage       : ./log-search.sh <pattern> <dir> <context_lines>
# =============================================================================

set -euo pipefail

# --- Config ---
PATTERN=${1:-'ERROR'}
LOG_DIR=${2:-'/var/log'}
CONTEXT=${3:-3}

RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 1. Validation
if [[ ! -d "$LOG_DIR" ]]; then
    echo -e "${RED}Error: Directory $LOG_DIR not found.${NC}"
    exit 1
fi

echo -e "${YELLOW}🔍 Searching for: '${PATTERN}' in ${LOG_DIR}${NC}"
echo -e "${CYAN}Note: Searching both .log and .gz files modified in the last 24h${NC}\n"

# 2. Execution
TOTAL_MATCHES=0

# Use 'find' to get files modified in the last 24 hours to save time
while IFS= read -r logfile; do
    
    # Determine if we use 'grep' or 'zgrep' (for compressed files)
    SEARCH_CMD="grep"
    [[ "$logfile" == *.gz ]] && SEARCH_CMD="zgrep"

    # Count matches first (case-insensitive -i)
    count=$($SEARCH_CMD -i -c "$PATTERN" "$logfile" 2>/dev/null || true)

    if [[ -n "$count" ]] && (( count > 0 )); then
        echo -e "${RED}📂 File: $logfile ($count matches)${NC}"
        echo "----------------------------------------------------"
        # Print matches with line numbers (-n) and context (-C)
        $SEARCH_CMD -i -n -C "$CONTEXT" "$PATTERN" "$logfile" || true
        echo -e "----------------------------------------------------\n"
        ((TOTAL_MATCHES += count))
    fi

done < <(find "$LOG_DIR" -type f \( -name "*.log" -o -name "*.gz" \) -mtime -1 -readable)

# 3. Summary
if (( TOTAL_MATCHES == 0 )); then
    echo -e "${CYAN}No matches found for '${PATTERN}'.${NC}"
else
    echo -e "${YELLOW}✅ Search Complete. Total matches: $TOTAL_MATCHES${NC}"
fi