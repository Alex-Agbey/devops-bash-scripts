#!/usr/bin/env bash

# =============================================================================
# Script Name : rolling-restart.sh
# Author      : Alex Agbey
# Description : Zero-downtime restart with status tracking
# Usage       : ./rolling-restart.sh <deployment_name> <namespace>
# =============================================================================

set -euo pipefail

# --- UI Colours ---
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Input Validation
if [[ $# -ne 2 ]]; then
    echo -e "${RED}Usage: $0 <deployment_name> <namespace>${NC}"
    exit 1
fi

DEPLOY="$1"
NS="$2"

# 2. Pre-Flight Check: Does the deployment exist?
if ! kubectl get deployment "$DEPLOY" -n "$NS" &>/dev/null; then
    echo -e "${RED}ERROR: Deployment '${DEPLOY}' not found in namespace '${NS}'.${NC}"
    exit 1
fi

echo -e "${CYAN}🚀 Initializing Rolling Restart: ${DEPLOY} [Namespace: ${NS}]${NC}"

# 3. Trigger Restart
kubectl rollout restart deployment/"$DEPLOY" -n "$NS"

# 4. Monitor Status (The SRE way)
echo -e "${CYAN}⏳ Waiting for pods to stabilize (Timeout: 120s)...${NC}"
if kubectl rollout status deployment/"$DEPLOY" -n "$NS" --timeout=120s; then
    echo -e "${GREEN}✔ Rollout Successful! All pods are healthy.${NC}"
else
    echo -e "${RED}✘ ROLLOUT FAILED or TIMED OUT! Immediate investigation required.${NC}"
    echo -e "${CYAN}Check logs: kubectl logs -n $NS -l app=$DEPLOY --tail=20${NC}"
    exit 1
fi

# 5. Final Snapshot
echo -e "\n${CYAN}Current Pod Status:${NC}"
kubectl get pods -n "$NS" -l "app.kubernetes.io/name=$DEPLOY" 2>/dev/null || kubectl get pods -n "$NS" -l "app=$DEPLOY"