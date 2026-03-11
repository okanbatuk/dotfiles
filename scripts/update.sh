#!/bin/bash
# update.sh - Advanced functional update & maintenance system

clear
# --- Core Environment Import ---
# Minimal import: Variables come from .zshenv, functions from core.sh
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "$DOTFILES_DIR/core.sh" || { echo "Core environment not found"; exit 1; }

# --- 0. Logging & Mode Setup ---
setup_env() {
    MODE="light"
    [[ "$1" == "--full" ]] && MODE="full"

    LOG_DIR_UPDATES="$LOG_DIR/updates"
    mkdir -p "$LOG_DIR_UPDATES" 2>/dev/null
    LOG_FILE="$LOG_DIR_UPDATES/update-$(date +%Y-%m-%d)-$MODE.log"

    # Fail-safe: Ensure the current user owns the log file if it was previously created by root
    [ -f "$LOG_FILE" ] && sudo chown "$REAL_USER":"$REAL_USER" "$LOG_FILE" 2>/dev/null

    exec > >(tee -a "$LOG_FILE") 2>&1
    echo -e "\n${PURPLE}===== UPDATE STARTED AT $(date) [Mode: $MODE] =====${NC}"
}

# --- 1. System Packages ---
update_os() {
    echo -e "\n${GREEN}>>> [STEP 1] Updating System Packages...${NC}"
    if [[ "$MODE" == "full" ]]; then
        echo -e "🌐 [PACMAN] Refreshing mirrors..."
        sudo pacman-mirrors --fasttrack 10
    fi

    echo -e "📦 [PACMAN] Running system upgrade..."
    sudo pacman -Syyu --noconfirm
    if command -v yay >/dev/null 2>&1; then
        echo -e "📦 [YAY] Running AUR upgrade (as user)..."
        yay -Syu --noconfirm --needed
    fi

    echo -e "📦 [FLATPAK] Checking for updates..."
    flatpak update -y
}

# --- 2. Runtimes & SDKs ---
update_tooling() {
    echo -e "\n${CYAN}>>> [STEP 2] Updating Runtimes & Tooling...${NC}"

    if command -v bun >/dev/null 2>&1; then
        echo -e "🚀 [BUN] Upgrading..."
        run_as_user bun upgrade
    fi

    if command -v rustup >/dev/null 2>&1; then
        echo -e "🦀 [RUST] Updating stable toolchain..."
        run_as_user rustup update stable
    fi

    if command -v fnm >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
        echo -e "🟢 [NPM/FNM] Updating global packages for $(node -v)..."
        run_as_user bash -c "eval \"\$(fnm env)\" && \
                    npm install -g npm@latest --silent && \
                    npm update -g --no-audit --no-fund && \
                    npm cache verify"
    fi
}

# --- 3. Deep Maintenance & Cleanup ---
run_maintenance() {
    echo -e "\n${BLUE}>>> [STEP 3] Maintenance & Cleanup...${NC}"
    if [[ "$MODE" != "full" ]]; then
        echo -e "⏭️  [LIGHT] Skipping deep maintenance."
        return
    fi

    echo -e "🧹 [CLEANUP] Removing old caches and orphaned packages..."

    # Cache & Space
    rm -rf "$REAL_HOME/.cache"/* 2>/dev/null
    sudo paccache -rk 2

    # Orphaned Packages
    local orphans=$(pacman -Qdtq)
    [[ -n "$orphans" ]] && sudo pacman -Rs $orphans --noconfirm

    echo -e "🧹 [CLEANUP] Removing node_modules..."
    # Node Modules Cleanup (Desktop/Projects)
    PROJECTS_DIR="$REAL_HOME/Desktop/Projects"
    if [ -d "$PROJECTS_DIR" ] && command -v fd >/dev/null 2>&1; then
        fd -H -t d node_modules "$PROJECTS_DIR" -x rm -rf
    fi
}

# --- 4. Health & Security Controls ---
check_health() {
    echo -e "\n${CYAN}>>> Security & Health Checks${NC}"

    # Security
    systemctl is-active -q ufw && echo -e "  ${GREEN}✅ UFW active${NC}"
    systemctl is-active -q usbguard && echo -e "  ${GREEN}✅ USBGuard active${NC}"

    # Space Check
    local root_available=$(df -h / | awk 'NR==2 {print $4}')
    echo -e "${BLUE}🗂️  Available space on '/':${NC} ${GREEN}$root_available${NC}"

    # Failed Services
    local failed_system=$(systemctl --failed --no-legend)
    if [[ -n "$failed_system" ]]; then
        echo -e "${RED}❌ Failed SYSTEM services:${NC}\n$failed_system"
        sudo systemctl reset-failed
    fi
}

# --- Main Logic ---
main() {
    setup_env "$1"
    update_os
    update_tooling
    run_maintenance
    check_health

    echo -e "\n${PURPLE}===== UPDATE ENDED AT $(date) =====${NC}"
    find "$LOG_DIR_UPDATES" -type f -name "*.log" -mtime +30 -delete
}

main "$@"
