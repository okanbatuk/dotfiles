#!/bin/bash
# ~/dotfiles/core.sh
# Shared environment variables, global constants, and helper functions.
# This file acts as the "Source of Truth" for all automation scripts.

# --- User & Directory Context ---
# These are also defined in .zshenv for the shell,
# but redefined here to ensure scripts work when run independently.
export REAL_USER=${SUDO_USER:-$USER}
export REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
export DOTFILES_DIR="$REAL_HOME/dotfiles"

# --- Centralized Paths ---
export SCRIPTS_DIR="$DOTFILES_DIR/scripts"
export LOG_DIR="$DOTFILES_DIR/logs"
export SS_DIR="$REAL_HOME/Pictures/Screenshots"

# --- Helper Functions ---

# run_as_user: Executes commands as the non-root user even from a sudo context.
# Essential for FNM, Bun, and AUR (yay) installations to prevent root pollution.
run_as_user() {
    sudo -i -u "$REAL_USER" "$@"
}

# --- Common UI Colors ---
# Used for consistent and readable terminal output across all scripts.
export BLUE='\033[1;34m'
export GREEN='\033[1;32m'
export YELLOW='\033[1;33m'
export RED='\033[0;31m'
export CYAN='\033[0;36m'
export PURPLE='\033[1;35m'
export NC='\033[0m' # No Color (Reset)
