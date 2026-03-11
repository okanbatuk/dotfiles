#!/bin/bash
# 03-links.sh - Linking core configs and application settings
# Ensures configuration files are symlinked to the correct home directory.

set -e # Exit on any error to trigger the setup.sh failure trap

# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_DIR/../core.sh" || { source "$CORE_DIR/core.sh" 2>/dev/null || exit 1; }

echo -e "${CYAN}Running task with DOTFILES_DIR: $DOTFILES_DIR${NC}"
echo -e "${YELLOW}📂 Linking Home directory configs for user: $REAL_USER...${NC}"

# 1. Core shell and git configuration files
CORE_FILES=(.zshrc .zsh_aliases .zshenv .gitconfig .zsh_notes)

for file in "${CORE_FILES[@]}"; do
    # Check if the file exists and is NOT a symbolic link already
    if [ -e "$REAL_HOME/$file" ] && [ ! -L "$REAL_HOME/$file" ]; then
        echo -e "  🔄 Backing up existing $file to $file.bak"
        mv "$REAL_HOME/$file" "$REAL_HOME/$file.bak"
    fi

    # Create the symlink
    ln -sf "$DOTFILES_DIR/$file" "$REAL_HOME/$file"

    # Ensure the link ownership belongs to the real user, not root
    chown -h "$REAL_USER:$REAL_USER" "$REAL_HOME/$file"
    echo -e "  ${GREEN}✅ Linked $file${NC}"
done

# 2. Modular functions folder
# Using -n to treat existing link to directory as a normal file
ln -sfn "$DOTFILES_DIR/functions" "$REAL_HOME/.zsh_functions.d"
chown -h "$REAL_USER:$REAL_USER" "$REAL_HOME/.zsh_functions.d"
echo -e "  ${GREEN}✅ Linked functions folder to $REAL_HOME/.zsh_functions.d${NC}"

# 3. Application specific configurations (~/.config)
echo -e "${YELLOW}⚙️  Linking App configurations...${NC}"
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
            echo -e "  🔄 Backing up existing config for $app"
            mv "$REAL_HOME/.config/$app" "$REAL_HOME/.config/$app.bak"
        fi

        # Ensure fresh link by removing existing link/file
        rm -rf "$REAL_HOME/.config/$app"

        ln -sfn "$DOTFILES_DIR/config/$app" "$REAL_HOME/.config/$app"
        # Crucial: Ensure the symlink itself is owned by the user
        chown -h "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/$app"
        echo -e "  ${GREEN}✅ Linked config for $app${NC}"
    fi
done

echo -e "${GREEN}✅ Symlinking finished successfully.${NC}"
