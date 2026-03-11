#!/bin/bash
# 02-dev-env.sh - Setup JS/TS runtimes, global shims, and editors.
# Dynamically detects Node.js LTS and ensures isolated user-space installation.

set -e # Exit immediately if a command exits with a non-zero status

# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_DIR/../core.sh" || { source "$CORE_DIR/core.sh" 2>/dev/null || exit 1; }

# --- Variables ---
TARGET_USER="$REAL_USER"
TARGET_HOME="$REAL_HOME"
FNM_DIR="$TARGET_HOME/.local/share/fnm"

# --- Functions ---

setup_fnm() {
    echo -e "${PURPLE}📦 Installing/Checking FNM...${NC}"
    if [ ! -f "$FNM_DIR/fnm" ]; then
        run_as_user mkdir -p "$FNM_DIR"
        run_as_user curl -fsSL https://fnm.vercel.app/install | run_as_user bash -s -- --install-dir "$FNM_DIR" --skip-shell || exit 1
    fi
}

setup_node_lts() {
    echo -e "${PURPLE}🔍 Detecting latest Node.js LTS version...${NC}"

    # Force metadata update and fetch the latest LTS version number
    # This avoids "Can't find requested version: lts" errors in Docker/CI environments
    LTS_VERSION=$(run_as_user "$FNM_DIR/fnm" list-remote --lts | tail -n 1 | awk '{print $1}')

    if [ -z "$LTS_VERSION" ]; then
        echo -e "${YELLOW}⚠️  Could not detect LTS version dynamically. Falling back to 'lts' alias...${NC}"
        LTS_VERSION="lts"
    fi

    echo -e "${PURPLE}📥 Installing Node.js $LTS_VERSION via FNM...${NC}"
    run_as_user "$FNM_DIR/fnm" install "$LTS_VERSION" || exit 1
    run_as_user "$FNM_DIR/fnm" default "$LTS_VERSION" || exit 1

    # Store detected version for the subsequent global package task
    export DETECTED_LTS="$LTS_VERSION"
}

install_global_packages() {
    echo -e "${PURPLE}🛠️  Installing Global NPM Packages (User Space)...${NC}"

    # Fallback detection if setup_node_lts was skipped in the same session
    if [ -z "$DETECTED_LTS" ]; then
        DETECTED_LTS=$(run_as_user "$FNM_DIR/fnm" list-remote --lts | tail -n 1)
    fi

    # Resolve the absolute path to the Node binary to prevent 'env: node' errors
    local NODE_BIN_PATH
    NODE_BIN_PATH=$(run_as_user "$FNM_DIR/fnm" exec --using="$DETECTED_LTS" sh -c 'dirname $(which node)')

    if [ -z "$NODE_BIN_PATH" ] || [[ "$NODE_BIN_PATH" == "." ]]; then
        echo -e "${RED}❌ Could not resolve Node binary path!${NC}"
        exit 1
    fi

    echo -e "${CYAN}🚀 Path resolved: $NODE_BIN_PATH${NC}"

    # Inject path explicitly into the env to ensure npm can find the node engine
    local NPM_EXEC="run_as_user env PATH=$NODE_BIN_PATH:$PATH $NODE_BIN_PATH/npm"

    # Define a clean npm install alias for reuse
    local NPM_INSTALL_CLEAN="install -g --no-audit --no-fund --loglevel=error"

    # 1. Update npm itself cleanly
    $NPM_EXEC $NPM_INSTALL_CLEAN npm@latest || exit 1

    # 2. Install global tools with minimized log noise
    $NPM_EXEC $NPM_INSTALL_CLEAN \
        nopt semver node-gyp \
        typescript ts-node tsc-watch @types/node \
        nodemon pm2 vercel @biomejs/biome \
        neovim tree-sitter-cli \
        typescript-language-server vscode-langservers-extracted || exit 1
}

setup_bun() {
    if ! run_as_user command -v bun &> /dev/null; then
        echo -e "${PURPLE}📦 Installing Bun...${NC}"
        run_as_user curl -fsSL https://bun.sh/install | run_as_user bash || exit 1
    fi
}

install_editors() {
    echo -e "${CYAN}🖥️  Installing Editors (System Level)...${NC}"
    local EDITORS=(neovim zed)

    for editor in "${EDITORS[@]}"; do
        if ! pacman -Qi "$editor" &> /dev/null; then
            echo -e "${YELLOW}📥 Installing $editor...${NC}"
            pacman -S --noconfirm "$editor" || exit 1
        else
            echo -e "${GREEN} ✅ $editor is already installed.${NC}"
        fi
    done
}

# --- Main Execution ---
echo -e "${PURPLE}🌐 Configuring JS/TS Environment for $TARGET_USER...${NC}"

setup_fnm
setup_node_lts
install_global_packages
setup_bun
install_editors

echo -e "${GREEN}✅ Development environment setup finished successfully.${NC}"
