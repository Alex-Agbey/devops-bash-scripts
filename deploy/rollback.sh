#!/usr/bin/env bash
# =============================================================================
# Authors      : Alex Agbey
# script name  : rollback.sh
# usage       : ./rollback.sh <deployment_name> <namespace> [revision_number]
# Description  : Kubernetes Rollback Utility with Safety Checks & Post-Rollback Validation --- IGNORE ---
# ============================================================================= 

set -euo pipefail

# --- UI Styling ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Validation ---
if [[ $# -lt 2 ]]; then
    echo -e "${RED}Usage: $0 <deployment_name> <namespace> [revision_number]${NC}"
    echo -e "${YELLOW}Example: $0 shortlink-api shortlink 5${NC}"
    exit 1
fi

DEPLOY="$1"
NS="$2"
REVISION="${3:-}" # Optional: Roll back to a specific version if provided

log() { echo -e "${BLUE}[ROLLBACK]${NC} $*"; }

# 1. Check if Deployment Exists
if ! kubectl get deployment "$DEPLOY" -n "$NS" &>/dev/null; then
    echo -e "${RED}Error: Deployment '$DEPLOY' not found in namespace '$NS'.${NC}"
    exit 1
fi

echo -e "${YELLOW}=== Deployment History for $DEPLOY ===${NC}"
kubectl rollout history deployment/"$DEPLOY" -n "$NS"
echo "------------------------------------------------"

# 2. Safety Confirmation
read -p "Are you sure you want to proceed with the rollback? (y/n): " confirm
if [[ $confirm != [yY] ]]; then
    echo -e "${RED}Rollback cancelled by user.${NC}"
    exit 0
fi

# 3. Execution
if [[ -n "$REVISION" ]]; then
    log "Rolling back $DEPLOY to revision $REVISION..."
    kubectl rollout undo deployment/"$DEPLOY" -n "$NS" --to-revision="$REVISION"
else
    log "Rolling back $DEPLOY to the immediate previous version..."
    kubectl rollout undo deployment/"$DEPLOY" -n "$NS"
fi

# 4. Verification
log "Waiting for pods to stabilize (120s timeout)..."
if kubectl rollout status deployment/"$DEPLOY" -n "$NS" --timeout=120s; then
    echo -e "\n${GREEN}✅ SUCCESS: Rollback complete.${NC}"
else
    echo -e "\n${RED}❌ CRITICAL: Rollback failed or timed out! Check pod events.${NC}"
    kubectl get events -n "$NS" --sort-by='.lastTimestamp' | tail -n 5
    exit 1
fi

# 5. Final Snapshot
echo -e "\n${YELLOW}=== Current Pod Status ===${NC}"
kubectl get pods -n "$NS" -l app="$DEPLOY" || kubectl get pods -n "$NS" | grep "$DEPLOY"