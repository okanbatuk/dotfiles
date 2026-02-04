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
# Shell and Git configurations
# ----------------------------
echo -e "${YELLOW}📂 Linking Home directory configs...${NC}"
for file in .zshrc .zsh_aliases .zsh_functions .zshenv .gitconfig; do
  if [ -e "$HOME/$file" ]; then
    echo -e "  🔄 Backing up existing $file to $file.bak"
    mv "$HOME/$file" "$HOME/$file.bak"
  fi
  ln -sf "$DOTFILES_DIR/$file" "$HOME/$file"
  echo -e "  ${GREEN}✅ Linked $file${NC}"
done

echo -e "${BLUE}----------------------------------------${NC}"

# ----------------------------
# Config Directory Apps (Espanso, Alacritty, Neovim)
# ----------------------------
echo -e "${YELLOW}⚙️  Linking App configurations...${NC}"
mkdir -p "$HOME/.config"
for app in espanso alacritty nvim; do
  if [ -d "$DOTFILES_DIR/config/$app" ]; then
    if [ -e "$HOME/.config/$app" ] && [ ! -L "$HOME/.config/$app" ]; then
      echo -e "  🔄 Backing up existing config for $app"
      mv "$HOME/.config/$app" "$HOME/.config/$app.bak"
    fi
    ln -sf "$DOTFILES_DIR/config/$app" "$HOME/.config/$app"
    echo -e "  ${GREEN}✅ Linked config for $app${NC}"
  fi
done

echo -e "${BLUE}----------------------------------------${NC}"

# ----------------------------
# Zed config (external repo)
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
