# ===================================
# Oh-My-Zsh
# ===================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="santi"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting dotenv extract)

source $ZSH/oh-my-zsh.sh

# ===================================
# Performance Optimizations
# ===================================

# Optimize zsh-autosuggestions
ZSH_AUTOSUGGEST_USE_ASYNC=true
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Optimize zsh-syntax-highlighting
ZSH_HIGHLIGHT_MAXLENGTH=300
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)

# ===================================
# Aliases
# ===================================
# General
# alias ls='eza --icons'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Navigation
alias cd..='cd ..'
alias ..='cd ..'
alias agents-history='~/.tmux/agents-history.py'  # every agent CLI session, with fzf
alias ...='cd ../..'

# caffeinate: cafe-on, cafe-off and cafe-status are tmux/cafe.py, linked in ~/.local/bin
unalias cafe-on cafe-off cafe-status 2>/dev/null  # the old aliases, in shells that load this again

# Git
alias gdm='git diff --stat  main'
alias gdom='git fetch && git diff --stat  origin/main'
alias gb-gone='git fetch --prune && git branch -vv | grep ": gone]" | awk "{print \$1}"'
alias gbD-gone='git fetch --prune && git branch -vv | grep ": gone]" | awk "{print \$1}" | xargs -r git branch -D'
alias gbD-gone-safe='gbD_gone_safe'
alias glf="git log --stat --pretty=format:'%C(yellow)%h%Creset - %s %Cgreen(%cr)%Creset %C(bold blue)<%an>%Creset'"
alias gls="git log --pretty=format:'%C(yellow)%h%Creset - %s %Cgreen(%cr)%Creset %C(bold blue)<%an>%Creset'"

gbD_gone_safe() {
  git fetch --prune
  gone=$(git branch -vv | grep ": gone]" | awk '{print $1}')

  if [ -z "$gone" ]; then
    echo "✅ No gone branches found."
  else
    echo -e "\n🧼 The following branches have gone remotes and can be deleted:\n"
    echo "$gone"
    echo
    read "answer?❓ Do you want to delete these branches? (y/N) "
    if [[ "$answer" == "y" ]]; then
      echo "$gone" | xargs -r git branch -D
    else
      echo "✅ Nothing deleted."
    fi
  fi
}

# Useful Functions
mkcd() {
  if [ -d "$1" ]; then
    echo "Directory $1 already exists."
    cd "$1"
  else
    mkdir -p "$1" && cd "$1"
  fi
}

# Load system-specific configurations
if [ -f "$HOME/.zshrc.local" ]; then
    source "$HOME/.zshrc.local"
fi

export GPG_TTY=$(tty)
eval "$(direnv hook zsh)"

# asdf
export PATH="/opt/homebrew/opt/asdf/bin:$PATH"
export PATH="/opt/homebrew/opt/asdf/shims:$PATH"
. "/opt/homebrew/opt/asdf/libexec/asdf.sh"

# tmux
export DISABLE_AUTO_TITLE='true'

# Flag the tmux window when a command finishes while you're on another one
if [[ -n $TMUX ]]; then
  _attention_preexec() { _attention_ran=1 }
  _attention_precmd() {
    [[ -n $_attention_ran ]] || return
    unset _attention_ran
    ~/.tmux/attention.sh done &!
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook preexec _attention_preexec
  add-zsh-hook precmd _attention_precmd
fi

# Local bin
export PATH="$HOME/.local/bin:$PATH"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
