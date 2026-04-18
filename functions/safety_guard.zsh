# ~/.zsh_functions.d/safety_guard.zsh

# --- 🛰️ Emergency Mode (The Escape Hatch) ---
# This function is triggered when the primary guard script is missing or fails.
# It restricts execution to a predefined whitelist of safe commands for system recovery.
emergency_mode() {
    # Whitelist of allowed commands in Emergency Mode
    local WHITELIST=("ls" "cd" "vi" "vim" "nvim" "nano" "source" "cp" "mv" "rm" "cat" "echo" "rfs" "reload" "ln" "chmod" "touch" "mkdir")

    # Split the buffer into individual commands to handle chains (&&, |, ;)
    local commands=("${(s:&&:)${(s:|:)${(s:;:)${1}}}}")
    local all_allowed=true

    for full_cmd in "${commands[@]}"; do
        # Extract the base command (first word) while handling leading spaces
        local cmd_base="${${full_cmd##[[:space:]]##}%% *}"
        local found=false

        for safe_cmd in "${WHITELIST[@]}"; do
            if [[ "$cmd_base" == "$safe_cmd" ]]; then
                found=true
                break
            fi
        done

        if [[ "$found" == "false" ]]; then
            all_allowed=false
            break
        fi
    done

    if [[ "$all_allowed" == "true" ]]; then
        # Proceed with execution if all commands in the chain are whitelisted
        zle .accept-line
    else
        # Block and notify the user
        echo -e "\n\033[1;31m❌ SAFETY ALERT: Guard failed or missing. Emergency Mode Active!\033[0m"
        echo -e "\033[1;33mOnly whitelist commands are allowed until the system is restored.\033[0m"
        echo -e "Allowed: ${WHITELIST[*]}\n"

        BUFFER="" # Clear the buffer to prevent execution
        zle -I    # Refresh the prompt
        return 1
    fi
}

# --- 🛡️ Main Interceptor Widget ---
# High-level logic to decide between the primary Guard Script and Emergency Mode.
safety-guard-widget() {
    local GUARD_PATH="$HOME/scripts/.confirm.sh"

    # Guard script file is missing entirely
    # Falls back to Emergency Mode to prevent total shell lockout.
    if [[ ! -f "$GUARD_PATH" ]]; then
        emergency_mode "$BUFFER"
        return $?
    fi

    # The script handles pattern matching against danger_zone.list and user confirmation.
    # Run script and capture its specific exit code
    "$GUARD_PATH" "$BUFFER"
    local exit_status=$?

    if [[ $exit_status -eq 0 ]]; then
        # Success or 'y'
        zle .accept-line
    elif [[ $exit_status -eq 2 ]]; then
        # User explicitly said 'n' - Just clear and stop, no Emergency Mode alert
        BUFFER=""
        zle -I
        return 1
    else
        # Critical error (exit 1) - Fallback to Emergency Mode
        emergency_mode "$BUFFER"
    fi
}

# --- ⚙️ Initialization ---
# Register the logic as a Zsh Line Editor (ZLE) widget and bind it to Enter
zle -N accept-line safety-guard-widget
