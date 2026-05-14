#!/usr/bin/env bash

# =============================================================================
# Script Name : namespace-cleanup.sh
# Author      : Alex Agbey
# Description : Deep-clean of a K8s namespace including non-standard resources
# Usage       : ./namespace-cleanup.sh <namespace>
# =============================================================================

set -euo pipefail

# --- UI Colours ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 1. Input Validation
if [[ $# -ne 1 ]]; then
    echo -e "${RED}Usage: $0 <namespace>${NC}"
    exit 1
fi

NS="$1"

# 2. Production Safety Firewall
# We add 'kube-public' and 'kube-node-lease' to the protected list
PROTECTED=("kube-system" "default" "kube-public" "kube-node-lease")

for P in "${PROTECTED[@]}"; do
    if [[ "$NS" == "$P" ]]; then
        echo -e "${RED}CRITICAL ERROR: '${NS}' is a protected system namespace! Action blocked.${NC}"
        exit 1
    fi
done

# 3. Double-Confirmation
echo -e "${RED}🛑 WARNING: This will permanently destroy ALL resources in [${NS}].${NC}"
echo -e "${YELLOW}This includes Deployments, Services, Secrets, ConfigMaps, and Persistent Storage.${NC}"
read -rp "To continue, type the namespace name exactly [$NS]: " CONFIRM

if [[ "$CONFIRM" != "$NS" ]]; then
    echo -e "${CYAN}Aborted. No changes made.${NC}"
    exit 1
fi

echo -e "\n${CYAN}🚀 Commencing Deep Clean of: $NS...${NC}"

# 4. The Deep Clean Phase
# 'delete all' only hits Pods, Services, Deployments, etc. 
# It MISSES ConfigMaps, Secrets, Ingresses, and PVCs.
resources=(
    "all"
    "ingress"
    "pvc"
    "configmap"
    "secret"
    "rolebindings"
    "roles"
    "serviceaccounts"
)

for res in "${resources[@]}"; do
    echo -e "${YELLOW}Cleaning ${res}s...${NC}"
    kubectl delete "$res" --all -n "$NS" --wait=false 2>/dev/null || true
done

# 5. Handling "Stuck" Resources (Finalizers)
# Sometimes pods get stuck in 'Terminating' state forever.
echo -e "${YELLOW}Force-clearing any stuck 'Terminating' pods...${NC}"
kubectl delete pods -n "$NS" --all --force --grace-period=0 2>/dev/null || true

echo -e "\n${GREEN}✔ Namespace cleanup command issued for: $NS${NC}"
echo -e "${CYAN}[TIP] Run 'kubectl get all -n $NS' to verify everything is gone.${NC}"