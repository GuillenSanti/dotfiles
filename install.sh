#!/bin/zsh

# Colors for messages
green='\033[0;32m'
yellow='\033[1;33m'
blue='\033[0;34m'
nc='\033[0m' # No color

# Formatted message
print_msg() {
    echo -e "${green}[INFO]${nc} $1"
}

# Function to install pv using Homebrew
install_pv() {
    print_msg "Installing pv..."
    brew install pv
}

# Check if Homebrew is installed
if command -v brew &> /dev/null; then
    print_msg "Homebrew is already installed. Updating..."
    brew update
else
    print_msg "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    print_msg "Homebrew installed successfully."
fi

# Ensure Homebrew is in the PATH
brew_bin="/usr/local/bin/brew"
if [[ -x "$brew_bin" ]]; then
    export PATH="$brew_bin:$PATH"

    # Check if pv is installed
    if ! command -v pv &> /dev/null; then
        install_pv
    fi
else
    echo "Homebrew binary not found. Please check the installation."
    exit 1
fi

# Function to show progress of cloning using pv
clone_with_progress() {
    if [ -d "$2" ]; then
        print_msg "$2 already exists. Updating..."
        (cd "$2" && git pull origin master)
    else
        git clone --progress "$1" "$2" 2>&1 | pv -lep -s $(git ls-remote --tags --heads "$1" | wc -l)
    fi
}

# Check and update Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    print_msg "Oh My Zsh is already installed. Updating..."
    env ZSH=$ZSH sh $ZSH/tools/upgrade.sh
else
    print_msg "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    print_msg "Oh My Zsh installed successfully."
fi

# Install Zsh plugins
print_msg "Installing/Updating Zsh plugins..."
# zsh-autosuggestions
clone_with_progress https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# zsh-syntax-highlighting
clone_with_progress https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
# zsh-fzf-history-search
clone_with_progress https://github.com/joshskidmore/zsh-fzf-history-search ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-fzf-history-search

# Install or update fzf using Homebrew
if ! brew list fzf &>/dev/null; then
    print_msg "Installing fzf..."
    brew install fzf
else
    print_msg "fzf is already installed. Updating..."
    brew upgrade fzf
fi

# Specify the dotfiles directory
dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Remove existing symbolic links
print_msg "Removing existing symbolic links..."
rm -f "$HOME/.zshrc" "$HOME/.vimrc" "$ZSH/themes/santi.zsh-theme" "$HOME/.gitignore_global"

# Create new symbolic links
print_msg "Creating new symbolic links for your configuration."
ln -s "$dotfiles_dir/.zshrc" "$HOME/.zshrc"
ln -s "$dotfiles_dir/.vimrc" "$HOME/.vimrc"
ln -s "$dotfiles_dir/santi.zsh-theme" "$ZSH/themes/santi.zsh-theme"
ln -s "$dotfiles_dir/.gitignore_global" "$HOME/.gitignore_global"
print_msg "Symbolic links created successfully."

# Ensure that the files have been created correctly
ls -la "$HOME/.zshrc" "$HOME/.vimrc"

