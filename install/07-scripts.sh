#!/bin/bash
# 07-scripts.sh - Linking and preparing custom automation scripts
# Links local automation tools to ~/scripts and ensures they are executable.

set -e # Exit immediately if a command fails to trigger setup.sh trap

# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_DIR/../core.sh" || { source "$CORE_DIR/core.sh" 2>/dev/null || exit 1; }

echo -e "${CYAN}Running task with DOTFILES_DIR: $DOTFILES_DIR${NC}"
echo -e "${YELLOW}📜 Linking automation scripts to $REAL_HOME/scripts...${NC}"

# 1. Target Directory Preparation
# Ensure the scripts directory exists and is owned by the real user
if [ ! -d "$REAL_HOME/scripts" ]; then
    run_as_user mkdir -p "$REAL_HOME/scripts"
fi

# 2. Script Linking Loop
# Iterates through all shell scripts in the dotfiles/scripts directory
SCRIPTS_SOURCE_DIR="$DOTFILES_DIR/scripts"

if [ -d "$SCRIPTS_SOURCE_DIR" ]; then
    # Use a nullglob to avoid errors if no .sh files are found
    shopt -s nullglob
    for script_path in "$SCRIPTS_SOURCE_DIR"/*.sh; do
        if [ -f "$script_path" ]; then
            # Extract filename from path
            script_name=$(basename "$script_path")
            TARGET_LINK="$REAL_HOME/scripts/.$script_name"

            # Create symlink as the real user to avoid permission issues
            run_as_user ln -sf "$script_path" "$TARGET_LINK"

            # Ensure the source script is executable (System Level)
            chmod +x "$script_path"

            echo -e "  ${GREEN}✅ Linked and set executable: $script_name${NC}"
        fi
    done
    shopt -u nullglob
else
    echo -e "  ${CYAN}💡 No scripts directory found in $SCRIPTS_SOURCE_DIR. Skipping.${NC}"
fi

echo -e "${GREEN}✅ Automation scripts task finished successfully.${NC}"
