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

# Function to create a file if it doesn't exist
create_local_file() {
    local file_path="$1"
    local description="$2"

    if [ ! -f "$file_path" ]; then
        print_msg "Creating $file_path for $description..."
        touch "$file_path"

        # Add default or example content if required
        if [[ "$file_path" == *"zshrc.local" ]]; then
            echo "# Custom machine-specific configurations" > "$file_path"
            echo "# Example: export PATH=\$PATH:/some/custom/path" >> "$file_path"
            echo "# Example: alias gs='git status'" >> "$file_path"
        elif [[ "$file_path" == *"hosts.local" ]]; then
            echo "# Custom machine-specific hosts configurations" > "$file_path"
            echo "# Example: 127.0.0.1   my-custom-host.local" >> "$file_path"
            echo "# Example: 192.168.1.100 another-host.local" >> "$file_path"
        fi

        print_msg "$file_path created successfully."
    else
        print_msg "$file_path already exists."
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
rm -f "$HOME/.zshrc" "$HOME/.vimrc" "$ZSH/themes/santi.zsh-theme" "$HOME/.gitignore_global" "$HOME/.zshrc.local" "$HOME/.hosts.local"

# Specify the dotfiles directory
dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure the ZSH themes directory exists
if [ ! -d "$ZSH/themes" ]; then
    echo "Error: $ZSH/themes directory not found."
    exit 1
fi

# Create new symbolic links
create_symlink() {
    if [ ! -L "$2" ]; then
        print_msg "Creating symlink for $1..."
        ln -s "$1" "$2" || { echo "Error creating symlink for $2"; exit 1; }
    else
        print_msg "Symlink for $2 already exists."
    fi
}

# Create local configuration files in the root of dotfiles
create_local_file "$dotfiles_dir/.zshrc.local" "machine-specific Zsh configurations"
create_local_file "$dotfiles_dir/hosts.local" "machine-specific hosts configurations"

# Create symbolic links for the local files in the home directory
create_symlink "$dotfiles_dir/.zshrc.local" "$HOME/.zshrc.local"
create_symlink "$dotfiles_dir/hosts.local" "$HOME/.hosts.local"

# Create other symbolic links
create_symlink "$dotfiles_dir/.zshrc" "$HOME/.zshrc"
create_symlink "$dotfiles_dir/.vimrc" "$HOME/.vimrc"
create_symlink "$dotfiles_dir/santi.zsh-theme" "$ZSH/themes/santi.zsh-theme"
create_symlink "$dotfiles_dir/.gitignore_global" "$HOME/.gitignore_global"

print_msg "Symbolic links created successfully."

# Execute the update-hosts.sh script
print_msg "Executing update-hosts.sh script..."
if [ -f "$dotfiles_dir/update-hosts.sh" ]; then
    bash "$dotfiles_dir/update-hosts.sh" || { echo "Error executing update-hosts.sh"; exit 1; }
else
    echo "Error: update-hosts.sh not found."
    exit 1
fi
