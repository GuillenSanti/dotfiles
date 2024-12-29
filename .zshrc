# ===================================
# Oh-My-Zsh
# ===================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="santi"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting dotenv extract sudo docker docker-compose)
source $ZSH/oh-my-zsh.sh

# ===================================
# Aliases
# ===================================
# General
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Navigation
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'

# Git
alias gdm='git diff --stat  main'
alias gdom='git fetch && git diff --stat  origin/main'
alias gb-no-remote='git fetch --prune && git branch -vv | grep ": gone]" | awk "{print \$1}"'
alias gbD-no-remote='git fetch --prune && git branch -vv | grep ": gone]" | awk "{print \$1}" | xargs -r git branch -D'
alias glf="git log --stat --pretty=format:'%C(yellow)%h%Creset - %s %Cgreen(%cr)%Creset %C(bold blue)<%an>%Creset'"

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