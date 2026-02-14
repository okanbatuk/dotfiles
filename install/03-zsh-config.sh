#!/bin/bash
# 03-zsh-config.sh - Managing Zsh sourcing for multiple config files and functions
source "$(dirname "$0")/00-core.sh"

echo -e "${CYAN}Running task with DOTFILES_DIR: $DOTFILES_DIR${NC}"
echo -e "${YELLOW}🐚 Updating .zshrc configuration...${NC}"
ZSHRC="$HOME/.zshrc"

# 1. List of files to be sourced in .zshrc
# Add any new config files here (e.g., .zshenv, .zsh_plugins)
FILES_TO_SOURCE=(.zsh_aliases .zshenv)

for file in "${FILES_TO_SOURCE[@]}"; do
    # Check if the source line already exists to avoid duplicates
    if ! grep -q "source.*$file" "$ZSHRC"; then
        echo -e "  ➕ Adding source line for $file to .zshrc"
        # Append the source command with a check if the file exists
        echo -e "\n# Load $file\n[[ -f ~/$file ]] && source ~/$file" >> "$ZSHRC"
        echo -e "  ${GREEN}✅ $file source added.${NC}"
    else
        echo -e "  ${GREEN}✅ $file is already sourced in .zshrc${NC}"
    fi
done

# 2. Inject Dynamic Functions Loader
# Automatically sources every standalone function file in ~/.zsh_functions.d
if ! grep -q ".zsh_functions.d" "$ZSHRC"; then
    echo -e "  ➕ Adding dynamic function loader to .zshrc"
    cat <<'EOF' >> "$ZSHRC"

# Load modular functions from .zsh_functions.d
if [ -d ~/.zsh_functions.d ]; then
    for func in ~/.zsh_functions.d/*; do
        [ -f "$func" ] && source "$func"
    done
fi
EOF
    echo -e "  ${GREEN}✅ Dynamic function loader added.${NC}"
else
    echo -e "  ${GREEN}✅ Function loader is already present in .zshrc${NC}"
fi
