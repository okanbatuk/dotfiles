#!/bin/bash
# 08-scripts.sh - Linking and hardening custom automation scripts
# Manages user-level script access and ensures secure file permissions.

set -e # Exit immediately if a command fails to trigger setup.sh trap

# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_DIR/../core.sh" || { source "$CORE_DIR/core.sh" 2>/dev/null || exit 1; }

log_info "Starting automation scripts task with DOTFILES_DIR: $DOTFILES_DIR"

# 1. Target Directory Preparation
# Ensure the scripts directory exists in home and is owned by the real user
SCRIPTS_TARGET_DIR="$REAL_HOME/scripts"
if [ ! -d "$SCRIPTS_TARGET_DIR" ]; then
    run_as_user mkdir -p "$SCRIPTS_TARGET_DIR"
    log_debug "✅ Created scripts directory at $SCRIPTS_TARGET_DIR"
fi

# 2. Script Linking & Hardening Loop
SCRIPTS_SOURCE_DIR="$DOTFILES_DIR/scripts"

if [ -d "$SCRIPTS_SOURCE_DIR" ]; then
    # Use nullglob to handle cases where no .sh files exist
    shopt -s nullglob

    log_info "Linking and hardening scripts from $SCRIPTS_SOURCE_DIR..."

    for script_path in "$SCRIPTS_SOURCE_DIR"/*.sh; do
        if [ -f "$script_path" ]; then
            script_name=$(basename "$script_path")
            # Using hidden symlink pattern as per your original design
            TARGET_LINK="$SCRIPTS_TARGET_DIR/.$script_name"

            # Create symlink as the real user to maintain correct ownership
            run_as_user ln -sf "$script_path" "$TARGET_LINK"

            # --- Permission Hardening ---
            # Set to 755 (rwxr-xr-x): Owner can write, others can only read/execute
            # This fixes the 777 (over-privileged) issue while ensuring they remain functional.
            chmod 755 "$script_path"

            log_debug "Hardened & Linked: $script_name -> $TARGET_LINK"
        fi
    done
    shopt -u nullglob
    log_success "✅ All scripts have been secured and linked successfully."
else
    log_warn "No scripts directory found in $SCRIPTS_SOURCE_DIR. Skipping task."
fi

log_info "✅ Automation scripts task finished successfully."
