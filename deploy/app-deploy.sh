#!/usr/bin/env bash
# =============================================================================
# Authors      : Alex Agbey
# script name  : app-deploy.sh
# usage       : ./app-deploy.sh <tag>
# Description  : Production Deployment Pipeline with Rollback & Health Verification --- IGNORE ---
# ============================================================================= 

set -euo pipefail

# --- Configuration & Styling ---
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOG_FILE="deployments.log"
APP_URL="http://shortlink.example.com/health" # Change to your actual app URL

[[ $# -ne 1 ]] && { echo -e "${RED}Usage: $0 <v1.0.0>${NC}"; exit 1; }

TAG="$1"
DOCKER_USER="${DOCKERHUB_USERNAME:-alexagbey}"
IMAGE="${DOCKER_USER}/shortlink-api:${TAG}"
NAMESPACE='shortlink'
DEPLOYMENT='shortlink-api'

log() { 
    local msg="[DEPLOY $(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo -e "${CYAN}${msg}${NC}"
    echo "$msg" >> "$LOG_FILE"
}

error_exit() {
    echo -e "${RED}[ERROR] $*${NC}" | tee -a "$LOG_FILE"
    exit 1
}

# --- Pipeline Steps ---

# 1. Environment Guard
log "Stage 1: Validation"
bash "$(dirname "$0")/env-check.sh" || error_exit "Environment check failed."

# 2. Container Build
log "Stage 2: Building $IMAGE"
docker build -t "$IMAGE" . || error_exit "Build failed."

# 3. Registry Push
log "Stage 3: Pushing to Registry"
docker push "$IMAGE" || error_exit "Push failed. Check docker login."

# 4. Kubernetes Orchestration
log "Stage 4: Updating K8s Cluster"
kubectl set image deployment/"$DEPLOYMENT" "${DEPLOYMENT}=${IMAGE}" -n "$NAMESPACE"

# 5. Rollout Monitoring & Automatic Rollback
log "Stage 5: Monitoring Rollout (120s timeout)..."
if ! kubectl rollout status deployment/"$DEPLOYMENT" -n "$NAMESPACE" --timeout=120s; then
    log "${RED}Rollout timed out! Initiating Rollback...${NC}"
    kubectl rollout undo deployment/"$DEPLOYMENT" -n "$NAMESPACE"
    error_exit "Deployment failed and was rolled back."
fi

# 6. Post-Deployment Health Check (The "Gold Standard" Step)
log "Stage 6: Verifying Application Health..."
sleep 5 # Give the load balancer a second to catch up
if curl -s --head "$APP_URL" | grep "200" > /dev/null; then
    log "${GREEN}Application is responding correctly!${NC}"
else
    log "${YELLOW}Warning: Deployment succeeded but Health Check failed. Manual review required.${NC}"
fi

echo -e "\n${GREEN}🚀 DEPLOYMENT SUCCESSFUL: $IMAGE${NC}"