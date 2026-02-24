#!/bin/bash
# 06-scripts.sh - Linking and preparing custom automation scripts
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
echo -e "${YELLOW}📜 Linking automation scripts to $REAL_HOME/scripts...${NC}"

# Create the target directory if it doesn't exist
mkdir -p "$REAL_HOME/scripts"

# Iterate through all shell scripts in the dotfiles/scripts directory
if [ -d "$DOTFILES_DIR/scripts" ]; then
    for script_path in "$DOTFILES_DIR/scripts"/*.sh; do
        if [ -f "$script_path" ]; then
            # Extract filename from path
            script_name=$(basename "$script_path")

            # Create symlink in ~/scripts
            ln -sf "$script_path" "$REAL_HOME/scripts/.$script_name"

            # Ensure the source script is executable
            chmod +x "$script_path"

            echo -e "  ${GREEN}✅ Linked and set executable: $script_name${NC}"
        fi
    done
else
    echo -e "  ${CYAN}💡 No scripts directory found in $DOTFILES_DIR/scripts. Skipping.${NC}"
fi
