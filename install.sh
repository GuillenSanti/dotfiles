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

# Function to install or update a Homebrew package
install_or_update_brew_package() {
    package=$1
    if ! brew list "$package" &>/dev/null; then
        print_msg "Installing $package..."
        brew install "$package" || { echo "Error installing $package"; exit 1; }
    else
        print_msg "$package is already installed. Updating..."
        brew upgrade "$package" || { echo "Error upgrading $package"; exit 1; }
    fi
}

# Function to show progress of cloning using pv
clone_with_progress() {
    if [ -d "$2" ]; then
        print_msg "$2 already exists. Updating..."
        (cd "$2" && git pull origin main || git pull origin master)
    else
        git clone --progress "$1" "$2" 2>&1 | pv -lep -s $(git ls-remote --tags --heads "$1" | wc -l)
    fi
}

# Function to create zshrc.local if it doesn't exist
create_local_zshrc() {
    local local_zshrc="$HOME/.zshrc.local"
    if [ ! -f "$local_zshrc" ]; then
        print_msg "Creating $local_zshrc for machine-specific configurations..."
        touch "$local_zshrc"

        # Add default settings or example configurations here
        echo "# Custom machine-specific configurations" > "$local_zshrc"
        echo "# Example: export PATH=\$PATH:/some/custom/path" >> "$local_zshrc"
        echo "# Example: alias gs='git status'" >> "$local_zshrc"

        print_msg "$local_zshrc created successfully."
    else
        print_msg "$local_zshrc already exists."
    fi
}

# Check if Homebrew is installed, if not, install it
if ! command -v brew &> /dev/null; then
    print_msg "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || { echo "Error installing Homebrew"; exit 1; }
    print_msg "Homebrew installed successfully."
else
    print_msg "Homebrew is already installed. Updating..."
    brew update || { echo "Error updating Homebrew"; exit 1; }
fi

# Install or update essential packages using Homebrew
install_or_update_brew_package "fzf"
install_or_update_brew_package "asdf"
install_or_update_brew_package "direnv"
install_or_update_brew_package "pv"

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

# Remove existing symbolic links
print_msg "Removing existing symbolic links..."
rm -f "$HOME/.zshrc" "$HOME/.vimrc" "$ZSH/themes/santi.zsh-theme" "$HOME/.gitignore_global"

# Ensure the ZSH themes directory exists
if [ ! -d "$ZSH/themes" ]; then
    echo "Error: $ZSH/themes directory not found."
    exit 1
fi

# Specify the dotfiles directory
dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create new symbolic links if they don't already exist
create_symlink() {
    if [ ! -L "$2" ]; then
        print_msg "Creating symlink for $1..."
        ln -s "$1" "$2" || { echo "Error creating symlink for $2"; exit 1; }
    else
        print_msg "Symlink for $2 already exists."
    fi
}

create_symlink "$dotfiles_dir/.zshrc" "$HOME/.zshrc"
create_symlink "$dotfiles_dir/.vimrc" "$HOME/.vimrc"
create_symlink "$dotfiles_dir/santi.zsh-theme" "$ZSH/themes/santi.zsh-theme"
create_symlink "$dotfiles_dir/.gitignore_global" "$HOME/.gitignore_global"

print_msg "Symbolic links created successfully."

# Ensure that the files have been created correctly
ls -la "$HOME/.zshrc" "$HOME/.vimrc"

# After ensuring Homebrew and packages are installed, call the function to create ~/.zshrc.local
create_local_zshrc

# Execute the update-hosts.sh script
print_msg "Executing update-hosts.sh script..."
if [ -f "$dotfiles_dir/update-hosts.sh" ]; then
    bash "$dotfiles_dir/update-hosts.sh" || { echo "Error executing update-hosts.sh"; exit 1; }
else
    echo "Error: update-hosts.sh not found."
    exit 1
fi
