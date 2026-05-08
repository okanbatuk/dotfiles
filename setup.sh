#!/bin/bash
# setup.sh - Interactive and automated dotfiles orchestrator

set -e

# --- 🔍 Smart Environment Detection ---
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

export REAL_USER
export REAL_HOME

# --- Core Environment Import ---
DOTFILES_DIR="${DOTFILES_DIR:-$REAL_HOME/dotfiles}"
source "$DOTFILES_DIR/core.sh" || { echo "Error: core.sh not found"; exit 1; }

# --- 🚨 Error Handling ---
failure() {
  local lineno=$1
  local msg=$2
  log_error "❌ Critical failure at line $lineno: $msg"
  exit 1
}
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

# --- 📂 Infrastructure Initialization ---
initialize_infrastructure() {
    # 1. Create session ID and setup logging via core.sh
    # This handles directory creation, ownership, and 30-day rotation
    local session_id=$(date +%Y%m%d_%H%M%S)
    prepare_logging "setup" "setup_$session_id.log"

    # 2. Assign global variables from core.sh output
    export CURRENT_LOG="$CURRENT_LOG_FILE"
    export STATE_DIR="$LOG_DIR/state"

    # 3. Ensure State Directory exists and is owned by the real user
    if [ ! -d "$STATE_DIR" ]; then
        mkdir -p "$STATE_DIR"
        sudo chown -R "$REAL_USER":"$REAL_USER" "$STATE_DIR"
    fi

    # 4. Start global redirection with tee
    # Redirection happens AFTER prepare_logging fixes permissions
    exec > >(tee -a "$CURRENT_LOG") 2>&1

    log_info "===== SETUP SESSION STARTED: $session_id ====="
    log_debug "Log: $CURRENT_LOG | State: $STATE_DIR"
}

# --- 🛠️ Functions ---

show_menu() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${CYAN}   🚀 DOTFILES PROFESSIONAL SETUP${NC}"
    echo -e "${BLUE}========================================${NC}"

    options=($(ls "$DOTFILES_DIR/install" | grep -E '^[0-9].*\.sh$' | sort))

    for i in "${!options[@]}"; do
        local task_name="${options[$i]%.sh}"
        if [ -f "$STATE_DIR/$task_name.done" ]; then
            echo -e "${YELLOW}$((i+1)))${NC} ${options[$i]} ${GREEN}[✅ INSTALLED]${NC}"
        else
            echo -e "${YELLOW}$((i+1)))${NC} ${options[$i]}"
        fi
    done
    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${YELLOW}f)${NC} 🧹 Force Mode"
    echo -e "${YELLOW}a)${NC} 🚀 Run All"
    echo -e "${YELLOW}q)${NC} 👋 Quit"
    echo -e "${BLUE}========================================${NC}"
}

run_task() {
    local task_file="$DOTFILES_DIR/install/$1"
    local task_name="${1%.sh}"
    local state_file="$STATE_DIR/$task_name.done"

    if [[ -f "$state_file" && "$FORCE_INSTALL" != "true" ]]; then
        log_debug "Skipping $task_name: Already satisfied."
        return 0
    fi

    log_info "▶️ Executing Task: $1"

    if sudo -E "$task_file" "$@" 2>&1 | tee -a "$CURRENT_LOG"; then
        sudo bash -c "echo 'Installed at: $(date)' > '$state_file'"
        sudo chown "$REAL_USER":"$REAL_USER" "$state_file"
        log_debug "✅ Task $task_name marked as completed."
    else
        log_error "❌ Task failed: $1. Check $CURRENT_LOG"
        exit 1
    fi
}

# --- 🚀 Main Logic ---

if [[ $EUID -ne 0 ]]; then
   log_error "❌ This script must be run with sudo."
   exit 1
fi

# Run the centralized infrastructure setup
initialize_infrastructure

if [[ "$1" == "--force" ]]; then
    log_warn "🧹 Force Mode active: Clearing states..."
    rm -f "$STATE_DIR"/*.done
    FORCE_INSTALL="true"
fi

if [[ "$1" == "--auto" ]]; then
    log_info "🤖 Starting Automated Setup..."
    tasks=($(ls "$DOTFILES_DIR/install" | grep -E '^[0-9].*\.sh$' | sort))
    for task in "${tasks[@]}"; do
        run_task "$task"
    done
    log_success "✨ Setup finished successfully."
else
    while true; do
        show_menu
        read -p "Select an option: " choice

        case $choice in
            f|F)
                log_warn "🧹 Resetting state..."
                rm -f "$STATE_DIR"/*.done
                FORCE_INSTALL="true" ;;
            q|Q)
                log_info "👋 Exiting..."
                break ;;
            a|A)
                log_info "🚀 Running all tasks..."
                tasks=($(ls "$DOTFILES_DIR/install" | grep -E '^[0-9].*\.sh$' | sort))
                for task in "${tasks[@]}"; do
                    run_task "$task"
                done
                log_success "✨ All tasks completed."
                break ;;
            [0-9]*)
                idx=$((choice-1))
                if [[ "$idx" -ge 0 && "$idx" -lt "${#options[@]}" ]]; then
                    run_task "${options[$idx]}"
                else
                    log_error "❌ Invalid option."
                fi
                ;;
            *)
                log_error "❌ Invalid selection."
                ;;
        esac
    done
fi
