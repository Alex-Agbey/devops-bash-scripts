#!/usr/bin/env bash

# =============================================================================
# Script Name : pod-restarts.sh
# Author      : Alex Agbey
# Description : Monitoring Kubernetes Pod stability (CrashLoop Detection)
# Usage       : ./pod-restarts.sh [namespace] [restart_threshold] - Checks for pods that have restarted more than the specified threshold (default: 5) in the given namespace (or all namespaces if not specified).
# Example     : ./pod-restarts.sh default 10 - Checks the 'default' namespace for pods with 10 or more restarts.
# =============================================================================

set -euo pipefail

# --- Config ---
# If no namespace provided, check all. Default threshold is 5 restarts.
NAMESPACE_ARG=${1:-"--all-namespaces"}
[[ "$NAMESPACE_ARG" != "--all-namespaces" ]] && NAMESPACE_FLAG="-n $NAMESPACE_ARG" || NAMESPACE_FLAG="-A"

THRESHOLD=${2:-5}
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Dependency Check
if ! command -v kubectl &>/dev/null; then
    echo -e "${RED}Error: kubectl not found. Ensure your Kubeconfig is set up.${NC}"
    exit 1
fi

echo -e "${YELLOW}🔍 Auditing Pod Stability (Threshold: ${THRESHOLD} restarts)...${NC}"

# 2. Logic Phase
FOUND_ISSUES=0

# We pull: Namespace($1), Name($2), Status($3), Restarts($5)
while IFS= read -r line; do
    ns=$(echo "$line" | awk '{print $1}')
    pod=$(echo "$line" | awk '{print $2}')
    status=$(echo "$line" | awk '{print $3}')
    restarts=$(echo "$line" | awk '{print $4}')

    if [[ "$restarts" =~ ^[0-9]+$ ]] && (( restarts >= THRESHOLD )); then
        echo -e " ${RED}[CRITICAL]${NC} Pod: ${pod}"
        echo -e "          Namespace: ${ns}"
        echo -e "          Status:    ${status}"
        echo -e "          Restarts:  ${restarts}"
        echo "-----------------------------------"
        ((FOUND_ISSUES++))
    fi
done < <(kubectl get pods $NAMESPACE_FLAG --no-headers | awk '{print $1, $2, $3, $5}')

# 3. Final Report
if (( FOUND_ISSUES == 0 )); then
    echo -e "${GREEN}✔ Cluster is stable. All pods within restart limits.${NC}"
    exit 0
else
    echo -e "\n${RED}✘ Warning: ${FOUND_ISSUES} pod(s) are unstable.${NC}"
    echo -e "${YELLOW}[TIP] Run 'kubectl describe pod <name>' to investigate.${NC}"
    exit 1
fi