#!/bin/bash
# 01-system.sh - Preparation and Dependency Installation
# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_ENV="$CORE_DIR/../core.sh"

if [ -f "$CORE_ENV" ]; then
    source "$CORE_ENV"
else
    # Fallback to current dir if not in scripts/
    source "$CORE_DIR/core.sh" 2>/dev/null || { echo "Error: core.sh not found"; exit 1; }
fi

echo -e "${CYAN}Running task with DOTFILES_DIR: $DOTFILES_DIR${NC}"
echo -e "${YELLOW}📁 Preparing system and installing dependencies...${NC}"

# 1. Create necessary log directories
# Used for tracking updates, maintenance tasks, and storage logs
# Note: $DOTFILES_DIR is inherited from the main setup.sh
mkdir -p "$DOTFILES_DIR/logs"/{updates,maintenance,storage}
echo -e "  ${GREEN}✅ Log structure ready${NC}"

# Create cargo env file to prevent Zsh errors during first setup
mkdir -p "$REAL_HOME/.cargo"
touch "$REAL_HOME/.cargo/env"

# 2. Comprehensive Dependency List
# Categorized for better maintainability
DEPENDENCIES=(
    # --- Core & Build Tools ---
    base-devel git docker docker-compose rustup util-linux perl
    unzip zip
    # --- Modern CLI Tools ---
    eza bat fzf ripgrep
    fastfetch
    fd jq tldr starship zoxide handlr
    # --- Shell Enhancements ---
    zsh zsh-autosuggestions zsh-syntax-highlighting
    # --- Editors ---
    neovim zed
    # --- Multimedia & UI ---
    tesseract-data-eng
    tesseract-data-tur
    alacritty drawing zathura zathura-pdf-mupdf mpv yt-dlp
    # --- System Tools ---
    smartmontools pacman-contrib
    # --- Fonts & UI Elements ---
    ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols-common noto-fonts-emoji
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
