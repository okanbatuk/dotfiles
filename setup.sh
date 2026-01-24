#!/bin/bash
# setup.sh - Dotfiles bootstrap script
# Usage: ./setup.sh

set -e

DOTFILES_DIR="$HOME/dotfiles"

echo "🔧 Setting up dotfiles..."

# ----------------------------
# Shell and Git configurations
# ----------------------------
for file in .zshrc .zsh_aliases .zshenv .gitconfig; do
  if [ -e "$HOME/$file" ]; then
    echo "Backing up existing $file to $file.bak"
    mv "$HOME/$file" "$HOME/$file.bak"
  fi
  ln -sf "$DOTFILES_DIR/$file" "$HOME/$file"
done

# ----------------------------
# Espanso configuration
# ----------------------------
if [ -d "$DOTFILES_DIR/config/espanso" ]; then
  mkdir -p "$HOME/.config"
  if [ -e "$HOME/.config/espanso" ]; then
    mv "$HOME/.config/espanso" "$HOME/.config/espanso.bak"
  fi
  ln -sf "$DOTFILES_DIR/config/espanso" "$HOME/.config/espanso"
fi

# ----------------------------
# Zed config (external repo)
# ----------------------------
ZED_REPO_URL="https://github.com/okanbatuk/zed-config.git"
ZED_TARGET="$DOTFILES_DIR/external/zed-config"
ZED_CONFIG_DIR="$HOME/.config/zed"

if [ ! -d "$ZED_TARGET" ]; then
  echo "📥 Cloning Zed config repository..."
  mkdir -p "$DOTFILES_DIR/external"
  git clone "$ZED_REPO_URL" "$ZED_TARGET"
else
  echo "✅ Zed config already exists."
fi

if [ -e "$ZED_CONFIG_DIR" ]; then
  mv "$ZED_CONFIG_DIR" "$ZED_CONFIG_DIR.bak"
fi
ln -sf "$ZED_TARGET" "$ZED_CONFIG_DIR"

echo "✅ Dotfiles setup complete!"
echo "💡 Open a new terminal or run 'source ~/.zshrc' to apply changes."
