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

    # 1. Create a unique timestamp for the file name (Year-Month-Day_Hour-Minute-Second)
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

    # 2. Build the dynamic log name
    local log_name="update-${timestamp}-${MODE}.log"

    # 3. Pass it to core.sh function as it is
    prepare_logging "updates" "$log_name"

    # Redirect all output (stdout & stderr) to this new unique file
    exec > >(tee -a "$CURRENT_LOG_FILE") 2>&1

    log_info "===== UPDATE STARTED AT $(date) [Mode: $MODE] ====="
    log_debug "Mode: $MODE | User: $REAL_USER | Home: $REAL_HOME"
}

# --- 🛡️ Pacman Lock Management ---
# Checks for existing pacman database locks and manages conflicts intelligently
handle_pacman_lock() {
    local lock_file="/var/lib/pacman/db.lck"

    if [[ -f "$lock_file" ]]; then
        log_warn "⚠️ Pacman lock file detected: $lock_file"

        # Identify the process ID (PID) holding the lock file
        local pid=$(sudo fuser "$lock_file" 2>/dev/null | awk '{print $NF}')

        if [[ -n "$pid" ]]; then
            # Get the command name of the blocking process
            local process_name=$(ps -p "$pid" -o comm=)

            # Check if the lock is held by our own Full Update service
            # If update-full is active, the light update should yield to prevent corruption
            if systemctl is-active -q update-full.service; then
                log_info "🛡️ Full update is currently in progress. Light update will exit to avoid conflict."
                send_notification "Update Deferred" "Light update skipped because a Full update is running. ⏳" "low"
                exit 0
            fi

            # If the lock is held by system auto-updaters (e.g., PackageKit, Discover), terminate it
            log_success "🛑 Found active system process '$process_name' (PID: $pid). Terminating to take control..."

            # Graceful termination first
            sudo kill -15 "$pid"
            sleep 2

            # Force kill if still alive
            if ps -p "$pid" > /dev/null; then
                log_debug "Process $pid still alive, forcing kill..."
                sudo kill -9 "$pid" 2>/dev/null
            fi
        fi

        # Remove the lock file to proceed with our controlled script execution
        log_info "🔓 Removing lock file to proceed with custom update script..."
        sudo rm -f "$lock_file"

        # Notify only if we had to forcibly kill a third-party system process
        if [[ "$process_name" != "pacman" && "$process_name" != "yay" ]]; then
            send_notification "Security Alert" "External process ($process_name) was terminated to prioritize your update script. 🛡️" "normal" "dialog-warning"
        fi
    fi
}

# --- 1. System Packages ---
update_os() {
    # Check the db.lck file if exist remove it
    handle_pacman_lock

    log_info ">>> [STEP 1] Updating System Packages..."

    if [[ "$MODE" == "full" ]]; then
        log_info "🌐 [PACMAN] Refreshing mirrors..."
        sudo pacman-mirrors --fasttrack 10
    fi

    log_info "📦 [PACMAN] Running system upgrade..."
    sudo pacman -Syyu --noconfirm && log_success "📦 [PACMAN] System packages updated."

    log_info "📦 [YAY] Running AUR upgrade (as user)..."
    run_as_user "yay -Syu --noconfirm --needed" && log_success "📦 [YAY] Packages updated."

    if command -v flatpak >/dev/null 2>&1; then
        log_info "📦 [FLATPAK] Checking for updates..."
        flatpak update -y && log_success "📦 [FLATPAK] Runtimes updated."
    fi
}

# --- 2. Runtimes & Tooling ---
update_tooling() {
    log_info ">>> [STEP 2] Updating Runtimes & Tooling..."

    if command -v bun >/dev/null 2>&1; then
        log_info "🚀 [BUN] Upgrading..."
        run_as_user bun upgrade && log_success "🚀 [BUN] Runtime upgraded."
    fi

    if command -v rustup >/dev/null 2>&1; then
        log_info "🦀 [RUST] Updating stable toolchain..."
        run_as_user rustup update stable && log_success "🦀 [RUST] Toolchain updated."
    fi

    if command -v fnm >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
        # Dynamically detect current node version
        local current_node=$(run_as_user "eval \"\$(fnm env)\" && fnm current")
        log_info "🟢 [NPM/FNM] Updating global packages for $current_node..."
        run_as_user bash -c "eval \"\$(fnm env)\" && \
                    npm install -g npm@latest --silent && \
                    npm update -g --no-audit --no-fund && \
                    npm cache verify" && log_success "🟢 [NPM/FNM] Global NPM packages updated for $current_node."
    fi
}

# --- 3. Deep Maintenance & Cleanup ---
run_maintenance() {
    log_info ">>> [STEP 3] Maintenance & Cleanup..."
    if [[ "$MODE" != "full" ]]; then
        log_debug "Skipping deep maintenance in light mode."
        return
    fi

    log_info "🧹 [CLEANUP] Removing old caches and orphaned packages..."

    # Cache & Space
    sudo paccache -rk 2

    # Orphaned Packages
    local orphans=$(pacman -Qdtq)
    [[ -n "$orphans" ]] && sudo pacman -Rs $orphans --noconfirm
    log_success "✅ System package cache and orphans cleaned."

    log_info "🧹 [CLEANUP] Removing node_modules in Projects..."
    # Node Modules Cleanup (Desktop/Projects)
    PROJECTS_DIR="$REAL_HOME/Desktop/Projects"
    if [ -d "$PROJECTS_DIR" ] && command -v fd >/dev/null 2>&1; then
        log_debug "Scanning $PROJECTS_DIR for node_modules to delete..."
        run_as_user fd -H -t d node_modules "$PROJECTS_DIR" --changed-before 7d -x rm -rf
        log_success "✅ Old node_modules directories purged from projects."
    fi

    log_success "✅ Deep maintenance cycle finished successfully."
}

# --- 4. Health & Security Controls ---
check_health() {
    log_info ">>> Security & Health Checks"

    # Security
    systemctl is-active -q ufw && log_success "  ✅ UFW active"
    systemctl is-active -q usbguard && log_success "  ✅ USBGuard active$"

    # Space Check
    local root_available=$(df -h / | awk 'NR==2 {print $4}')
    log_info "🗂️  Available space on '/': ${GREEN}$root_available${NC}"

    # Failed Services
    local failed_system=$(systemctl --failed --no-legend)
    if [[ -n "$failed_system" ]]; then
        log_error "❌ Failed SYSTEM services:\n$failed_system"
        sudo systemctl reset-failed
    else
        log_debug "No failed system services found."
    fi
}

# --- Main Logic ---
main() {
    setup_env "$1"
    update_os
    update_tooling
    run_maintenance
    check_health

    log_success "===== UPDATE COMPLETED SUCCESSFULLY AT $(date) ====="
    log_info "Log location: ${YELLOW}$CURRENT_LOG_FILE${NC}"

    # Notify completion based on mode
    send_notification "Update Complete" "System maintenance ($MODE mode) finished successfully! ✅" "normal" "emblem-ok"
}

main "$@"
