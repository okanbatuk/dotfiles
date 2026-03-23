#!/bin/bash
# 06-git.sh - Personal Git configuration and GPG check
# Sets up local git credentials and identifies GPG keys for signing.

set -e # Exit immediately if a command fails to trigger setup.sh trap

# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_DIR/../core.sh" || { source "$CORE_DIR/core.sh" 2>/dev/null || exit 1; }

log_info "👤 Configuring Git and GPG for $REAL_USER..."

GIT_LOCAL="$REAL_HOME/.gitconfig.local"

# 1. Setup Personal Credentials
# Checks if local credentials exist to avoid overwriting
if [ ! -f "$GIT_LOCAL" ]; then
    log_warn "💡 Setup: Personal Git details not found."

    # Ensure input is taken correctly even when run via sudo using /dev/tty
    read -p "  Enter your Git User Name: " git_name < /dev/tty
    read -p "  Enter your Git Email: " git_email < /dev/tty

    # Create the local config file safely
    cat <<EOF > "$GIT_LOCAL"
[user]
    name = $git_name
    email = $git_email
EOF

    # Critical: Fix ownership since setup.sh runs as root
    chown "$REAL_USER:$REAL_USER" "$GIT_LOCAL"
    log_info "✅ Created $GIT_LOCAL with your credentials."
else
    log_debug "✅ $GIT_LOCAL already exists."
fi

# 2. GPG Signing Check
# Run gpg commands as REAL_USER to check their specific keyring
log_info "🔑 Checking GPG signing status for $REAL_USER..."

if ! run_as_user gpg --list-secret-keys &> /dev/null; then
    log_warn "💡 Tip: No GPG keys found for $REAL_USER."
    log_debug "For 'Verified' commits, consider creating one manually with 'gpg --full-generate-key'."
else
    # Detect the first GPG key ID (Long format) as the real user
    GPG_KEY_ID=$(run_as_user gpg --list-secret-keys --keyid-format=LONG | grep 'sec' | awk '{print $2}' | cut -d'/' -f2 | head -n 1 || echo "")

    if [ -n "$GPG_KEY_ID" ]; then
        log_info "✅ GPG key detected: $GPG_KEY_ID"
        echo -e "${YELLOW}👉 To enable signing, add these to your ~/.gitconfig.local:${NC}"
        echo -e "     [user]\n       signingkey = $GPG_KEY_ID\n     [commit]\n       gpgsign = true"
    fi
fi

log_info "✅ Git configuration task finished successfully."
