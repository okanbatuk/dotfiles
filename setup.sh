#!/bin/bash
# setup.sh - Dotfiles bootstrap script
# Usage: ./setup.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

DOTFILES_DIR="$HOME/dotfiles"

echo -e "${CYAN}🚀 Setting up dotfiles...${NC}"
echo -e "${BLUE}----------------------------------------${NC}"

# ----------------------------
# 1. Log Directory Preparation
# ----------------------------
echo -e "${YELLOW}📁 Creating log directories...${NC}"
mkdir -p "$DOTFILES_DIR/logs"/{updates,maintenance,storage}
echo -e "  ${GREEN}✅ Log structure ready${NC}"

echo -e "${BLUE}----------------------------------------${NC}"

# ----------------------------
# 2. Shell and Git configurations
# ----------------------------
echo -e "${YELLOW}📂 Linking Home directory configs...${NC}"

# Symlinks core shell and git configs to the user's home directory
for file in .zshrc .zsh_aliases .zsh_functions .zshenv .gitconfig; do
  if [ -e "$HOME/$file" ]; then
    echo -e "  🔄 Backing up existing $file to $file.bak"
    mv "$HOME/$file" "$HOME/$file.bak"
  fi
  ln -sf "$DOTFILES_DIR/$file" "$HOME/$file"
  echo -e "  ${GREEN}✅ Linked $file${NC}"
done

# ----------------------------
# 3. Zsh Source Check
# ----------------------------
echo -e "${YELLOW}🔗 Checking Zsh source links...${NC}"
ZSHRC="$HOME/.zshrc"
declare -A SOURCE_FILES=(
    [".zsh_aliases"]="[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases"
    [".zsh_functions"]="[[ -f ~/.zsh_functions ]] && source ~/.zsh_functions"
)

# Ensures .zshrc is actually sourcing the alias and function files
for file in "${!SOURCE_FILES[@]}"; do
    if ! grep -q "$file" "$ZSHRC"; then
        echo -e "  ➕ Adding source line for $file to .zshrc"
        echo -e "\n# Load $file\n${SOURCE_FILES[$file]}" >> "$ZSHRC"
    else
        echo -e "  ${GREEN}✅ $file is already sourced in .zshrc${NC}"
    fi
done

echo -e "${BLUE}----------------------------------------${NC}"

# ----------------------------
# 4. Scripts linking (Automation)
# ----------------------------
echo -e "${YELLOW}📜 Linking automation scripts...${NC}"
mkdir -p "$HOME/scripts"

# Links custom scripts to ~/scripts and ensures they are executable
for script in "$DOTFILES_DIR/scripts"/*.sh; do
  if [ -f "$script" ]; then
    script_name=$(basename "$script")
    ln -sf "$script" "$HOME/scripts/$script_name"
    chmod +x "$script"
    echo -e "  ${GREEN}✅ Linked and set executable: $script_name${NC}"
  fi
done

echo -e "${BLUE}----------------------------------------${NC}"

# ----------------------------
# 5. Dependency Check
# ----------------------------
echo -e "${YELLOW}🔍 Checking dependencies...${NC}"
DEPENDENCIES=(alacritty zathura zathura-pdf-mupdf mpv yt-dlp eza fd fzf smartmontools pacman-contrib)

# Checks for required packages and installs them if missing
for pkg in "${DEPENDENCIES[@]}"; do
    if ! pacman -Qs "$pkg" > /dev/null; then
        echo -e "  ${CYAN}📦 Installing $pkg...${NC}"
        sudo pacman -S --noconfirm "$pkg"
    else
        echo -e "  ${GREEN}✅ $pkg is already installed.${NC}"
    fi
done

# ----------------------------
# 6. Config Directory Apps (Espanso, Alacritty, Neovim, Zathura, Mpv)
# ----------------------------
echo -e "${YELLOW}⚙️  Linking App configurations...${NC}"
mkdir -p "$HOME/.config"

# Links app-specific settings (Alacritty, MPV, Nvim, etc.) to ~/.config
for app in espanso alacritty nvim zathura mpv; do
  if [ -d "$DOTFILES_DIR/config/$app" ]; then
    if [ -e "$HOME/.config/$app" ] && [ ! -L "$HOME/.config/$app" ]; then
      echo -e "  🔄 Backing up existing config for $app"
      rm -rf "$HOME/.config/$app.bak" # Remove old backup if exists
      mv "$HOME/.config/$app" "$HOME/.config/$app.bak"
    fi

    # Remove existing symlink if it exists to ensure a fresh link
    if [ -L "$HOME/.config/$app" ]; then
      rm "$HOME/.config/$app"
    fi

    ln -sf "$DOTFILES_DIR/config/$app" "$HOME/.config/$app"
    echo -e "  ${GREEN}✅ Linked config for $app${NC}"
  fi
done

echo -e "${BLUE}----------------------------------------${NC}"

# ----------------------------
# 7. Zed config (external repo)
# ----------------------------
ZED_REPO_URL="https://github.com/okanbatuk/zed-config.git"
ZED_TARGET="$DOTFILES_DIR/external/zed-config"
ZED_CONFIG_DIR="$HOME/.config/zed"

echo -e "${YELLOW}📝 Setting up Zed editor...${NC}"
if [ ! -d "$ZED_TARGET" ]; then
  echo -e "  📥 ${CYAN}Cloning Zed config repository...${NC}"
  mkdir -p "$DOTFILES_DIR/external"
  git clone "$ZED_REPO_URL" "$ZED_TARGET"
else
  echo -e "  ${GREEN}✅ Zed config already exists.${NC}"
fi

if [ -e "$ZED_CONFIG_DIR" ]; then
  mv "$ZED_CONFIG_DIR" "$ZED_CONFIG_DIR.bak"
fi
ln -sf "$ZED_TARGET" "$ZED_CONFIG_DIR"

echo -e "${BLUE}----------------------------------------${NC}"
echo -e "${GREEN}✨ Dotfiles setup complete!${NC}"
echo -e "${CYAN}💡 Open a new terminal or run 'source ~/.zshrc' to apply changes.${NC}"
