#!/bin/zsh

# Colors for messages
green='\033[0;32m'
no_color='\033[0m'

# Formatted message
print_msg() {
    echo -e "${green}[INFO]${no_color} $1"
}

# Specify the dotfiles directory
dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to show progress of cloning using pv
clone_with_progress() {
    local repo_url="$1"
    local dest_dir="$2"

    if [ -d "$dest_dir" ]; then
        print_msg "$dest_dir already exists. Updating..."
        (cd "$dest_dir" && git pull --ff-only) || {
            print_msg "Error pulling updates for $dest_dir"
            return 1
        }
    else
        # Prefer a shallow clone; if pv is available show progress, otherwise do a normal shallow clone
        if command -v pv >/dev/null 2>&1; then
            git clone --progress --depth 1 "$repo_url" "$dest_dir" 2>&1 | pv -lep -s $(git ls-remote --tags --heads "$repo_url" | wc -l) || {
                print_msg "Error cloning $repo_url"
                return 1
            }
        else
            git clone --depth 1 "$repo_url" "$dest_dir" || {
                print_msg "Error cloning $repo_url"
                return 1
            }
        fi
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

update_gitconfig() {
    local dotfiles_gitconfig="$dotfiles_dir/.gitconfig"
    local current_gitconfig="$HOME/.gitconfig"

    if [ ! -f "$dotfiles_gitconfig" ]; then
        print_msg "Dotfiles .gitconfig file not found. Skipping Git configuration update."
        return
    fi

    print_msg "Updating .gitconfig with dotfiles values..."

    local section=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(echo "$line" | xargs)

        # Remove empty lines
        if [[ -z "$line" ]]; then
            continue
        fi

        if [[ "$line" == \[*\] ]]; then
            section="${line//[[:space:]]/}"
            section="${section//[[]/}"
            section="${section//[]]/}"
        else
            local key=$(echo "$line" | cut -d '=' -f 1 | xargs)
            local value=$(echo "$line" | cut -d '=' -f 2- | xargs)

            if [[ -n "$key" && -n "$value" && -n "$section" ]]; then
                git config --global "$section.$key" "$value" || {
                    echo "Error setting git config for $section.$key"
                    return 1
                }
            fi
        fi
    done < "$dotfiles_gitconfig"

    print_msg ".gitconfig updated successfully."
}

# Merge claude/hooks.json into ~/.claude/settings.json, keeping everything else.
# Claude Code rewrites that file itself, so it can't be a symlink.
merge_claude_hooks() {
    local settings="$HOME/.claude/settings.json"
    local hooks="$dotfiles_dir/claude/hooks.json"

    mkdir -p "$HOME/.claude"
    [ -f "$settings" ] || echo '{}' > "$settings"

    print_msg "Merging Claude Code hooks into $settings..."
    if jq --slurpfile h "$hooks" '
        reduce ($h[0].hooks | to_entries[]) as $e (.;
            .hooks[$e.key] = ((.hooks[$e.key] // []) + $e.value | unique))
    ' "$settings" > "$settings.tmp"; then
        mv "$settings.tmp" "$settings"
        print_msg "Claude Code hooks merged successfully."
    else
        rm -f "$settings.tmp"
        echo "Error merging Claude Code hooks"
    fi
}

# Point Claude Code's status line at claude/statusline.py (linked into ~/.claude), keeping everything else.
set_claude_statusline() {
    local settings="$HOME/.claude/settings.json"

    print_msg "Setting the Claude Code status line in $settings..."
    if jq '.statusLine = {"type": "command", "command": "/usr/bin/python3 ~/.claude/statusline.py"}' \
        "$settings" > "$settings.tmp"; then
        mv "$settings.tmp" "$settings"
        print_msg "Claude Code status line set."
    else
        rm -f "$settings.tmp"
        echo "Error setting the Claude Code status line"
    fi
}

# Check if Homebrew is installed, if not, install it
if ! command -v brew &> /dev/null; then
    print_msg "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || { echo "Error installing Homebrew"; exit 1; }
    # The installer doesn't add brew to this script's PATH
    eval "$(/opt/homebrew/bin/brew shellenv)"
    print_msg "Homebrew installed successfully."
else
    print_msg "Homebrew is already installed. Updating..."
    brew update || { echo "Error updating Homebrew"; exit 1; }
fi

# Install or upgrade everything in the Brewfile
print_msg "Installing Homebrew packages from the Brewfile..."
brew bundle --file="$dotfiles_dir/Brewfile" || echo "Error installing some Homebrew packages"

# Claude Code comes from its own installer, not Homebrew: it updates itself and the cask lags behind
if ! command -v claude &> /dev/null && [ ! -x "$HOME/.local/bin/claude" ]; then
    print_msg "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash || echo "Error installing Claude Code"
else
    print_msg "Claude Code is already installed. It updates itself."
fi

# opencode too, into ~/.opencode/bin, which .zshrc already puts on the PATH
if ! command -v opencode &> /dev/null && [ ! -x "$HOME/.opencode/bin/opencode" ]; then
    print_msg "Installing opencode..."
    curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path || echo "Error installing opencode"
else
    print_msg "opencode is already installed. Upgrade it with opencode upgrade."
fi

# Check and update Oh My Zsh
# Ensure ZSH variables have sensible defaults
ZSH=${ZSH:-$HOME/.oh-my-zsh}
ZSH_CUSTOM=${ZSH_CUSTOM:-$ZSH/custom}

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
clone_with_progress https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
clone_with_progress https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
clone_with_progress https://github.com/joshskidmore/zsh-fzf-history-search "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-fzf-history-search"

# Remove existing symbolic links
print_msg "Removing existing symbolic links..."
rm -f "$HOME/.zshrc" "$HOME/.vimrc" "$ZSH/custom/themes/santi.zsh-theme" "$HOME/.gitignore_global" "$HOME/.zshrc.local" "$HOME/.hosts.local" "$HOME/.tmux.conf" "$HOME/.tmuxp/main.yaml" "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty" "$HOME/.config/opencode/AGENTS.md" "$HOME/.claude/CLAUDE.md"

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
create_symlink "$dotfiles_dir/.tmux.conf" "$HOME/.tmux.conf"

# Ensure ~/.tmux directory exists before symlinking scripts
mkdir -p "$HOME/.tmux"
create_symlink "$dotfiles_dir/tmux/battery.sh" "$HOME/.tmux/battery.sh"
create_symlink "$dotfiles_dir/tmux/caffeinate.sh" "$HOME/.tmux/caffeinate.sh"

# cafe-on, cafe-off and cafe-status as commands, so agents' shells find them without .zshrc's aliases
mkdir -p "$HOME/.local/bin"
for cafe in cafe-on cafe-off cafe-status; do
    create_symlink "$dotfiles_dir/tmux/cafe.py" "$HOME/.local/bin/$cafe"
done
create_symlink "$dotfiles_dir/tmux/attention.sh" "$HOME/.tmux/attention.sh"
# The deck (the home dashboard) is a repo of its own: cloned into deck/, it links its own commands
clone_with_progress https://github.com/GuillenSanti/deck.git "$dotfiles_dir/deck"
"$dotfiles_dir/deck/install.sh"

# Ensure ~/.tmuxp directory exists before symlinking the tmuxp layout
mkdir -p "$HOME/.tmuxp"
create_symlink "$dotfiles_dir/tmux/main.yaml" "$HOME/.tmuxp/main.yaml"

mkdir -p "$HOME/.config/opencode/plugins"
create_symlink "$dotfiles_dir/opencode/plugins/attention.js" "$HOME/.config/opencode/plugins/attention.js"
create_symlink "$dotfiles_dir/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"

mkdir -p "$HOME/.claude"
create_symlink "$dotfiles_dir/claude/statusline.py" "$HOME/.claude/statusline.py"
# Claude Code reads the same global rules as opencode
create_symlink "$dotfiles_dir/opencode/AGENTS.md" "$HOME/.claude/CLAUDE.md"

# And Codex too
mkdir -p "$HOME/.codex"
create_symlink "$dotfiles_dir/opencode/AGENTS.md" "$HOME/.codex/AGENTS.md"

# Ghostty reads its config on macOS from Application Support
ghostty_dir="$HOME/Library/Application Support/com.mitchellh.ghostty"
mkdir -p "$ghostty_dir"
create_symlink "$dotfiles_dir/ghostty/config.ghostty" "$ghostty_dir/config.ghostty"

print_msg "Symbolic links created successfully."

merge_claude_hooks
set_claude_statusline
update_gitconfig

# Execute the update-hosts.sh script
print_msg "Executing update-hosts.sh script..."
if [ -f "$dotfiles_dir/update-hosts.sh" ]; then
    bash "$dotfiles_dir/update-hosts.sh" || { echo "Error executing update-hosts.sh"; exit 1; }
else
    echo "Error: update-hosts.sh not found."
    exit 1
fi

ensure_sites_directory

# Check what's committed here with gitleaks (.githooks/pre-commit)
git -C "$dotfiles_dir" config core.hooksPath .githooks

# Your private parts, when there are some, go last: they may replace links made above
if [ -x "$dotfiles_dir/private/install.sh" ]; then
    print_msg "Executing private/install.sh..."
    "$dotfiles_dir/private/install.sh"
fi
