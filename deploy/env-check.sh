#!/usr/bin/env bash

# =============================================================================
# Script Name : env-check.sh
# Author      : Alex Agbey
# usage       : ./env-check.sh
# Description : Checks for required environment variables before deployment. It validates the presence and format of critical variables, providing clear feedback on any issues found.
# =============================================================================

set -euo pipefail

# --- Configuration ---
ENV_FILE=".env"
REQUIRED_VARS=(
    'DOCKERHUB_USERNAME'
    'IMAGE_NAME'
    'IMAGE_TAG'
    'DATABASE_URL'
    'SECRET_KEY'
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Starting Environment Audit ===${NC}"

# 1. Automatic .env Loading
if [[ -f "$ENV_FILE" ]]; then
    echo -e "${YELLOW}[INFO]${NC} Found $ENV_FILE, loading variables..."
    # Export variables while ignoring comments
    export "$(grep -v '^#' "$ENV_FILE" | xargs)"
fi

MISSING=0

# 2. Advanced Validation Loop
for var in "${REQUIRED_VARS[@]}"; do
    value="${!var:-}"

    if [[ -z "$value" ]]; then
        echo -e " ${RED}[MISSING]${NC} $var"
        ((MISSING++))
    else
        # Custom Logic for Specific Keys
        case "$var" in
            "SECRET_KEY")
                if [[ ${#value} -lt 12 ]]; then
                    echo -e " ${YELLOW}[WEAK]   ${NC} $var is too short (min 12 chars)!"
                    ((MISSING++))
                else
                    echo -e " ${GREEN}[SECURE ]${NC} $var (Length: ${#value})"
                fi
                ;;
            "DATABASE_URL")
                if [[ ! "$value" =~ ^[a-zA-Z]+:// ]]; then
                    echo -e " ${RED}[INVALID]${NC} $var format is incorrect"
                    ((MISSING++))
                else
                    echo -e " ${GREEN}[VALID  ]${NC} $var (Connection string detected)"
                fi
                ;;
            *)
                echo -e " ${GREEN}[SET    ]${NC} $var"
                ;;
        esac
    fi
done

echo "------------------------------------------------"

# 3. Final Verdict
if (( MISSING > 0 )); then
    echo -e "${RED}❌ BOOTSTRAP FAILED: $MISSING issues found.${NC}"
    echo -e "${YELLOW}Please check your environment variables or $ENV_FILE file.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ ENVIRONMENT READY: All checks passed.${NC}"