#!/bin/bash
# 05-zed-conf.sh - Zed configuration as external repository.
source "$(dirname "$0")/00-core.sh"

echo -e "${CYAN}Running task with DOTFILES_DIR: $DOTFILES_DIR${NC}"
# Zed Editor Configuration
ZED_REPO_URL="https://github.com/okanbatuk/zed-config.git"
ZED_TARGET="$DOTFILES_DIR/external/zed-config"
ZED_CONFIG_DIR="$HOME/.config/zed"

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
