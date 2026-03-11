#!/bin/bash
# 05-git.sh - Personal Git configuration and GPG check
# Sets up local git credentials and identifies GPG keys for signing.

set -e # Exit immediately if a command fails

# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_DIR/../core.sh" || { source "$CORE_DIR/core.sh" 2>/dev/null || exit 1; }

echo -e "${CYAN}Running task with DOTFILES_DIR: $DOTFILES_DIR${NC}"
echo -e "${YELLOW}👤 Configuring Git and GPG for $REAL_USER...${NC}"

GIT_LOCAL="$REAL_HOME/.gitconfig.local"

# 1. Setup Personal Credentials
if [ ! -f "$GIT_LOCAL" ]; then
    echo -e "  ${CYAN}Setup: Personal Git details not found.${NC}"

    # Ensure input is taken correctly even when run via sudo
    # Use /dev/tty to make sure read works in all terminal environments
    read -p "  Enter your Git User Name: " git_name < /dev/tty
    read -p "  Enter your Git Email: " git_email < /dev/tty

    # Create the local config file
    # We use a simple cat here as it's a one-time static creation
    cat <<EOF > "$GIT_LOCAL"
[user]
    name = $git_name
    email = $git_email
EOF

    # Critical: Fix ownership since setup.sh runs as root
    chown "$REAL_USER:$REAL_USER" "$GIT_LOCAL"
    echo -e "  ${GREEN}✅ Created $GIT_LOCAL with your credentials.${NC}"
else
    echo -e "  ${GREEN}✅ $GIT_LOCAL already exists.${NC}"
fi

# 2. GPG Signing Check
# We run gpg commands as the REAL_USER to check their specific keyring
echo -e "${YELLOW}🔑 Checking GPG signing status for $REAL_USER...${NC}"

if ! run_as_user gpg --list-secret-keys &> /dev/null; then
    echo -e "  ${CYAN}💡 Tip: No GPG keys found for $REAL_USER.${NC}"
    echo -e "  ${CYAN}   For 'Verified' commits, consider creating one manually with 'gpg --full-generate-key'.${NC}"
else
    # Detect the first GPG key ID (Long format) as the real user
    GPG_KEY_ID=$(run_as_user gpg --list-secret-keys --keyid-format=LONG | grep 'sec' | awk '{print $2}' | cut -d'/' -f2 | head -n 1 || echo "")

    if [ -n "$GPG_KEY_ID" ]; then
        echo -e "  ${GREEN}✅ GPG key detected: $GPG_KEY_ID${NC}"
        echo -e "  ${YELLOW}👉 To enable signing, add these to your ~/.gitconfig.local:${NC}"
        echo -e "     [user]\n       signingkey = $GPG_KEY_ID\n     [commit]\n       gpgsign = true"
    fi
fi

echo -e "${GREEN}✅ Git configuration task finished.${NC}"
