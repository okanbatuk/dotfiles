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

    prepare_logging "updates" "update-$(date +%Y-%m-%d)-$MODE.log"

    exec > >(tee -a "$CURRENT_LOG_FILE") 2>&1
    log_info "===== UPDATE STARTED AT $(date) [Mode: $MODE] ====="
    log_debug "Mode: $MODE | User: $REAL_USER | Home: $REAL_HOME"
}

# --- 🛡️ Pacman Lock Management ---
# Checks for existing pacman database locks and resolves conflicts
handle_pacman_lock() {
    local lock_file="/var/lib/pacman/db.lck"
    
    if [[ -f "$lock_file" ]]; then
        log_warn "⚠️ Pacman lock file detected: $lock_file"
        
        # Identify the process ID (PID) holding the lock file
        # fuser returns the PID of the process using the specified file
        local pid=$(sudo fuser "$lock_file" 2>/dev/null | awk '{print $NF}')
        
        if [[ -n "$pid" ]]; then
            # Get the command name of the blocking process for logging
            local process_name=$(ps -p "$pid" -o comm=)
            log_info "🛑 Found active process '$process_name' (PID: $pid) holding the lock. Terminating..."
            
            # Send SIGTERM (15) for a graceful shutdown first
            sudo kill -15 "$pid"
            sleep 2
            
            # If the process is still alive, force kill with SIGKILL (9)
            if ps -p "$pid" > /dev/null; then
                log_debug "Process $pid still alive, forcing kill..."
                sudo kill -9 "$pid" 2>/dev/null
            fi
        fi
        
        # Ensure the lock file is removed even if the process exited cleanly
        log_info "🔓 Removing lock file to proceed with update..."
        sudo rm -f "$lock_file"
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
    sudo pacman -Syyu --noconfirm

    log_info "📦 [YAY] Running AUR upgrade (as user)..."
    run_as_user "yay -Syu --noconfirm --needed"

    if command -v flatpak >/dev/null 2>&1; then
        log_info "📦 [FLATPAK] Checking for updates..."
        flatpak update -y
    fi
}

# --- 2. Runtimes & Tooling ---
update_tooling() {
    log_info ">>> [STEP 2] Updating Runtimes & Tooling..."

    if command -v bun >/dev/null 2>&1; then
        log_info "🚀 [BUN] Upgrading..."
        run_as_user bun upgrade
    fi

    if command -v rustup >/dev/null 2>&1; then
        log_info "🦀 [RUST] Updating stable toolchain..."
        run_as_user rustup update stable
    fi

    if command -v fnm >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
        # Dynamically detect current node version
        local current_node=$(run_as_user "eval \"\$(fnm env)\" && fnm current")
        log_info "🟢 [NPM/FNM] Updating global packages for $current_node..."
        run_as_user bash -c "eval \"\$(fnm env)\" && \
                    npm install -g npm@latest --silent && \
                    npm update -g --no-audit --no-fund && \
                    npm cache verify"
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

    log_info "🧹 [CLEANUP] Removing node_modules in Projects..."
    # Node Modules Cleanup (Desktop/Projects)
    PROJECTS_DIR="$REAL_HOME/Desktop/Projects"
    if [ -d "$PROJECTS_DIR" ] && command -v fd >/dev/null 2>&1; then
        log_debug "Scanning $PROJECTS_DIR for node_modules to delete..."
        run_as_user fd -H -t d node_modules "$PROJECTS_DIR" --changed-before 7d -x rm -rf
    fi
}

# --- 4. Health & Security Controls ---
check_health() {
    log_info ">>> Security & Health Checks"

    # Security
    systemctl is-active -q ufw && log_info "  ✅ UFW active"
    systemctl is-active -q usbguard && log_info "  ✅ USBGuard active$"

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

    log_info "===== UPDATE ENDED AT $(date) ====="
    log_info "Log location: ${YELLOW}$CURRENT_LOG_FILE${NC}"
}

main "$@"
