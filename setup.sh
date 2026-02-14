#!/bin/bash
source "$(dirname "$0")/install/00-core.sh"

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
    # Automatic mode (skips menu)
    for task in $(ls "$DOTFILES_DIR/install" | grep -v "00-header.sh"); do
        run_task "$task"
    done
else
    # Interactive mode
    while true; do
        show_menu
        read -p "Select an option: " choice

        if [[ "$choice" == "q" ]]; then
            break
        elif [[ "$choice" == "a" ]]; then
            for task in $(ls "$DOTFILES_DIR/install" | grep -v "00-header.sh"); do
                run_task "$task"
            done
            break
        elif [[ "$choice" -gt 0 && "$choice" -le "${#options[@]}" ]]; then
            run_task "${options[$((choice-1))]}"
        else
            echo -e "${RED}Invalid option!${NC}"
        fi
    done
fi
