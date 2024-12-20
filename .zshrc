# ===================================
# Oh-My-Zsh
# ===================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="santi"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting )
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
alias ga='git add'
alias gc='git commit -m'
alias gs='git status'
alias gd='git diff'
alias gdm='git --no-pager diff --stat  main'
alias gdom='git fetch && git --no-pager diff --stat  origin/main'
alias gl='git log --oneline --decorate --all --graph'
alias gb='git --no-pager branch'
alias gb-no-remote='git fetch --prune && git branch -vv | grep ": gone]" | awk "{print \$1}"'
alias gbD-no-remote='git fetch --prune && git branch -vv | grep ": gone]" | awk "{print \$1}" | xargs -r git branch -D'
alias glf="git log --stat --pretty=format:'%C(yellow)%h%Creset - %s %Cgreen(%cr)%Creset %C(bold blue)<%an>%Creset'"

# Programmer
# alias code='cd ~/Sites'  # Change this based on your projects directory
alias h='history'

# Useful Functions
mkcd() {
  if [ -d "$1" ]; then
    echo "Directory $1 already exists."
    cd "$1"
  else
    mkdir -p "$1" && cd "$1"
  fi
}

# Factorial
## aws

alias preproduction_login="aws sso login --profile=preproduction"
alias preproduction_console="instance_id=\$(aws ec2 describe-instances --profile preproduction --filters 'Name=tag:Name,Values=preproduction-blue/k8s-console' --query 'Reservations[].Instances[].InstanceId' --output text); aws ssm start-session --profile=preproduction --target \$instance_id"

alias demo_login='aws sso login --profile=demo && eval "$(aws configure export-credentials --profile development --format env)"'
alias demo_console="instance_id=\$(aws ec2 describe-instances --profile demo --filters 'Name=tag:Name,Values=demo-green/k8s-console' --query 'Reservations[].Instances[].InstanceId' --output text); aws ssm start-session --profile=demo --target \$instance_id"

alias production_login="aws sso login --profile=production"
alias production_console="instance_id=\$(aws ec2 describe-instances --profile production --filters 'Name=tag:Name,Values=production-blue/k8s-console' --query 'Reservations[].Instances[].InstanceId' --output text); aws ssm start-session --profile=production --target \$instance_id"

alias development_login='aws sso login --profile=development && eval "$(aws configure export-credentials --profile development --format env)"'

## local development
alias factorial_update='cd backend && bin/update'

# PATH Configuration
# ===================================
export PATH="$HOME/.asdf/shims:$HOME/.asdf/bin:$PATH"
. /opt/homebrew/opt/asdf/libexec/asdf.sh
export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"
export GPG_TTY=$(tty)
export PATH="/opt/homebrew/opt/make/libexec/gnubin:$PATH"

eval "$(direnv hook zsh)"
export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"
export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"
