#!/bin/bash
# 02-links.sh - Linking core configs and application settings
source "$(dirname "$0")/00-core.sh"

echo -e "${CYAN}Running task with DOTFILES_DIR: $DOTFILES_DIR${NC}"
echo -e "${YELLOW}📂 Linking Home directory configs...${NC}"

# Core shell and git configuration files
CORE_FILES=(.zshrc .zsh_aliases .zshenv .gitconfig)

for file in "${CORE_FILES[@]}"; do
    if [ -e "$HOME/$file" ] && [ ! -L "$HOME/$file" ]; then
        echo -e "  🔄 Backing up existing $file to $file.bak"
        mv "$HOME/$file" "$HOME/$file.bak"
    fi
    ln -sf "$DOTFILES_DIR/$file" "$HOME/$file"
    echo -e "  ${GREEN}✅ Linked $file${NC}"
done

# Link the modular functions folder
ln -sfn "$DOTFILES_DIR/functions" "$HOME/.zsh_functions.d"
echo -e "  ${GREEN}✅ Linked functions folder to ~/.zsh_functions.d${NC}"

# Application specific configurations (~/.config)
echo -e "${YELLOW}⚙️  Linking App configurations...${NC}"
mkdir -p "$HOME/.config"

APPS=(espanso alacritty nvim zathura mpv)

for app in "${APPS[@]}"; do
    if [ -d "$DOTFILES_DIR/config/$app" ]; then
        # Handle existing real directories by backing them up
        if [ -d "$HOME/.config/$app" ] && [ ! -L "$HOME/.config/$app" ]; then
            echo -e "  🔄 Backing up existing config for $app"
            mv "$HOME/.config/$app" "$HOME/.config/$app.bak"
        fi

        # Always remove existing symlink to ensure fresh link
        rm -rf "$HOME/.config/$app"

        ln -sfn "$DOTFILES_DIR/config/$app" "$HOME/.config/$app"
        echo -e "  ${GREEN}✅ Linked config for $app${NC}"
    fi
done

# IdeaVim configuration
echo -e "${YELLOW}⌨️  Linking IdeaVim configuration...${NC}"
if [ -f "$DOTFILES_DIR/config/JetBrains/ideavimrc" ]; then
    ln -sf "$DOTFILES_DIR/config/JetBrains/ideavimrc" "$HOME/.ideavimrc"
    echo -e "  ${GREEN}✅ Linked .ideavimrc${NC}"
else
    echo -e "  ${RED}❌ ideavimrc not found in $DOTFILES_DIR/config/JetBrains/${NC}"
fi
