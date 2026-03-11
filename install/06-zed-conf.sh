#!/bin/bash
# 06-zed-conf.sh - Zed configuration as external repository.
# Handles external zed-config with a soft-fail approach to prevent setup interruption.

set -e # Stop on fatal errors, but we handle git failures manually

# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_DIR/../core.sh" || { source "$CORE_DIR/core.sh" 2>/dev/null || exit 1; }

echo -e "${CYAN}Running task with DOTFILES_DIR: $DOTFILES_DIR${NC}"

# Zed Editor Configuration
ZED_REPO_URL="git@github.com:okanbatuk/zed-config.git"
ZED_TARGET="$DOTFILES_DIR/external/zed-config"
ZED_CONFIG_DIR="$REAL_HOME/.config/zed"

# 1. Non-interactive accessibility check
echo -e "${YELLOW}📝 Checking access to Zed config repository...${NC}"

# Use GIT_TERMINAL_PROMPT=0 to ensure it doesn't hang waiting for password
if ! run_as_user GIT_TERMINAL_PROMPT=0 git ls-remote "$ZED_REPO_URL" &>/dev/null; then
    echo -e "${RED}⚠️  Warning: Zed repo is unreachable (Private or SSH key missing). Skipping...${NC}"
    # We don't exit 1 here, so setup.sh continues.
else
    # 2. Clone or Update logic (Run as user to maintain permissions)
    if [ ! -d "$ZED_TARGET" ]; then
        echo -e "  📥 ${CYAN}Cloning Zed config repository...${NC}"
        run_as_user mkdir -p "$DOTFILES_DIR/external"
        run_as_user git clone "$ZED_REPO_URL" "$ZED_TARGET" || echo -e "${RED}❌ Clone failed, but continuing...${NC}"
    else
        echo -e "  ${GREEN}✅ Zed config repo already exists.${NC}"
        # update repo if it exists
        run_as_user git -C "$ZED_TARGET" pull
    fi

    # 3. Symlink configuration
    if [ -d "$ZED_TARGET" ]; then
        # Backup existing config if it's a real directory
        if [ -e "$ZED_CONFIG_DIR" ] && [ ! -L "$ZED_CONFIG_DIR" ]; then
            echo -e "  🔄 Backing up existing Zed config..."
            mv "$ZED_CONFIG_DIR" "$ZED_CONFIG_DIR.bak"
        fi

        # Create symlink as user
        run_as_user ln -sfn "$ZED_TARGET" "$ZED_CONFIG_DIR"
        echo -e "  ${GREEN}✅ Zed configuration linked successfully.${NC}"
    fi
fi

echo -e "${GREEN}✅ Zed configuration task finished.${NC}"
