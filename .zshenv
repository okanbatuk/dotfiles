# ~/.zshenv
# This file is sourced for ALL zsh instances (interactive and non-interactive).
# Perfect for environment variables that scripts and the shell both need.

# --- User & Directory Context ---
# Dynamically resolve the real user even when using sudo
export REAL_USER=${USER:-$(id -u -n)}
export REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
export DOTFILES_DIR="$REAL_HOME/dotfiles"
export SCRIPTS_DIR="$REAL_HOME/scripts"

# --- Toolchain Paths ---
export BUN_INSTALL="$REAL_HOME/.bun"
export CARGO_HOME="$REAL_HOME/.cargo"
export GPG_TTY=$(tty)
export EDITOR="nvim"

# --- Advanced Path Management ---
# PATH Reset & Reconstruction
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# typeset -U ensures unique entries in the PATH array
typeset -U path PATH
path=(
    "$REAL_HOME/.local/share/fnm"
    "$REAL_HOME/.local/share/fnm/node-versions/$(ls $REAL_HOME/.local/share/fnm/node-versions 2>/dev/null | head -n 1)/bin"
    "$BUN_INSTALL/bin"
    "$CARGO_HOME/bin"
    "$REAL_HOME/.local/bin"
    "/opt/Windsurf"
    $path
)

# --- Toolchain Initializations ---
# Load Cargo (Rust) environment if it exists
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# --- Local Overrides ---
# Load machine-specific environment variables that shouldn't be in git
if [[ -f "$HOME/.zshenv.local" ]]; then
    source "$HOME/.zshenv.local"
fi
