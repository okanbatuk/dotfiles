#!/bin/bash
# 05-zed-conf.sh - Zed configuration as external repository.
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
# Zed Editor Configuration
ZED_REPO_URL="https://github.com/okanbatuk/zed-config.git"
ZED_TARGET="$DOTFILES_DIR/external/zed-config"
ZED_CONFIG_DIR="$REAL_HOME/.config/zed"

if ! git ls-remote "$ZED_REPO_URL" &>/dev/null; then
    echo "⚠️ Zed repo is private or unreachable. Skipping cloning..."
else
    echo -e "${YELLOW}📝 Setting up Zed editor...${NC}"
    if [ ! -d "$ZED_TARGET" ]; then
        echo -e "  📥 ${CYAN}Cloning Zed config repository...${NC}"
        mkdir -p "$DOTFILES_DIR/external"
        git clone "$ZED_REPO_URL" "$ZED_TARGET"
    else
        echo -e "  ${GREEN}✅ Zed config repo already exists.${NC}"
    fi

    # Link Zed config with no-dereference to avoid nesting
    if [ -e "$ZED_CONFIG_DIR" ] && [ ! -L "$ZED_CONFIG_DIR" ]; then
        mv "$ZED_CONFIG_DIR" "$ZED_CONFIG_DIR.bak"
    fi
    ln -sfn "$ZED_TARGET" "$ZED_CONFIG_DIR"
    echo -e "  ${GREEN}✅ Zed configuration linked.${NC}"
fi
