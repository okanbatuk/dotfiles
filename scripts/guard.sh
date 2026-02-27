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

# --- Check if the command is blacklisted ---
check_blacklist() {
    local cmd_to_run="$*"

    for blocked in "${BLACKLIST[@]}"; do
        if [[ "$cmd_to_run" == *"$blocked"* ]]; then
            return 1
        fi
    done
    return 0
}

# --- Guard Logic ---
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
