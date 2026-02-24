#!/bin/bash
# ~/dotfiles/core.sh

# Get the real user even when running with sudo
export REAL_USER=${SUDO_USER:-$USER}
export REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# Centralized Paths
export DOTFILES_DIR="$REAL_HOME/dotfiles"
export SCRIPTS_DIR="$DOTFILES_DIR/scripts"
export LOG_DIR="$DOTFILES_DIR/logs"
export SS_DIR="$REAL_HOME/Pictures/Screenshots"
export SDKMAN_DIR="$REAL_HOME/.sdkman"

# Common UI Colors
export BLUE='\033[1;34m'
export GREEN='\033[1;32m'
export RED='\033[1;31m'
export PURPLE='\033[1;35m'
export NC='\033[0m'
