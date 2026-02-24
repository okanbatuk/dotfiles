#!/bin/bash
# 04-git.sh - Personal Git configuration and GPG check
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
echo -e "${YELLOW}👤 Configuring Git and GPG...${NC}"

GIT_LOCAL="$REAL_HOME/.gitconfig.local"

# 1. Setup Personal Credentials
if [ ! -f "$GIT_LOCAL" ]; then
    echo -e "  ${CYAN}Setup: Personal Git details not found.${NC}"
    read -p "  Enter your Git User Name: " git_name
    read -p "  Enter your Git Email: " git_email

    cat <<EOF > "$GIT_LOCAL"
[user]
    name = $git_name
    email = $git_email
EOF
    echo -e "  ${GREEN}✅ Created $GIT_LOCAL with your credentials.${NC}"
else
    echo -e "  ${GREEN}✅ $GIT_LOCAL already exists.${NC}"
fi

# 2. GPG Signing Check
echo -e "${YELLOW}🔑 Checking GPG signing status...${NC}"
if ! gpg --list-secret-keys > /dev/null 2>&1; then
    echo -e "  ${CYAN}💡 Tip: No GPG keys found. For 'Verified' commits, consider creating one manually.${NC}"
else
    # Detect the first GPG key ID (Long format)
    GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=LONG | grep 'sec' | awk '{print $2}' | cut -d'/' -f2 | head -n 1)
    echo -e "  ${GREEN}✅ GPG key detected: $GPG_KEY_ID${NC}"
    echo -e "  ${YELLOW}👉 To enable signing, add these to your ~/.gitconfig.local:${NC}"
    echo -e "     [user]\n       signingkey = $GPG_KEY_ID\n     [commit]\n       gpgsign = true"
fi
