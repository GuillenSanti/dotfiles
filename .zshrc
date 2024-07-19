# Basic Oh-My-Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="santi"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting )
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
# alias code='cd ~/Sites'  # Change this based on your projects directory
alias ..='cd ..'
alias ...='cd ../..'
alias h='history'

# Useful Functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Factorial
## aws

alias preproduction_login="aws sso login --profile=preproduction"
alias preproduction_console="instance_id=\$(aws ec2 describe-instances --profile preproduction --filters 'Name=tag:Name,Values=preproduction-blue/k8s-console' --query 'Reservations[].Instances[].InstanceId' --output text); aws ssm start-session --profile=preproduction --target \$instance_id"

alias demo_login="aws sso login --profile=demo"
alias demo_console="instance_id=\$(aws ec2 describe-instances --profile demo --filters 'Name=tag:Name,Values=demo-green/k8s-console' --query 'Reservations[].Instances[].InstanceId' --output text); aws ssm start-session --profile=demo --target \$instance_id"

alias production_login="aws sso login --profile=production"
alias production_console="instance_id=\$(aws ec2 describe-instances --profile production --filters 'Name=tag:Name,Values=production-blue/k8s-console' --query 'Reservations[].Instances[].InstanceId' --output text); aws ssm start-session --profile=production --target \$instance_id"

## local development
alias factorial_update='cd backend && bin/update'


# Exports
export PATH="$HOME/.asdf/shims:$HOME/.asdf/bin:$PATH"
. /opt/homebrew/opt/asdf/libexec/asdf.sh
export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"
eval "$(direnv hook zsh)"
