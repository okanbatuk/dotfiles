. "$HOME/.cargo/env"
export GPG_TTY=$(tty)
export BUN_INSTALL="$HOME/.bun"
export NPM_GLOB="$HOME/.npm-global"

if [[ -f "$HOME/.zshenv.local" ]]; then
    source "$HOME/.zshenv.local"
fi

export EDITOR="nvim"
