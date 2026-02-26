#!/bin/bash
# shutdown.sh - System maintenance and cleanup before poweroff

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

# --- Helper: Privilege De-escalation ---
# Executes commands as the logged-in user to prevent root ownership pollution
run_as_user() {
    sudo -u "$REAL_USER" "$@"
}

# --- 0. Logging & Setup ---
setup_env() {
    # Determine if shutdown is required via parameter or prompt
    if [[ "$1" =~ ^[YyNn]$ ]]; then
        SHUTDOWN_CHOICE="$1"
    else
        echo -e "${CYAN}❓ Do you want to shutdown after cleanup? (Yy/Nn):${NC} "
        read -r SHUTDOWN_CHOICE
    fi

    # Initialize log directory and file
    LOG_DIR_MAINT="$LOG_DIR/maintenance"
    mkdir -p "$LOG_DIR_MAINT"
    LOG_FILE="$LOG_DIR_MAINT/shutdown-cleanup-$(date +%Y-%m-%d).log"

    # Redirect all output to log file and terminal
    exec > >(tee -a "$LOG_FILE") 2>&1
    echo -e "\n${PURPLE}===== CLEANUP STARTED AT $(date) [User: $REAL_USER] =====${NC}"
}

# --- 1. System Maintenance (Root Required) ---
clean_system() {
    echo -e "\n${BLUE}>>> [STEP 1] System Level Cleanup...${NC}"

    # Flush memory caches to disk
    echo -e "🧠 Flushing filesystem caches..."
    sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

    # Vacuum systemd journal logs older than 2 days
    echo -e "🧹 Vacuuming journal logs (2 days)..."
    sudo journalctl --vacuum-time=2d

    # Clean temporary directories using fd for performance if available
    echo -e "🧹 Cleaning temporary files..."
    if command -v fd >/dev/null 2>&1; then
        sudo fd . /tmp /var/tmp -x rm -rf 2>/dev/null || true
    else
        sudo find /tmp /var/tmp -mindepth 1 -delete 2>/dev/null || true
    fi

    # Remove old cached packages
    echo -e "📦 Cleaning package caches (Pacman/Pamac)..."
    sudo paccache -rk 2 2>/dev/null || true
    sudo pamac clean --keep 2 2>/dev/null || true
}

# --- 2. User & Desktop Maintenance ---
clean_user_space() {
    echo -e "\n${CYAN}>>> [STEP 2] User Space Cleanup...${NC}"

    # Clean old screenshots (>24h)
    if [ -d "$SS_DIR" ]; then
        echo -e "📸 Cleaning old screenshots (>24h)..."
        run_as_user find "$SS_DIR" -type f -name "Screenshot*" -mmin +1440 -delete 2>/dev/null || true
    fi

    echo -e "🧹 Clearing GNOME thumbnails & user cache..."
    run_as_user rm -rf "$REAL_HOME/.cache/thumbnails"/* 2>/dev/null || true
}

# --- 3. Developer Tooling Cleanup ---
clean_dev_tools() {
    echo -e "\n${GREEN}>>> [STEP 3] Dev-Tooling Cleanup (NPM, Bun, Rust)...${NC}"
    # Clean dev caches
    # We use run_as_user to ensure root doesn't own any regenerated metadata
    echo -e "🧹 Cleaning NPM & Bun caches..."
    run_as_user rm -rf "$REAL_HOME/.npm/_cacache" 2>/dev/null || true
    run_as_user rm -rf "$REAL_HOME/.bun/install/cache" 2>/dev/null || true

    echo -e "🧹 Cleaning AUR helper caches..."
    run_as_user rm -rf "$REAL_HOME/.cache/yay" "$REAL_HOME/.cache/paru" 2>/dev/null || true

    # Handle Flatpak runtimes and app caches
    echo -e "📦 Cleaning Flatpak unused runtimes..."
    flatpak uninstall --unused -y 2>/dev/null || true
    run_as_user rm -rf "$REAL_HOME/.var/app"/*/cache 2>/dev/null || true
}

# --- 4. Log Management ---
manage_logs() {
    echo -e "\n${PURPLE}>>> [STEP 4] Log Rotation & Management...${NC}"

    # Remove custom session logs if directory exists
    CUSTOM_LOG_DIR="$LOG_DIR/custom"
    if [ -d "$CUSTOM_LOG_DIR" ]; then
        echo -e "🧹 Wiping custom session logs..."
        rm -rf "$CUSTOM_LOG_DIR"
    fi

    # Rotate maintenance logs older than 30 days
    echo -e "🗃️ Removing maintenance logs older than 30 days..."
    find "$LOG_DIR_MAINT" -type f -name "*.log" -mtime +30 -delete
}

# --- Final Execution ---
finalize() {
    echo -e "\n${PURPLE}===== CLEANUP ENDED AT $(date) =====${NC}"

    # Execute poweroff if confirmed
    if [[ "$SHUTDOWN_CHOICE" =~ ^[Yy]$ ]]; then
        echo -e "\n${RED}✅ System shutting down in 5 seconds...${NC}"
        sleep 5
        sudo systemctl poweroff
    else
        echo -e "\n${GREEN}✅ Maintenance complete. Staying online.${NC}"
    fi
}

# --- Main Logic ---
main() {
    setup_env "$1"
    clean_system
    clean_user_space
    clean_dev_tools
    manage_logs
    finalize
}

main "$@"
