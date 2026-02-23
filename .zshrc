# ~/.zshrc

# 🔄 Path & Environment
typeset -U path PATH

# 🔄 Path & Environment
path=(
    "$BUN_INSTALL/bin"
    "$HOME/.cargo/bin"
    "/opt/Windsurf"
    "$HOME/.npm-global/bin"
    "$HOME/.local/bin"
    $path
)
# ⚡ Initialize Completion System (Sadece bir kez çağrılması yeterlidir)
autoload -U compinit && compinit
autoload -Uz bashcompinit && bashcompinit

# 📦 Load Toolchains & Completions
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# 🧠 Load Alias & Env Variables files
[[ -f "$HOME/.zsh_aliases" ]] && source "$HOME/.zsh_aliases"
[[ -f "$HOME/.zshenv" ]] && source "$HOME/.zshenv"
[[ -f "$HOME/.zsh_notes" ]] && source "$HOME/.zsh_notes"


# Load custom functions from the modular directory
if [ -d "$HOME/.zsh_functions.d" ]; then
  for func_file in "$HOME/.zsh_functions.d"/*; do
    # Only source if it's a file and readable
    [ -f "$func_file" ] && source "$func_file"
  done
fi


# 🧩 Manjaro & FZF
[[ -e /usr/share/zsh/manjaro-zsh-prompt ]] && source /usr/share/zsh/manjaro-zsh-prompt
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# 🧩 Plugins & Highlighting
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# Terminal Title Integration
preexec() { print -Pn "\e]0;$1\a" }
precmd() { print -Pn "\e]0;%n@%m: %~\a" }

# 📁 History & Completion
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS INC_APPEND_HISTORY SHARE_HISTORY
setopt auto_cd correct nocaseglob

# ⌨️ Vim-Style & Smart History Search
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
bindkey '^K' up-line-or-beginning-search
bindkey '^J' down-line-or-beginning-search
bindkey '^U' backward-kill-line
bindkey '^W' backward-kill-word

WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# 📁 Advanced Completion Styles
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# 🚀 Initializers
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

# 🔒 Misc
xhost +local:root > /dev/null 2>&1

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
