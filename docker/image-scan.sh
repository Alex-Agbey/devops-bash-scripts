#!/usr/bin/env bash

# =============================================================================
# Script Name : image-scan.sh
# Author      : Alex Agbey
# Description : Trivy -Security auditing for Docker images (DevSecOps)
# Usage       : ./image-scan.sh <image_name> - Scans the specified Docker image for vulnerabilities using Trivy, with a focus on High and Critical issues. Generates a JSON report for CI/CD pipelines.
# Example     : ./image-scan.sh myapp:latest - Scans the 'myapp:latest' image and outputs results to the terminal and a JSON report.
# =============================================================================

set -euo pipefail

# --- Configuration ---
IMAGE="$1"
REPORT_DIR="./security-reports"
mkdir -p "$REPORT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Validation
if [[ $# -ne 1 ]]; then
    echo -e "${RED}Usage: $0 <image_name:tag>${NC}"
    exit 1
fi

# 2. Trivy Check/Install
if ! command -v trivy &>/dev/null; then
    echo -e "${YELLOW}[INFO] Trivy not found. Installing now...${NC}"
    # Use sudo for /usr/local/bin if not root
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin v0.48.3
fi

echo -e "${YELLOW}🔍 Scanning Image: $IMAGE${NC}"

# 3. Execution
# We run it twice: 
# Once for a pretty table in the terminal
trivy image --severity HIGH,CRITICAL --no-progress "$IMAGE"

# Capturing the status specifically for the pipeline exit
if trivy image --severity HIGH,CRITICAL --exit-code 1 --no-progress --format json --output "${REPORT_DIR}/scan-$(date +%F).json" "$IMAGE"; then
    echo -e "\n${GREEN}✔ Security Audit Passed! No High/Critical vulnerabilities.${NC}"
    exit 0
else
    echo -e "\n${RED}✘ Security Audit Failed! Critical vulnerabilities detected.${NC}"
    echo -e "${YELLOW}Detailed report saved to: ${REPORT_DIR}${NC}"
    exit 1
fi