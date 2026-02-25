#!/bin/bash
# update.sh - Advanced functional update & maintenance system

clear
# --- Core Environment Import ---
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
CORE_ENV="$(dirname "$SCRIPT_DIR")/core.sh"
source "$CORE_ENV" 2>/dev/null || { echo "Error: core.sh not found"; exit 1; }

run_as_user() {
    sudo -u "$REAL_USER" "$@"
}

# --- 0. Logging & Mode Setup ---
setup_env() {
    MODE="light"
    [[ "$1" == "--full" ]] && MODE="full"

    LOG_DIR_UPDATES="$LOG_DIR/updates"
    mkdir -p "$LOG_DIR_UPDATES"
    LOG_FILE="$LOG_DIR_UPDATES/update-$(date +%Y-%m-%d)-$MODE.log"

    # Tüm çıktıyı log dosyasına ve terminale yönlendir
    exec > >(tee -a "$LOG_FILE") 2>&1
    echo -e "\n${PURPLE}===== UPDATE STARTED AT $(date) [Mode: $MODE] =====${NC}"
}

# --- 1. System Packages ---
update_os() {
    echo -e "\n${GREEN}>>> Updating System Packages (Pacman & Yay)...${NC}"
    if [[ "$MODE" == "full" ]]; then
        sudo pacman-mirrors --fasttrack 10
    fi
    sudo pacman -Syyu --noconfirm
    command -v yay >/dev/null 2>&1 && run_as_user yay -Syu --noconfirm
    flatpak update -y
}

# --- 2. Runtimes & SDKs ---
update_tooling() {
    echo -e "\n${CYAN}>>> Updating Runtimes & Tooling...${NC}"

    # Bun
    command -v bun >/dev/null 2>&1 && run_as_user bun upgrade

    # Rust (Burada isteğin üzerine default stable eklendi)
    if command -v rustup >/dev/null 2>&1; then
        run_as_user rustup update stable && run_as_user rustup default stable
    fi

    # NPM
    if command -v npm >/dev/null 2>&1; then
        run_as_user npm install -g npm@latest --silent
        run_as_user npm update -g
        run_as_user npm cache verify
    fi

    # SDKMAN!
    if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
        run_as_user bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && sdk selfupdate && sdk update"
        [[ "$MODE" == "full" ]] && run_as_user bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && export sdkman_auto_answer=true && sdk upgrade"
    fi
}

# --- 3. Deep Maintenance & Cleanup ---
run_maintenance() {
    if [[ "$MODE" != "full" ]]; then
        echo -e "\n${GREEN}>>> [LIGHT] Skipping deep cleanup.${NC}"
        return
    fi

    echo -e "\n${BLUE}>>> Deep Maintenance & Cleanup...${NC}"

    # Cache & Space
    rm -rf "$REAL_HOME/.cache"/* 2>/dev/null
    sudo paccache -rk 2

    # Node Modules Cleanup (Desktop/Projects)
    PROJECTS_DIR="$REAL_HOME/Desktop/Projects"
    if [ -d "$PROJECTS_DIR" ] && command -v fd >/dev/null 2>&1; then
        fd -H -t d node_modules "$PROJECTS_DIR" -x rm -rf
    fi

    # Failed Services
    local failed_system=$(systemctl --failed --no-legend)
    if [[ -n "$failed_system" ]]; then
        echo -e "${RED}❌ Failed SYSTEM services:${NC}\n$failed_system"
        sudo systemctl reset-failed
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

    # Orphaned Packages
    local orphans=$(pacman -Qdtq)
    [[ -n "$orphans" ]] && sudo pacman -Rs $orphans --noconfirm
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
