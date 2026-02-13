#!/bin/bash
# 00-core.sh - Shared variables and environment setup

# Export Global Variables
export DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export GREEN='\033[0;32m'
export BLUE='\033[0;34m'
export YELLOW='\033[1;33m'
export RED='\033[0;31m'
export CYAN='\033[0;36m'
export NC='\033[0m'

# Add any other shared constants here
export LOG_DIR="$DOTFILES_DIR/logs"
