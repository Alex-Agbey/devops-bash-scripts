#!/usr/bin/env bash

# =============================================================================
# Script Name : docker-cleanup.sh
# Description : Deep clean of Docker resources with space-reclaimed reporting
# Author      : Alex Agbey
# Usage       : ./cleanup.sh- Prunes all unused Docker resources and reports on space reclaimed.
#Removes stopped containers, dangling images, unused volumes, and networks. Shows space recovered before and
# Run this weekly to keep your Docker host clean and efficient.

# example     : ./cleanup.sh - Executes a full Docker cleanup and displays the resource usage before and after.
# =============================================================================

set -euo pipefail

# --- UI Colours ---
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Dependency Check
if ! command -v docker &>/dev/null; then
    echo -e "${RED}Error: Docker is not installed or not in PATH.${NC}"
    exit 1
fi

echo -e "${YELLOW}🚀 Initializing Docker Deep Cleanup...${NC}"

# 2. Capture Storage Stats Before Cleanup
# We use 'docker system df' to get the total reclaimable space
BEFORE_RECLAIMABLE=$(docker system df --format "{{.Reclaimable}}" | awk '{sum+=$1} END {print sum}')

echo -e "${CYAN}Current Docker Resource Usage:${NC}"
docker system df

echo -e "\n${YELLOW}Cleaning up unused resources...${NC}"

# 3. Execution Phase
# 'prune -f' is used to skip interactive prompts in automated environments
docker container prune -f > /dev/null
docker image prune -f > /dev/null
docker volume prune -f > /dev/null
docker network prune -f > /dev/null

# 4. Final Report
echo -e "${GREEN}✔ Cleanup Complete!${NC}"
echo -e "${CYAN}Updated Docker Resource Usage:${NC}"
docker system df

# 5. Logic Check: Did we actually free anything?
AFTER_RECLAIMABLE=$(docker system df --format "{{.Reclaimable}}" | awk '{sum+=$1} END {print sum}')

# Simple comparison for the "Wow" factor in logs
if [[ "$BEFORE_RECLAIMABLE" == "$AFTER_RECLAIMABLE" ]]; then
    echo -e "\n${GREEN}System was already lean. No significant space reclaimed.${NC}"
else
    echo -e "\n${GREEN}🎉 Storage Optimization Successful.${NC}"
fi