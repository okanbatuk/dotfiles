#!/bin/bash
# .confirm.sh - Global Command Interceptor Logic
# Purpose: Protects the user from accidental execution of destructive commands.

# --- Core Environment Import ---
# Using the streamlined import method leveraging .zshenv variables
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
source "$DOTFILES_DIR/core.sh" || { echo "Error: core.sh not found"; exit 1; }

# Resolve list file path
LIST_FILE="$DOTFILES_DIR/hints/danger_zone.list"
CMD_TO_CHECK="$*"

# --- Pre-flight Check: Ensure the danger zone list exists ---
if [[ ! -f "$LIST_FILE" ]]; then
    log_error "Danger list missing! Guard cannot proceed without $LIST_FILE"
    exit 1 # Stop execution immediately
fi

# --- Content Validation & Sanitization ---
# Filters out comments and empty lines to extract actual patterns
if command -v rg &> /dev/null; then
    VALID_CONTENT=$(rg -v '^\s*(#|$)' "$LIST_FILE" | rg '^[a-zA-Z0-9_-]+')
else
    VALID_CONTENT=$(grep -vE '^\s*(#|$)' "$LIST_FILE" | grep -E '^[a-zA-Z0-9_-]+')
fi

# Stage 1: Basic Existence Check
# Ensure the list is not physically empty or filled with junk
if [[ -z "$VALID_CONTENT" ]]; then
    log_error "Validation failed: No valid command patterns found in $LIST_FILE"
    log_error "Danger list is empty or contains invalid junk! Add at least one real pattern (e.g., 'rm -rf')."
    exit 1
fi

# Stage 2: Semantic Validation (Mandatory Patterns)
# Ensure the guard actually protects against the most critical commands
MANDATORY_PATTERNS=("rm -rf" "git reset --hard" "docker system prune")
missing_patterns=()

for pattern in "${MANDATORY_PATTERNS[@]}"; do
    # Efficiently check for mandatory patterns within the valid content string
    if command -v rg &> /dev/null; then
        echo "$VALID_CONTENT" | rg -qF "$pattern" || missing_patterns+=("$pattern")
    else
        echo "$VALID_CONTENT" | grep -qF "$pattern" || missing_patterns+=("$pattern")
    fi
done

# Block execution if core protection patterns are missing
if [[ ${#missing_patterns[@]} -ne 0 ]]; then
    log_error "Safety breach: Mandatory patterns are missing from the danger list!"
    log_warn "The guard refuses to start without: ${RED}${missing_patterns[*]}${NC}"
    log_info "Please update: $LIST_FILE"
    exit 1
fi

# Read validated patterns into array for the interceptor logic
mapfile -t DANGER_ZONE < <(echo "$VALID_CONTENT")

# Iterate through patterns to find matches
for danger in "${DANGER_ZONE[@]}"; do
    if [[ "$CMD_TO_CHECK" == *"$danger"* ]]; then
        log_warn "DESTRUCTIVE ACTION DETECTED"
        log_info "Command: ${RED}$CMD_TO_CHECK${NC}"
        log_info "Pattern matched: ${CYAN}$danger${NC}\n"

        # User confirmation with standard prompt
        echo -n -e "${YELLOW}[?]${NC} Are you absolutely sure? (y/n): "
        read -r choice < /dev/tty

        case "$choice" in
            [yY]* )
                log_success "Authorization granted. Proceeding..."
                exit 0
                ;;
            * )
                log_error "Execution blocked by Safety Guard."
                exit 2
                ;;
        esac
    fi
done

exit 0 # No danger patterns found, safe to proceed
