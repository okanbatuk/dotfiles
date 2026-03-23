#!/bin/bash
# 02-dev-env.sh - Setup JS/TS runtimes, global shims, and editors.
# Dynamically detects Node.js LTS and ensures isolated user-space installation.

set -e # Exit immediately if a command exits with a non-zero status

# --- Core Environment Import ---
CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CORE_DIR/../core.sh" || { source "$CORE_DIR/core.sh" 2>/dev/null || exit 1; }

# --- Variables ---
TARGET_USER="${REAL_USER:-myrn}"
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
FNM_DIR="$TARGET_HOME/.local/share/fnm"

# --- Functions ---

setup_fnm() {
    log_info "📦 Checking/Installing FNM (Fast Node Manager)..."

    if [ ! -f "$FNM_DIR/fnm" ]; then
        run_as_user mkdir -p "$FNM_DIR"
        log_debug "Downloading and installing FNM for $TARGET_USER..."
        run_as_user "curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir '$FNM_DIR' --skip-shell" || exit 1
        log_debug "✅ FNM binary verified at: $(ls -l $FNM_DIR/fnm)"
    else
        log_debug "✅ FNM already exists, skipping installation."
    fi
}

setup_node_lts() {
    log_info "🔍 Detecting latest Node.js LTS version..."

    # Hot-load FNM into the current subshell
    export PATH="$FNM_DIR:$PATH"
    log_debug "Temporary PATH for FNM: $PATH"
    if [ -f "$FNM_DIR/fnm" ]; then
        eval "$("$FNM_DIR/fnm" env --shell bash)"
        log_debug "FNM environment evaluated."
    fi

    # Force metadata update and fetch the latest LTS version number
    # This avoids "Can't find requested version: lts" errors in Docker/CI environments
    LTS_VERSION=$(run_as_user "$FNM_DIR/fnm" list-remote --lts | tail -n 1 | awk '{print $1}')
    log_debug "Detected LTS Version string: '$LTS_VERSION'"

    if [ -z "$LTS_VERSION" ]; then
        log_warn "⚠️ Could not detect LTS version dynamically. Falling back to 'lts' alias."
        LTS_VERSION="lts"
    fi

    log_info "📥 Installing Node.js $LTS_VERSION via FNM..."
    run_as_user "$FNM_DIR/fnm install $LTS_VERSION" || exit 1
    run_as_user "$FNM_DIR/fnm default $LTS_VERSION" || exit 1

    # Store detected version for the subsequent global package task
    export DETECTED_LTS="$LTS_VERSION"
    log_debug "Global DETECTED_LTS set to: $DETECTED_LTS"
}

install_global_packages() {
    log_info "🛠️ Installing Global NPM Packages (User Space)..."

    export PATH="$FNM_DIR:$PATH"

    # Fallback detection if setup_node_lts was skipped in the same session
    if [ -z "$DETECTED_LTS" ]; then
        log_debug "DETECTED_LTS is empty, attempting to recover from installed list..."
        DETECTED_LTS=$($FNM_DIR/fnm list | grep "lts" | awk '{print $2}' | head -n 1)
        [ -z "$DETECTED_LTS" ] && DETECTED_LTS=$($FNM_DIR/fnm list | tail -n 1 | awk '{print $2}')
    fi

    log_debug "📌 Using Node version: $DETECTED_LTS"

    log_debug "Searching for node binary in: $FNM_DIR/node-versions/$DETECTED_LTS"
    local NODE_PATH=$(find "$FNM_DIR/node-versions/$CLEAN_VER" -name "node" -type f -executable | head -n 1)

    if [ -z "$NODE_PATH" ]; then
        log_error "❌ Could not find node binary for $CLEAN_VER in $FNM_DIR"
        log_debug "Directory content of node-versions: $(ls -R $FNM_DIR/node-versions/$DETECTED_LTS | head -n 10)"
        exit 1
    fi
    log_debug "🚀 Node Path Directory Found: $NODE_PATH"

    local NODE_BIN_DIR=$(dirname "$NODE_PATH")
    if [ ! -d "$NODE_BIN_DIR" ]; then
        log_error "❌ Node bin directory not found: $NODE_BIN_DIR"
        exit 1
    fi

    log_debug "🚀 Node Binary Directory: $NODE_BIN_DIR"

    # Define a clean npm install alias for reuse
    local NPM_EXEC="sudo -u $TARGET_USER env PATH=$NODE_BIN_DIR:$PATH $NODE_BIN_DIR/npm"
    local NPM_INSTALL_CLEAN="install -g --no-audit --no-fund --loglevel=error"

    log_debug "NPM Execution Command: $NPM_EXEC"

    log_info "Updating npm and installing global tools..."
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
        log_info "📦 Installing Bun runtime..."
        run_as_user "curl -fsSL https://bun.sh/install | bash" || exit 1
    fi
}

install_editors() {
    log_info "🖥️  Installing Editors (System Level)..."
    local EDITORS=(neovim zed)

    for editor in "${EDITORS[@]}"; do
        if ! pacman -Qi "$editor" &> /dev/null; then
            log_info "📥 Installing $editor..."
            pacman -S --noconfirm "$editor" || exit 1
        else
            log_debug "✅ $editor is already installed."
        fi
    done
}

# --- Main Execution ---
main() {
    log_info "🌐 Configuring Backend Development Environment for $TARGET_USER..."
    log_debug "Execution Context: UID=$(id -u), User=$(whoami), Home=$HOME"

    setup_fnm
    setup_node_lts
    install_global_packages
    setup_bun
    install_editors

    log_info "✅ Development environment setup finished successfully."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
