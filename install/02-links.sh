#!/bin/bash
# 02-links.sh - Linking core configs and application settings
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
echo -e "${YELLOW}📂 Linking Home directory configs for user: $REAL_USER...${NC}"

# Core shell and git configuration files
CORE_FILES=(.zshrc .zsh_aliases .zshenv .gitconfig .zsh_notes)

for file in "${CORE_FILES[@]}"; do
    if [ -e "$REAL_HOME/$file" ] && [ ! -L "$REAL_HOME/$file" ]; then
        echo -e "  🔄 Backing up existing $file to $file.bak"
        mv "$REAL_HOME/$file" "$REAL_HOME/$file.bak"
    fi
    ln -sf "$DOTFILES_DIR/$file" "$REAL_HOME/$file"
    echo -e "  ${GREEN}✅ Linked $file${NC}"
done

# Link the modular functions folder
ln -sfn "$DOTFILES_DIR/functions" "$REAL_HOME/.zsh_functions.d"
echo -e "  ${GREEN}✅ Linked functions folder to $REAL_HOME/.zsh_functions.d${NC}"

# Application specific configurations (~/.config)
echo -e "${YELLOW}⚙️  Linking App configurations...${NC}"
mkdir -p "$REAL_HOME/.config"

APPS=(espanso alacritty nvim zathura mpv biome)

for app in "${APPS[@]}"; do
    if [ -d "$DOTFILES_DIR/config/$app" ]; then
        # Handle existing real directories by backing them up
        if [ -d "$REAL_HOME/.config/$app" ] && [ ! -L "$REAL_HOME/.config/$app" ]; then
            echo -e "  🔄 Backing up existing config for $app"
            mv "$REAL_HOME/.config/$app" "$REAL_HOME/$file.config/$app.bak"
        fi

        # Always remove existing symlink to ensure fresh link
        rm -rf "$REAL_HOME/.config/$app"

        ln -sfn "$DOTFILES_DIR/config/$app" "$REAL_HOME/.config/$app"
        echo -e "  ${GREEN}✅ Linked config for $app${NC}"
    fi
done

# IdeaVim configuration
echo -e "${YELLOW}⌨️  Linking IdeaVim configuration...${NC}"
if [ -f "$DOTFILES_DIR/config/JetBrains/ideavimrc" ]; then
    ln -sf "$DOTFILES_DIR/config/JetBrains/ideavimrc" "$REAL_HOME/.ideavimrc"
    echo -e "  ${GREEN}✅ Linked .ideavimrc${NC}"
else
    echo -e "  ${RED}❌ ideavimrc not found in $DOTFILES_DIR/config/JetBrains/${NC}"
fi
