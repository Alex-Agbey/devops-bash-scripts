#!/usr/bin/env bash

# =============================================================================
# Script Name : image-scan.sh
# Author      : Alex Agbey
# Description : Trivy -Security auditing for Docker images (DevSecOps)
# Usage       : ./image-scan.sh <image_name> - Scans the specified Docker image for vulnerabilities using Trivy, with a focus on High and Critical issues. Generates a JSON report for CI/CD pipelines.
# Example     : ./image-scan.sh myapp:latest - Scans the 'myapp:latest' image and outputs results to the terminal and a JSON report.
# =============================================================================


# Define colors for output
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Ensure variables have defaults to avoid empty string errors
REPORT_DIR="${REPORT_DIR:-./reports}"
IMAGE="${IMAGE:-my-app:latest}"

# 1. Fixed SC2250: Braces around variable references
mkdir -p "${REPORT_DIR}"

# 2. Fixed SC2312: Invoking 'date' separately to avoid masking return values
# This is a key reason why your pipeline was still failing
SCAN_DATE=$(date +%F)
REPORT_FILE="${REPORT_DIR}/scan-${SCAN_DATE}.json"

# 3. Fixed SC2250: Added braces to YELLOW, IMAGE, and NC
echo -e "${YELLOW}🔍 Scanning Image: ${IMAGE}${NC}"

# 4. Fixed SC2250: Braces around IMAGE
trivy image --severity HIGH,CRITICAL --no-progress "${IMAGE}"

# 5. Fixed logic for the IF statement using the pre-defined REPORT_FILE variable
if trivy image --severity HIGH,CRITICAL --exit-code 1 --no-progress --format json --output "${REPORT_FILE}" "${IMAGE}"; then
    echo -e "${GREEN}✅ No critical vulnerabilities found.${NC}"
else
    echo -e "${RED}❌ Vulnerabilities detected! Check ${REPORT_FILE}${NC}"
fi