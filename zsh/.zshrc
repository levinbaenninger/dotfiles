# ----------
# PATH setup
# ----------
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# -----------------
# zsh options
# -----------------
setopt AUTO_CD
setopt CORRECT
setopt EXTENDED_GLOB
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# -----------------
# History config
# -----------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

# -----------------
# Completion system
# -----------------
autoload -Uz compinit
compinit

# Improve completion UX
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# -----------------
# Starship prompt
# -----------------
eval "$(starship init zsh)"

# -----------------
# zoxide (smart cd)
# -----------------
eval "$(zoxide init zsh)"

# -----------------
# atuin (shell history)
# -----------------
eval "$(atuin init zsh)"

# -----------------
# fzf integration
# -----------------
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border --prompt='❯ '"

# -----------------
# Aliases – Modern replacements
# -----------------

# File listing & navigation
alias ls="eza --group-directories-first"
alias ll="eza -lah --group-directories-first"
alias la="eza -a"
alias tree="eza --tree"

# File viewing & search
alias cat="bat"
alias find="fd"
alias grep="rg"

# Disk & process tools
alias du="dust"
alias df="duf"
alias ps="procs"

# Navigation
alias cd="z"
alias cdi="zi"

# Help & docs
alias help="tldr"
alias man="batman"

# -----------------
# Git aliases
# -----------------
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gcm="git commit -m"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias gds="git diff --staged"

alias lg="lazygit"

# -----------------
# IDE shortcuts
# -----------------
alias code="code ."
alias cursor="cursor ."
alias webstorm="webstorm ."
alias rider="rider ."

# -----------------
# Misc quality-of-life
# -----------------
alias reload="source ~/.zshrc"
alias cls="clear"

# -----------------
# zsh-autosuggestions and zsh-syntax-highlighting
# -----------------
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# opencode
export PATH=/Users/levin/.opencode/bin:$PATH

# Android SDK
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Java
export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home

# bun completions
[ -s "/Users/levin/.bun/_bun" ] && source "/Users/levin/.bun/_bun"

# pnpm
export PNPM_HOME="/Users/levin/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end

# Vite+ bin (https://viteplus.dev) — sourced last so its bin wins position 1 in PATH
. "$HOME/.vite-plus/env"

# Pi
export PATH="/Users/levin/.vite-plus/js_runtime/node/24.18.0/bin:$PATH"
