# Basic Oh-My-Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="santi"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-fzf-history-search)
source $ZSH/oh-my-zsh.sh

# Aliases
# alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'

# Git
alias ga='git add'
alias gc='git commit -m'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --decorate --all --graph'

# Programmer
alias code='cd ~/Sites'  # Change this based on your projects directory
alias ..='cd ..'
alias ...='cd ../..'
alias h='history'

# Useful Functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}