#!/bin/bash
# 01-system.sh - Preparation and Dependency Installation

set -e # Ensure any uncontrolled error triggers the failure trap in setup.sh

# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_DIR/../core.sh" || { source "$CORE_DIR/core.sh" 2>/dev/null || exit 1; }

log_info "📁 Preparing system infrastructure and installing dependencies..."

# 1. Infrastructure Setup
# Create necessary log directories for operational tracking
log_info "Initializing log structure..."
mkdir -p "$LOG_DIR"/{updates,maintenance,storage}
log_debug "Log directories verified at $LOG_DIR"

# Create cargo environment placeholder to prevent shell initialization errors
if [ ! -d "$REAL_HOME/.cargo" ]; then
    mkdir -p "$REAL_HOME/.cargo"
    touch "$REAL_HOME/.cargo/env"
    chown -R "$REAL_USER":"$REAL_USER" "$REAL_HOME/.cargo"
    log_debug "Cargo environment placeholder created for $REAL_USER"
fi

# 2. Comprehensive Dependency List
# Curated for Backend Engineering, DevOps, and Modern CLI workflows
DEPENDENCIES=(
    # --- Core & Build Tools ---
    base-devel git docker docker-compose rustup util-linux perl
    unzip zip gnupg pinentry
    # --- Modern CLI Tools ---
    eza bat fzf ripgrep fastfetch fd jq tldr starship zoxide handlr lsof
    # --- Shell Enhancements ---
    zsh zsh-autosuggestions zsh-syntax-highlighting
    # --- Multimedia & UI ---
    tesseract-data-eng tesseract-data-tur
    alacritty drawing zathura zathura-pdf-mupdf mpv yt-dlp libnotify
    # --- System Tools ---
    smartmontools pacman-contrib
    # --- Fonts & UI Elements ---
    ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols-common noto-fonts-emoji
)

# 3. Package Installation Loop
log_info "📦 Synchronizing system packages..."

for pkg in "${DEPENDENCIES[@]}"; do
    if pacman -Qi "$pkg" &> /dev/null; then
        log_debug "✅ $pkg is already satisfied."
    else
        log_info "📥 Installing package: $pkg..."
        sudo pacman -S --noconfirm "$pkg" || {
            log_error "❌ Critical failure: Failed to install $pkg."
            exit 1 # This will be caught by setup.sh's trap
        }
    fi
done

log_info "✅ System dependencies synchronization finished successfully."
