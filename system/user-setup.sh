#!/usr/bin/env bash

# =============================================================================
# Script Name : user-setup.sh
# Author      : Alex Agbey
# Description : Securely provision a new user with SSH access
# Usage       : sudo ./user-setup.sh <username> "<public_key>" [--sudo]- Creates a new user, sets up SSH key-based authentication, and optionally grants sudo access.
# example     : sudo ./user-setup.sh alex "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..." --sudo - Creates user 'alex' with the provided SSH key and grants sudo privileges.
# =============================================================================

set -euo pipefail

# --- Configuration ---
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# 1. Root Check
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root (sudo).${NC}"
   exit 1
fi

# 2. Argument Validation
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <username> <ssh_public_key> [--sudo]"
    exit 1
fi

USERNAME="$1"
SSH_KEY="$2"
# Use a more flexible way to check for the sudo flag
HAS_SUDO_FLAG=$(echo "$*" | grep -c "\-\-sudo" || true)

# 3. User Creation
if id "$USERNAME" &>/dev/null; then
    echo -e "${GREEN}[INFO] User $USERNAME already exists.${NC}"
else
    useradd -m -s /bin/bash "$USERNAME"
    echo -e "${GREEN}[PASS] Created user: $USERNAME${NC}"
fi

# 4. Secure SSH Setup
SSH_DIR="/home/${USERNAME}/.ssh"
AUTH_FILE="${SSH_DIR}/authorized_keys"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Check if the key is already there to prevent duplicates
if grep -qF "$SSH_KEY" "$AUTH_FILE" 2>/dev/null; then
    echo -e "${GREEN}[INFO] SSH key already exists in $AUTH_FILE${NC}"
else
    echo "$SSH_KEY" >> "$AUTH_FILE"
    echo -e "${GREEN}[PASS] SSH key added for $USERNAME${NC}"
fi

chmod 600 "$AUTH_FILE"
chown -R "${USERNAME}:${USERNAME}" "$SSH_DIR"

# 5. Sudo Access (Platform-Agnostic)
if [[ $HAS_SUDO_FLAG -eq 1 ]]; then
    # Check if 'sudo' group exists, otherwise use 'wheel'
    SUDO_GROUP="sudo"
    grep -q "^sudo:" /etc/group || SUDO_GROUP="wheel"
    
    usermod -aG "$SUDO_GROUP" "$USERNAME"
    echo -e "${GREEN}[PASS] Sudo access granted via group: $SUDO_GROUP${NC}"
fi

echo -e "\n${GREEN}Setup complete for $USERNAME.${NC}"