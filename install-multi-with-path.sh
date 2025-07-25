#!/bin/bash

# Multi-Project Laravel Claude Code Setup Installer with PATH fix
# This wrapper ensures claude command is found

set -e

# Add claude to PATH
export PATH="$PATH:/Users/william/.claude/local"

# Colors for output
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Laravel Multi-Project Claude Code Setup (with PATH fix)${NC}"
echo "========================================================"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Run the actual multi-project installer
bash "$SCRIPT_DIR/install-multi.sh" "$@"