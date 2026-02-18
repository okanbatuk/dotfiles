#!/bin/bash
# 01-system.sh - Preparation and Dependency Installation
source "$(dirname "$0")/00-core.sh"

echo -e "${CYAN}Running task with DOTFILES_DIR: $DOTFILES_DIR${NC}"
echo -e "${YELLOW}📁 Preparing system and installing dependencies...${NC}"

# 1. Create necessary log directories
# Used for tracking updates, maintenance tasks, and storage logs
# Note: $DOTFILES_DIR is inherited from the main setup.sh
mkdir -p "$DOTFILES_DIR/logs"/{updates,maintenance,storage}
echo -e "  ${GREEN}✅ Log structure ready${NC}"

# Create cargo env file to prevent Zsh errors during first setup
mkdir -p "$HOME/.cargo"
touch "$HOME/.cargo/env"

# 2. Comprehensive Dependency List
# Categorized for better maintainability
DEPENDENCIES=(
    # --- Core & Build Tools ---
    base-devel          # Essential tools for building/compiling (gcc, make, etc.)
    git                 # Version control system
    docker              # Container engine
    docker-compose      # Multi-container orchestration tool
    rustup              # Rust toolchain installer (Required for Cargo & env files)

    # --- Modern CLI Tools ---
    eza                 # A modern, feature-rich replacement for 'ls'
    bat                 # A 'cat' clone with syntax highlighting and git integration
    fzf                 # Command-line fuzzy finder (required for dckr)
    ripgrep             # 'rg' - Faster and more featureful alternative to grep
    neofetch            # System information tool
    fd                  # A simple, fast and user-friendly alternative to 'find'
    jq                  # Command-line JSON processor
    tldr                # Collaborative cheatsheets for console commands
    starship            # The minimal, blazing-fast, and infinitely customizable prompt
    zoxide              # A smarter cd command for your terminal
    handlr              # A better xdg-utils alternative for managing default apps

    # --- Shell Enhancements ---
    zsh                 # The Z shell
    zsh-autosuggestions # Fish-like autosuggestions for zsh
    zsh-syntax-highlighting # Fish-shell-like syntax highlighting for Zsh

    # --- Editors ---
    neovim              # Core engine for your Neovim configuration
    zed                 # High-performance, multiplayer code editor

    # --- Multimedia & UI ---
    alacritty           # A cross-platform, GPU-accelerated terminal emulator
    drawing             # A simple image editor
    zathura             # A highly customizable and functional document viewer
    zathura-pdf-mupdf   # PDF support for zathura using MuPDF engine
    mpv                 # Media player for the command line
    yt-dlp              # A feature-rich command-line audio/video downloader

    # --- System Tools ---
    smartmontools       # Control and monitor storage systems (S.M.A.R.T.)
    pacman-contrib      # Collection of scripts and tools for pacman (e.g., paccache)

    # --- Fonts & UI Elements ---
    ttf-jetbrains-mono-nerd       # Developer-focused font with icons
    ttf-nerd-fonts-symbols-common # Common symbols for Nerd Font users
    noto-fonts-emoji              # Google Noto emoji fonts
)

# 3. Package Installation Loop
# Checks if each package is already installed via pacman before attempting installation
echo -e "${CYAN}📦 Checking system packages...${NC}"
for pkg in "${DEPENDENCIES[@]}"; do
    if pacman -Qi "$pkg" &> /dev/null; then
        echo -e "${GREEN} ✅ $pkg is already installed. ${NC}"
    else
        echo "📥 Installing $pkg..."
        if sudo pacman -S --noconfirm "$pkg"; then
            echo -e "${GREEN} ✅ Successfully installed $pkg.${NC}"
        else
            echo -e "${RED} ❌ Failed to install $pkg. Please check your connection or mirrors. ${NC}"
        fi
    fi
done

echo -e "${GREEN}✅ System dependencies update finished.${NC}"
