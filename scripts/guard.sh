#!/bin/bash
# guard.sh - A central security proxy for package upgrades

# --- Configuration: The Blacklist ---
# Any command starting with these patterns will be blocked if run as root
BLACKLIST=(
    # --- Node.js & JS Ecosystem ---
    "npm upgrade -g"
    "npm install -g"
    "npm update -g"
    "yarn global add"
    "pnpm add -g"
    "bun install -g"

    # --- Other Package Managers (Avoid Root Pollution) ---
    "cargo install"
    "pip install"
    "gem install"

    # --- High-Risk Operations (Safety Nets) ---
    # These remain blocked for root to prevent irreversible system-wide permission damage.
    "rm -rf / "
    "chmod -R 777"
    "chown -R root"
)

# --- Check if the command exists in the system ---
check_command_exists() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "❌ Error: Command '$1' not found in your system."
        exit 127 # Standard "command not found" exit code
    fi
}

# --- Check if the command is blacklisted ---
check_blacklist() {
    local cmd_to_run="$*"
    for blocked in "${BLACKLIST[@]}"; do
        local pattern="${blocked// / +}"
        if echo "$cmd_to_run" | grep -qiE "$pattern"; then
            return 1
        fi
    done
    return 0
}

# --- Guard Logic ---
# First, check if the binary even exists
check_command_exists "$1"

# Then, proceed with root pollution check
if [ "$EUID" -eq 0 ]; then
    if ! check_blacklist "$@"; then
        echo -e "\n🛑 ${RED}GUARD: Operation Blocked!${NC}"
        echo -e "💡 You are trying to run '${YELLOW}$*${NC}' as root."
        echo -e "❌ This command is blacklisted for root to prevent permission pollution.\n"
        exit 1
    fi
fi

# If safe or not root, execute the command
exec "$@"
