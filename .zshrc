# ~/.zshrc

# 🔄 Path & Environment
export PATH="$HOME/.cargo/bin:$HOME/.dotnet/tools:/opt/Windsurf:$HOME/.npm-global/bin:$PATH"
[[ ":$PATH:" != *":$PNPM_HOME:"* ]] && export PATH="$PNPM_HOME:$PATH"

# 📦 Load Toolchains
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# 🧠 Load Alias & Functions files
[[ -f "$HOME/.zsh_aliases" ]] && source "$HOME/.zsh_aliases"
[[ -f "$HOME/.zsh_functions" ]] && source "$HOME/.zsh_functions"

# 🧩 Manjaro & FZF
[[ -e /usr/share/zsh/manjaro-zsh-prompt ]] && source /usr/share/zsh/manjaro-zsh-prompt
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# 🧩 Plugins & Highlighting
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# 📁 History & Completion
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS INC_APPEND_HISTORY SHARE_HISTORY
autoload -Uz compinit && compinit
autoload -Uz bashcompinit && bashcompinit
setopt auto_cd correct nocaseglob

# ⌨️ Vim-Style & Smart History Search
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# Smart Arrow Bindings
bindkey "^[[A" up-line-or-beginning-search # Up Arrow
bindkey "^[[B" down-line-or-beginning-search # Down Arrow
bindkey \^U backward-kill-line

# History Back (Ctrl+K / Ctrl+J)
bindkey '^K' up-line-or-beginning-search
bindkey '^J' down-line-or-beginning-search

# Delete All Line / Delete Keyword (Ctrl+U / Ctrl+W)
bindkey '^U' backward-kill-line
bindkey '^W' backward-kill-word

WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# 📁 Advanced Completion
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# 🚀 Initializers
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# 🔒 Misc
xhost +local:root > /dev/null 2>&1

# OpenClaw Completion
#source <(openclaw completion --shell zsh)
