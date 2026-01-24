# ~/.zshrc

# 🔄 Environment variables
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$PATH:$HOME/.dotnet/tools"
export PATH="/opt/Windsurf:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"

# 📦 Load Rust cargo environment
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# 📦 Load bun environment (uncomment if needed)
# export BUN_INSTALL="$HOME/.bun"
# export PATH="$BUN_INSTALL/bin:$PATH"
# [ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# 🧠 Load alias file if present
if [[ -f "$HOME/.zsh_aliases" ]]; then
  source "$HOME/.zsh_aliases"
fi

# 🎨 Enable Powerline prompt
USE_POWERLINE="true"

# 🧩 Load Manjaro Zsh configurations
#if [[ -e /usr/share/zsh/manjaro-zsh-config ]]; then
#  source /usr/share/zsh/manjaro-zsh-config
#fi
if [[ -e /usr/share/zsh/manjaro-zsh-prompt ]]; then
  source /usr/share/zsh/manjaro-zsh-prompt
fi

source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh

# 🖼️ Set terminal window title for common emulators
case $TERM in
  xterm*|rxvt*|Eterm*|aterm|kterm|gnome*|interix|konsole*)
    precmd() { print -Pn "\e]0;%n@%m: %~\a" }
    ;;
  screen*)
    precmd() { print -Pn "\e_%n@%m: %~\e\\" }
    ;;
esac

# 📁 `ex` function – quick archive extractor
ex() {
  if [[ -f $1 ]]; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1   ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.zip)       unzip $1     ;;
      *.Z)         uncompress $1;;
      *.7z)        7z x $1      ;;
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# 🌈 Simple colored prompt (consider oh-my-zsh or powerlevel10k for advanced themes)
autoload -Uz show_colors
setopt prompt_subst
PROMPT='%F{green}%n@%m %F{cyan}%~ %f%# '

# 🧠 History settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# ⌨️ Completion, suggestions, and key bindings
autoload -Uz compinit && compinit
autoload -Uz bashcompinit && bashcompinit  # enable bash completions
zstyle ':completion:*' menu select
setopt auto_cd
setopt correct
setopt nocaseglob
bindkey "^[[A" up-line-or-search
bindkey "^[[B" down-line-or-search
bindkey \^U backward-kill-line

# 🔒 Allow root to open GUI apps
xhost +local:root > /dev/null 2>&1

# 🧪 `colors` helper function to show escape codes
show_colors() {
  local fgc bgc vals seq0

  printf "Color escapes are %s\n" '\e[${value};...;${value}m'
  printf "Values 30..37 are \e[33mforeground colors\e[m\n"
  printf "Values 40..47 are \e[43mbackground colors\e[m\n"
  printf "Value  1 gives a  \e[1mbold-faced look\e[m\n\n"

  for fgc in {30..37}; do
    for bgc in {40..47}; do
      vals="${fgc};${bgc}"
      seq0="\e[${vals}m"
      printf "  %-9s" "${seq0}"
      printf " ${seq0}TEXT\e[m"
      printf " \e[${vals};1mBOLD\e[m"
    done
    echo; echo
  done
}

# pnpm
export PNPM_HOME="/home/myrn/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bun completions
[ -s "/home/myrn/.bun/_bun" ] && source "/home/myrn/.bun/_bun"

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"


