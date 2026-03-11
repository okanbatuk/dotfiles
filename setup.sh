#!/bin/bash
# setup.sh - Interactive and automated dotfiles orchestrator

set -e

# --- 🔍 Smart Environment Detection ---
# Identify the actual user and their home directory even when run with sudo
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

# Export variables so child scripts (01-system.sh, etc.) can inherit them
export REAL_USER
export REAL_HOME

# --- Core Environment Import ---
# Using the streamlined import method leveraging .zshenv variables if available
DOTFILES_DIR="${DOTFILES_DIR:-$REAL_HOME/dotfiles}"
source "$DOTFILES_DIR/core.sh" || { echo "Error: core.sh not found at $DOTFILES_DIR/core.sh"; exit 1; }

# --- 📂 Infrastructure Initialization ---
# Ensure core logging and state tracking directories exist before any task execution
STATE_DIR="$DOTFILES_DIR/logs/state"
SESSION_LOG_DIR="$DOTFILES_DIR/logs/setup"
mkdir -p "$STATE_DIR" "$SESSION_LOG_DIR"

# Generate a unique Session ID and log file for the current execution
SESSION_ID=$(date +%Y%m%d_%H%M%S)
CURRENT_LOG="$SESSION_LOG_DIR/setup_$SESSION_ID.log"

# --- 🚨 Error Handling Mechanism (Trap) ---
failure() {
  local lineno=$1
  local msg=$2
  echo -e "${RED}❌ Error occurred! Line $lineno: $msg${NC}"
  exit 1
}

# Trigger failure function on any error (ERR)
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

# --- 🛠️ Functions ---

show_menu() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${CYAN}   🚀 DOTFILES PROFESSIONAL SETUP${NC}"
    echo -e "${BLUE}========================================${NC}"

    # Fetch all modular install scripts
    options=($(ls "$DOTFILES_DIR/install" | grep -E '^[0-9].*\.sh$'))

    for i in "${!options[@]}"; do
        local task_name="${options[$i]%.sh}"
        # Visual indicator for already installed modules
        if [ -f "$STATE_DIR/$task_name.done" ]; then
            echo -e "${YELLOW}$((i+1)))${NC} ${options[$i]} ${GREEN}[INSTALLED]${NC}"
        else
            echo -e "${YELLOW}$((i+1)))${NC} ${options[$i]}"
        fi
    done
    echo -e "${YELLOW}f)${NC} Force Mode (Clear all states)"
    echo -e "${YELLOW}a)${NC} Run All (Automatic Setup)"
    echo -e "${YELLOW}q)${NC} Quit"
    echo -e "${BLUE}----------------------------------------${NC}"
}

run_task() {
    local task_file="$DOTFILES_DIR/install/$1"
    local task_name="${1%.sh}"
    local state_file="$STATE_DIR/$task_name.done"

    # Persistence Check: Skip if the module is already marked as 'done'
    if [[ -f "$state_file" && "$FORCE_INSTALL" != "true" ]]; then
        echo -e "${YELLOW}Skip: $task_name (Already satisfied).${NC}"
        return 0
    fi

    echo -e "${CYAN}▶ Executing Task: $1${NC}"

    # Execution with Process Isolation: Output is mirrored to both terminal and session log
    if bash "$task_file" 2>&1 | tee -a "$CURRENT_LOG"; then
        # Record completion timestamp in the state file
        echo "Installed at: $(date)" > "$state_file"
        echo -e "${BLUE}----------------------------------------${NC}"
    else
        echo -e "${RED}❌ Task failed: $1. See $CURRENT_LOG for details.${NC}"
        exit 1
    fi
}

# --- 🚀 Main Logic ---

# Check for root privileges - setup usually needs sudo for system tasks
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run with sudo to orchestrate installations.${NC}"
   exit 1
fi

# Handle standalone force flag from CLI
if [[ "$1" == "--force" ]]; then
    echo -e "${PURPLE}🧹 Force Mode: Clearing previous installation states...${NC}"
    rm -f "$STATE_DIR"/*.done
    FORCE_INSTALL="true"
fi

# Interactive or Automated Mode Selection
if [[ "$1" == "--auto" ]]; then
    echo -e "${PURPLE}🤖 Starting Automated Setup Sequence...${NC}"
    tasks=($(ls "$DOTFILES_DIR/install" | grep -E '^[0-9].*\.sh$'))
    for task in "${tasks[@]}"; do
        run_task "$task"
    done
    echo -e "${GREEN}✅ Automated setup finished successfully.${NC}"
else
    while true; do
        show_menu
        read -p "Select an option: " choice

        case $choice in
            f|F)
                echo -e "${PURPLE}🧹 Resetting state: All modules will be re-evaluated.${NC}"
                rm -f "$STATE_DIR"/*.done
                FORCE_INSTALL="true" ;;
            q|Q)
                echo -e "${YELLOW}👋 Exiting setup...${NC}"
                break ;;
            a|A)
                echo -e "${PURPLE}🚀 Running all tasks...${NC}"
                tasks=($(ls "$DOTFILES_DIR/install" | grep -E '^[0-9].*\.sh$'))
                for task in "${tasks[@]}"; do
                    run_task "$task"
                done
                echo -e "${GREEN}✅ All tasks completed.${NC}"
                break ;;
            [0-9]*)
                idx=$((choice-1))
                if [[ "$idx" -ge 0 && "$idx" -lt "${#options[@]}" ]]; then
                    run_task "${options[$idx]}"
                else
                    echo -e "${RED}❌ Invalid option: $choice${NC}"
                fi
                ;;
            *)
                echo -e "${RED}❌ Invalid selection.${NC}"
                ;;
        esac
    done
fi
