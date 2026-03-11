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

if [ -f "$CORE_ENV" ]; then
    source "$CORE_ENV"
else
    # Fallback to current dir if not in scripts/
    source "$CORE_DIR/core.sh" 2>/dev/null || { echo "Error: core.sh not found"; exit 1; }
fi

show_menu() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${CYAN}   🚀 DOTFILES INTERACTIVE SETUP${NC}"
    echo -e "${BLUE}========================================${NC}"

    # List files excluding 00-header.sh
    options=($(ls "$DOTFILES_DIR/install" | grep -v "00-header.sh"))

    for i in "${!options[@]}"; do
        echo -e "${YELLOW}$((i+1)))${NC} ${options[$i]}"
    done
    echo -e "${YELLOW}a)${NC} Run All (Automatic Setup)"
    echo -e "${YELLOW}q)${NC} Quit"
    echo -e "${BLUE}----------------------------------------${NC}"
}

run_task() {
    local task_file="$DOTFILES_DIR/install/$1"
    if [ -f "$task_file" ]; then
        echo -e "${GREEN}▶ Executing: $1${NC}"
        bash "$task_file"
        echo -e "${BLUE}----------------------------------------${NC}"
    fi
}

# Main Logic
if [[ "$1" == "--auto" ]]; then
    # Auto mode (skips menu)
    tasks=($(ls "$DOTFILES_DIR/install" | grep -E '^[0-9].*\.sh$'))
    for task in "${tasks[@]}"; do
        run_task "$task"
    done
else
    # Interactive mode
    while true; do
        show_menu
        read -p "Select an option: " choice

        case $choice in
            q|Q)
                echo -e "${YELLOW}👋 Exiting...${NC}"
                break ;;
            a|A)
                tasks=($(ls "$DOTFILES_DIR/install" | grep -E '^[0-9].*\.sh$'))
                for task in "${tasks[@]}"; do
                    run_task "$task"
                done
                break ;;
            [0-9]*)
                if [[ "$choice" -gt 0 && "$choice" -le "${#options[@]}" ]]; then
                    run_task "${options[$((choice-1))]}"
                else
                    echo -e "${RED}❌ Invalid number!${NC}"
                fi ;;
            *)
                echo -e "${RED}❌ Invalid option!${NC}" ;;
        esac
    done
fi
