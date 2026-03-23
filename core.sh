#!/bin/bash
# ~/dotfiles/core.sh
# Shared environment variables, global constants, and helper functions.

# --- User & Directory Context ---
export REAL_USER=${REAL_USER:-${SUDO_USER:-$USER}}
export REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
export DOTFILES_DIR="${DOTFILES_DIR:-$REAL_HOME/dotfiles}"

# --- Centralized Paths ---
export SCRIPTS_DIR="$DOTFILES_DIR/scripts"
export LOG_DIR="$DOTFILES_DIR/logs"
export SS_DIR="$REAL_HOME/Pictures/Screenshots"

# --- 🔍 Debug Mode Detection ---
# Scans all arguments passed to the calling script for --debug
DEBUG_MODE=false
for arg in "$@"; do
  if [[ "$arg" == "--debug" || "$arg" == "-d" ]]; then
      DEBUG_MODE=true
      break # Flag bulunduğunda döngüden çıkmak daha verimlidir
  fi
done
export DEBUG_MODE

# --- 🎨 Common UI Colors ---
export BLUE='\033[1;34m'
export GREEN='\033[1;32m'
export RED='\033[1;31m'
export YELLOW='\033[1;33m'
export PURPLE='\033[1;35m' # Used for Debug
export NC='\033[0m'

# --- 📝 Logging Methods ---

log_info() { echo -e "\n${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "\n${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "\n${RED}[ERROR]${NC} $*"; }

# Only outputs if --debug flag is present
log_debug() {
    if [[ "$DEBUG_MODE" == true ]]; then
        echo -e "\n${PURPLE}[DEBUG]${NC} $*"
    fi
}

# --- 🛠️ Utility: prepare_logging ---
# Handles directory creation, ownership, and rotation in one go
prepare_logging() {
    local sub_dir="$1" # e.g., "updates" or "maintenance" or "storage"
    local target_dir="$LOG_DIR/$sub_dir"
    local log_file_name="$2"
    local log_path="$target_dir/$log_file_name"

    # Create directory with sudo if needed, but ensure user ownership
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir" 2>/dev/null || { sudo mkdir -p "$target_dir" && sudo chown -R "$REAL_USER":"$REAL_USER" "$LOG_DIR"; }
    fi

    # CRITICAL: Ensure the log file itself is writable by the user before 'tee'
    if [ -f "$log_path" ]; then
        [ ! -w "$log_path" ] && sudo chown "$REAL_USER":"$REAL_USER" "$log_path"
    else
        touch "$log_path"
    fi
    chmod 644 "$log_path"

    # Export for the calling script
    export CURRENT_LOG_FILE="$log_path"

    # Rotate logs (older than 30 days)
    log_debug "Rotating logs in $target_dir..."
    find "$target_dir" -type f -name "*.log" -mtime +30 -delete 2>/dev/null
}

# --- 🛠️ Utility: run_as_user ---
run_as_user() {
    local target_user="${REAL_USER:-$USER}"
    # Resolve the target user's home directory via system database to avoid SUDO_HOME mismatches
    local target_home=$(getent passwd "$target_user" | cut -d: -f6)

    log_debug "Context check -> Current: $(whoami) (UID: $(id -u)), Target: $target_user" >&2

    if [ "$(id -u)" -eq 0 ]; then
        log_debug "Elevated privileges (root) detected. Switching context to $target_user..." >&2

        # -E: Preserves the existing environment variables from the calling shell
        # env HOME=...: Forces the HOME variable to the target user's directory,
        # ensuring tools like FNM don't accidentally look into /root
        sudo -E -u "$target_user" env \
            HOME="$target_home" \
            REAL_USER="$REAL_USER" \
            REAL_HOME="$REAL_HOME" \
            FNM_DIR="$FNM_DIR" \
            DETECTED_LTS="$DETECTED_LTS" \
            DEBUG_MODE="$DEBUG_MODE" \
            bash -c "$*"
    else
        log_debug "Already running as $target_user. Executing directly..." >&2
        eval "$@"
    fi
}
