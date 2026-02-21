. "$HOME/.cargo/env"
export GPG_TTY=$(tty)
export BUN_INSTALL="$HOME/.bun"

if [[ -f "$HOME/.zshenv.local" ]]; then
    source "$HOME/.zshenv.local"
fi

export EDITOR="nvim"
