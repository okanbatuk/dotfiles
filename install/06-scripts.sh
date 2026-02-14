#!/bin/bash
# 06-scripts.sh - Linking and preparing custom automation scripts
source "$(dirname "$0")/00-core.sh"

echo -e "${CYAN}Running task with DOTFILES_DIR: $DOTFILES_DIR${NC}"
echo -e "${YELLOW}📜 Linking automation scripts to ~/scripts...${NC}"

# Create the target directory if it doesn't exist
mkdir -p "$HOME/scripts"

# Iterate through all shell scripts in the dotfiles/scripts directory
if [ -d "$DOTFILES_DIR/scripts" ]; then
    for script_path in "$DOTFILES_DIR/scripts"/*.sh; do
        if [ -f "$script_path" ]; then
            # Extract filename from path
            script_name=$(basename "$script_path")

            # Create symlink in ~/scripts
            ln -sf "$script_path" "$HOME/scripts/.$script_name"

            # Ensure the source script is executable
            chmod +x "$script_path"

            echo -e "  ${GREEN}✅ Linked and set executable: $script_name${NC}"
        fi
    done
else
    echo -e "  ${CYAN}💡 No scripts directory found in $DOTFILES_DIR/scripts. Skipping.${NC}"
fi
