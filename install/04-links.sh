#!/bin/bash
# 03-links.sh - Linking core configs and application settings
# Ensures configuration files are symlinked to the correct home directory.

set -e # Exit on any error to trigger the setup.sh failure trap

# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_DIR/../core.sh" || { source "$CORE_DIR/core.sh" 2>/dev/null || exit 1; }

log_info "📂 Linking core configurations for user: $REAL_USER"

# 1. Core shell and git configuration files
CORE_FILES=(.zshrc .zsh_aliases .zshenv .gitconfig .zsh_notes)

for file in "${CORE_FILES[@]}"; do
    # Check if the file exists and is NOT a symbolic link already
    if [ -e "$REAL_HOME/$file" ] && [ ! -L "$REAL_HOME/$file" ]; then
        log_debug " 🔄 Backing up existing $file to $file.bak"
        mv "$REAL_HOME/$file" "$REAL_HOME/$file.bak"
    fi

    # Create the symlink
    ln -sf "$DOTFILES_DIR/$file" "$REAL_HOME/$file"

    # Ensure the link ownership belongs to the real user, not root
    chown -h "$REAL_USER:$REAL_USER" "$REAL_HOME/$file"
    log_debug "✅ Linked: $file"
done

# 2. Modular Zsh Functions Directory
# Linking the entire functions folder for dynamic zsh loading
ln -sfn "$DOTFILES_DIR/functions" "$REAL_HOME/.zsh_functions.d"
chown -h "$REAL_USER:$REAL_USER" "$REAL_HOME/.zsh_functions.d"
log_debug "✅ Linked functions directory to ~/.zsh_functions.d"

# 3. Application specific configurations (~/.config)
log_info "⚙️ Synchronizing application settings in .config..."

# Ensure .config exists and is owned by the user
if [ ! -d "$REAL_HOME/.config" ]; then
    mkdir -p "$REAL_HOME/.config"
    chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.config"
fi

APPS=(espanso alacritty nvim zathura mpv biome)

for app in "${APPS[@]}"; do
    if [ -d "$DOTFILES_DIR/config/$app" ]; then
        # Handle existing real directories by backing them up
        if [ -d "$REAL_HOME/.config/$app" ] && [ ! -L "$REAL_HOME/.config/$app" ]; then
            log_debug "🔄 Backing up existing config for $app"
            mv "$REAL_HOME/.config/$app" "$REAL_HOME/.config/$app.bak"
        fi

        # Ensure fresh link by removing existing link/file
        rm -rf "$REAL_HOME/.config/$app"

        ln -sfn "$DOTFILES_DIR/config/$app" "$REAL_HOME/.config/$app"
        # Crucial: Ensure the symlink itself is owned by the user
        chown -h "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/$app"
        log_debug "✅ Linked config for: $app"
    fi
done

log_info "✅ Symlinking process finished successfully."
