#!/bin/bash
# 05-zsh-config.sh - Managing Zsh sourcing for multiple config files and functions
# Ensures that all modular config files and functions are properly sourced in .zshrc.

set -e # Exit on any error to trigger the setup.sh failure trap

# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_DIR/../core.sh" || { source "$CORE_DIR/core.sh" 2>/dev/null || exit 1; }

log_info "🐚 Updating .zshrc configuration for $REAL_USER..."

ZSHRC="$REAL_HOME/.zshrc"

# Check if .zshrc exists (either as a file or a valid symlink)
if [ ! -f "$ZSHRC" ]; then
    log_error "❌ Critical Error: .zshrc not found at $ZSHRC."
    log_warn "💡 Ensure 04-links.sh has run correctly before this script."
    exit 1
fi

# 1. List of files to be sourced in .zshrc
# These are core part of the shell experience
FILES_TO_SOURCE=(.zsh_aliases .zsh_notes)

for file in "${FILES_TO_SOURCE[@]}"; do
    # Check if the source line already exists using a precise regex
    if ! grep -q "source.*$file" "$ZSHRC"; then
        log_info "➕ Adding source line for $file to .zshrc"
        # Append the source command using $HOME for portability
        echo -e "\n# Load $file\n[[ -f \$HOME/$file ]] && source \$HOME/$file" >> "$ZSHRC"
        log_debug "✅ $file source added successfully."
    else
        log_debug "✅ $file is already sourced in .zshrc"
    fi
done

# 2. Inject Dynamic Functions Loader
# Automatically sources every standalone function file in ~/.zsh_functions.d
if ! grep -q ".zsh_functions.d" "$ZSHRC"; then
    log_info "🚀 Adding dynamic function loader to .zshrc"

    # Using a single-quoted EOF to prevent local variable expansion
    cat <<'EOF' >> "$ZSHRC"

# Load modular functions from .zsh_functions.d
if [ -d "$HOME/.zsh_functions.d" ]; then
    for func in "$HOME/.zsh_functions.d"/*; do
        [ -f "$func" ] && source "$func"
    done
fi
EOF
    log_debug "✅ Dynamic function loader added to .zshrc"
else
    log_debug "✅ Function loader is already present in .zshrc"
fi

# 3. Final Permissions Check
# Ensure .zshrc ownership is preserved even if setup.sh runs as root
chown "$REAL_USER:$REAL_USER" "$ZSHRC"

log_success "✅ Zsh configuration update finished successfully."
