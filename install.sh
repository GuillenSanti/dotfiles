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

    # Check if the package is already installed manually (i.e., outside of Homebrew)
    if command -v "$package" &>/dev/null; then
        # Get the path where the package is installed
        package_path=$(which "$package")

        # Check if the package is managed by Homebrew (its path should be inside Homebrew's installation directory)
        if [[ "$package_path" == /opt/homebrew/bin/* || "$package_path" == /usr/local/bin/* ]]; then
            print_msg "$package is already installed and managed by Homebrew. Updating..."
            brew upgrade "$package" || { echo "Error upgrading $package"; return 0; }
            return 0
        else
            print_msg "$package is already installed manually at $package_path. Skipping Homebrew installation."
            return 0
        fi
    fi

    # Check if a related app exists in /Applications (for GUI apps)
    apps_in_applications=()
    while IFS= read -r app; do
        apps_in_applications+=("$app")
    done < <(find /Applications -iname "*.app" -maxdepth 1)

    # Normalize the package name (lowercase and no spaces) for comparison
    normalized_package_name=$(echo "$package" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')

    for app in "${apps_in_applications[@]}"; do
        normalized_app_name=$(echo "$(basename "$app" .app)" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')

        if [[ "$normalized_app_name" == "$normalized_package_name" ]]; then
            print_msg "$package is already installed manually as $app. Skipping Homebrew installation."
            return 0
        fi
    done

    # If the package is not found, install it via Homebrew
    print_msg "Installing $package..."
    brew install "$package" || { echo "Error installing $package"; return 0; }
}

# Function to install or update a Homebrew cask package
install_or_update_brew_cask_package() {
    cask_package=$1
    print_msg "Installing $cask_package..."
    
    # Normalize the cask package name by converting it to lowercase and removing spaces
    normalized_cask_package=$(echo "$cask_package" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
    
    # Get all the app names from /Applications, normalize them (lowercase and no spaces)
    # Using a loop to process the output of find line by line
    apps_in_applications=()
    while IFS= read -r app; do
        apps_in_applications+=("$app")
    done < <(find /Applications -iname "*.app" -maxdepth 1)

    # Check if the normalized app name already exists in /Applications
    for app in "${apps_in_applications[@]}"; do
        # Normalize each app name (remove spaces and convert to lowercase)
        normalized_app_name=$(echo "$(basename "$app" .app)" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')

        # If the normalized app name matches the desired cask_package, skip installation
        if [[ "$normalized_app_name" == "$normalized_cask_package" ]]; then
            print_msg "$cask_package is already installed manually at $app. Skipping Homebrew installation."
            return 0
        fi
    done

    # If the app is not found, proceed with installation or update
    if ! brew list --cask "$cask_package" &>/dev/null; then
        print_msg "Installing $cask_package..."
        brew install --cask "$cask_package" || { echo "Error installing $cask_package"; return 0; }
    else
        print_msg "$cask_package is already installed via Homebrew. Updating..."
        brew upgrade --cask "$cask_package" || { echo "Error upgrading $cask_package"; return 0; }
    fi
}

# Function to show progress of cloning using pv
clone_with_progress() {
    local repo_url="$1"
    local dest_dir="$2"

    if [ -d "$dest_dir" ]; then
        print_msg "$dest_dir already exists. Updating..."

        # Detect the default branch of the remote repository
        local default_branch=$(git -C "$dest_dir" remote show origin | awk '/HEAD branch/ {print $NF}')
        if [ -z "$default_branch" ]; then
            print_msg "Default branch not detected. Using 'master' as fallback."
            default_branch="master"
        fi

        # Pull updates from the detected branch
        (cd "$dest_dir" && git pull origin "$default_branch") || {
            echo "Error pulling updates for $dest_dir"; 
            return 1;
        }
    else
        # Clone the repository with progress shown via pv
        git clone --progress "$repo_url" "$dest_dir" 2>&1 | pv -lep -s $(git ls-remote --tags --heads "$repo_url" | wc -l)
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

# Ensure the Sites directory exists
ensure_sites_directory() {
    local sites_dir="$HOME/Sites"

    if [ ! -d "$sites_dir" ]; then
        print_msg "Creating Sites directory in home..."
        mkdir -p "$sites_dir" || { echo "Error creating Sites directory"; exit 1; }
    else
        print_msg "Sites directory already exists."
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

# Install or update packages using Homebrew
install_or_update_brew_package "fzf"
install_or_update_brew_package "asdf"
install_or_update_brew_package "direnv"
install_or_update_brew_package "pv"
install_or_update_brew_package "tmux"
install_or_update_brew_package "meetingbar"
install_or_update_brew_cask_package "rectangle"

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
rm -f "$HOME/.zshrc" "$HOME/.vimrc" "$ZSH/custom/themes/santi.zsh-theme" "$HOME/.gitignore_global" "$HOME/.zshrc.local" "$HOME/.hosts.local"

# Specify the dotfiles directory
dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure the ZSH custom themes directory exists
if [ ! -d "$ZSH/custom/themes" ]; then
    echo "Error: $ZSH/custom/themes directory not found."
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
create_symlink "$dotfiles_dir/santi.zsh-theme" "$ZSH/custom/themes/santi.zsh-theme"
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

ensure_sites_directory
