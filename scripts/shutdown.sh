#!/bin/bash
# shutdown.sh - System maintenance and cleanup before poweroff
# Optimized to use centralized core.sh logic and English documentation.

clear

# --- Core Environment Import ---
# Using the streamlined import method leveraging .zshenv variables
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "$DOTFILES_DIR/core.sh" || { echo "Core environment not found"; exit 1; }

# --- 0. Logging & Setup ---
setup_env() {
    # Determine if shutdown is required via parameter or prompt
    [[ "$1" =~ ^[YyNn]$ ]] && SHUTDOWN_CHOICE="$1" || { log_info "Shutdown after cleanup? (Yy/Nn):"; read -r SHUTDOWN_CHOICE; }

    # Initialize log directory and file
    prepare_logging "maintenance" "shutdown-cleanup-$(date +%Y-%m-%d).log"

    # Redirect all output to log file and terminal
    exec > >(tee -a "$CURRENT_LOG_FILE") 2>&1
    log_info "===== CLEANUP STARTED AT $(date) ====="
    log_debug "Shutdown choice: $SHUTDOWN_CHOICE | Active user: $REAL_USER"
}

# --- 1. System Maintenance (Root Required) ---
cleanup_system() {
    log_info ">>> [STEP 1] System Level Cleanup..."
    log_debug "Cleaning system-wide caches and temp files..."
    # Refresh sudo timestamp to avoid password prompts later
    sudo -v

    # 1. Memory Management
    log_info "🧠 Flushing filesystem caches..."
    sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null

    # 2. Journal Logs
    log_info "🧹 Vacuuming journal logs (2 days)..."
    sudo journalctl --vacuum-time=2d

    # 3. Package Management (System Level)
    log_info "📦 Cleaning package caches (Pacman/Pamac)..."
    log_debug "Running paccache and pamac clean"
    sudo paccache -rk 2 2>/dev/null || true
    if command -v pamac >/dev/null 2>&1; then
        sudo pamac clean --keep 2 --no-confirm 2>/dev/null || true
    fi

    # 5. User Space Cleanup (User Level - Single Execution)
    log_info "🧹 Cleaning all user caches ($REAL_USER)..."
    log_debug "Target directory: $REAL_HOME/.cache"
    run_as_user "rm -rf $REAL_HOME/.cache/* 2>/dev/null"

    # 6. Temporary Files (Safe Cleanup)
    log_info "🧹 Cleaning old temporary files..."
    log_debug "Using systemd-tmpfiles for safe cleanup of /tmp"
    sudo systemd-tmpfiles --clean 2>/dev/null || true
}

# --- 2. User & Desktop Maintenance ---
clean_user_space() {
    log_info ">>> [STEP 2] User Space Cleanup..."

    # Screenshot Cleanup
    if [ -d "$SS_DIR" ]; then
        log_info "📸 Cleaning old screenshots in $SS_DIR..."
        run_as_user "find \"$SS_DIR\" -type f -name \"Screenshot*\" -mmin +1440 -delete 2>/dev/null"
    fi

    log_debug "User space cleanup completed for $REAL_USER."
}

# --- 3. Developer Tooling Cleanup ---
clean_dev_tools() {
    log_info ">>> [STEP 3] Dev-Tooling Cleanup (NPM, Bun, AUR)..."

    # 1. Package Manager Caches
    log_info "🧹 Cleaning NPM & Bun caches..."
    log_debug "Removing NPM cacache and Bun install cache for $REAL_USER"
    run_as_user "rm -rf $REAL_HOME/.npm/_cacache $REAL_HOME/.bun/install/cache 2>/dev/null"

    # 2. Flatpak
    if command -v flatpak >/dev/null 2>&1; then
        log_info "📦 Cleaning Flatpak runtimes & app caches..."

        log_debug "Uninstalling unused Flatpak runtimes (System level)"
        sudo flatpak uninstall --unused -y 2>/dev/null || true
        log_debug "Clearing Flatpak app caches in $REAL_HOME/.var/app"
        run_as_user "rm -rf $REAL_HOME/.var/app/*/cache 2>/dev/null"
    fi
}

# --- 4. Log Management ---
manage_logs() {
    log_info ">>> [STEP 4] Log Rotation & Management..."

    # Custom Session Logs Cleanup
    CUSTOM_LOG_DIR="$LOG_DIR/custom"
    if [ -d "$CUSTOM_LOG_DIR" ]; then
        log_info "🧹 Wiping custom session logs..."
        log_debug "Removing directory: $CUSTOM_LOG_DIR"
        rm -rf "$CUSTOM_LOG_DIR"
    fi
}

# --- Final Execution ---
finalize() {
    log_info "===== CLEANUP ENDED AT $(date) ====="
    log_info "Log location: ${YELLOW}$CURRENT_LOG_FILE${NC}"

    # Execute poweroff if confirmed
    if [[ "$SHUTDOWN_CHOICE" =~ ^[Yy]$ ]]; then
        log_warn "✅ System shutting down in 5 seconds..."
        log_debug "Triggering: sudo systemctl poweroff"

        sleep 5
        sudo systemctl poweroff
    else
        log_info "✅ Maintenance complete. Staying online."
        log_debug "Shutdown was declined or not requested. Context: $REAL_USER"
    fi
}

# --- Main Logic ---
main() {
    setup_env "$1"
    cleanup_system
    clean_user_space
    clean_dev_tools
    manage_logs
    finalize
}

main "$@"
