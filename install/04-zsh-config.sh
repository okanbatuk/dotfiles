#!/bin/bash
# 04-zsh-config.sh - Managing Zsh sourcing for multiple config files and functions
# Ensures that all modular config files and functions are properly sourced in .zshrc.

set -e # Exit on any error to trigger the setup.sh failure trap

# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_DIR/../core.sh" || { source "$CORE_DIR/core.sh" 2>/dev/null || exit 1; }

echo -e "${CYAN}Running task with DOTFILES_DIR: $DOTFILES_DIR${NC}"
echo -e "${YELLOW}🐚 Updating .zshrc configuration for $REAL_USER...${NC}"

ZSHRC="$REAL_HOME/.zshrc"

# Check if .zshrc exists (either as a file or a valid symlink)
if [ ! -f "$ZSHRC" ]; then
    echo -e "${RED}❌ Critical Error: .zshrc not found at $ZSHRC.${NC}"
    echo -e "${YELLOW}💡 Ensure 03-links.sh has run correctly before this script.${NC}"
    exit 1
fi

# 1. List of files to be sourced in .zshrc
FILES_TO_SOURCE=(.zsh_aliases .zsh_notes)

for file in "${FILES_TO_SOURCE[@]}"; do
    # Check if the source line already exists using a more precise regex
    if ! grep -q "source.*$file" "$ZSHRC"; then
        echo -e "  ➕ Adding source line for $file to .zshrc"
        # Append the source command. We use $HOME for portability inside .zshrc
        echo -e "\n# Load $file\n[[ -f \$HOME/$file ]] && source \$HOME/$file" >> "$ZSHRC"
        echo -e "  ${GREEN}✅ $file source added.${NC}"
    else
        echo -e "  ${GREEN}✅ $file is already sourced in .zshrc${NC}"
    fi
done

# 2. Inject Dynamic Functions Loader
# Automatically sources every standalone function file in ~/.zsh_functions.d
if ! grep -q ".zsh_functions.d" "$ZSHRC"; then
    echo -e "  ➕ Adding dynamic function loader to .zshrc"

    # Using a single-quoted EOF to prevent local variable expansion
    cat <<'EOF' >> "$ZSHRC"

# Load modular functions from .zsh_functions.d
if [ -d "$HOME/.zsh_functions.d" ]; then
    for func in "$HOME/.zsh_functions.d"/*; do
        [ -f "$func" ] && source "$func"
    done
fi
EOF
    echo -e "  ${GREEN}✅ Dynamic function loader added.${NC}"
else
    echo -e "  ${GREEN}✅ Function loader is already present in .zshrc${NC}"
fi

# 3. Final Permissions Check
# Since setup.sh runs as root, ensure .zshrc ownership is preserved
chown "$REAL_USER:$REAL_USER" "$ZSHRC"

echo -e "${GREEN}✅ Zsh configuration update finished.${NC}"
