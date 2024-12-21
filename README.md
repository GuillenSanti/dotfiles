# Dotfiles

This repository contains my personal dotfiles and configuration settings for various tools I use across different systems.

## Installation

To get started with these dotfiles, follow these steps:

1. **Clone the repository**:

    First, clone this repository to your machine:

    ```bash
    git clone https://github.com/GuillenSanti/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    ```

2. **Run the installation script**:

    The `install.sh` script will set up your environment, install necessary packages, and create symbolic links for your configuration files.

    ```bash
    ./install.sh
    ```

    This script will do the following:
    - Check if **Homebrew** is installed and install it if not.
    - Install or update essential packages via Homebrew (e.g., `fzf`, `asdf`, `direnv`, `pv`, etc.).
    - Install **Oh My Zsh** if it's not already installed.
    - Install and configure Zsh plugins such as `zsh-autosuggestions`, `zsh-syntax-highlighting`, and `zsh-fzf-history-search`.
    - Set up symbolic links for the following files:
      - `~/.zshrc` (Zsh configuration)
      - `~/.vimrc` (Vim configuration)
      - `~/.gitignore_global` (Global Git ignore file)
      - Custom Zsh theme `~/.oh-my-zsh/themes/santi.zsh-theme`
    - Create the `~/.zshrc.local` file (if not already created) for machine-specific configurations.
    - Create the `~/.hosts.local` file (if not already created) for machine-specific hosts configurations.
    - Execute the `update-hosts.sh` script to update your hosts file.

3. **Configure `~/.zshrc.local` and `~/.hosts.local` (optional)**:

    If you have machine-specific configurations (like environment variables, aliases, or other settings), you can add them to the `~/.zshrc.local` and `~/.hosts.local` files. These files are sourced at the end of your main `~/.zshrc` file.

    - Add any custom settings or exports in `~/.zshrc.local`, for example:

      ```bash
      export PATH="$PATH:/some/custom/path"
      alias gs="git status"
      ```

    - For `~/.hosts.local`, you can add custom host entries:

      ```bash
      127.0.0.1   my-custom-host.local
      192.168.1.100 another-host.local
      ```

    The `~/.zshrc.local` file will be automatically loaded by your main `~/.zshrc`, and the `~/.hosts.local` file will be included in the `/etc/hosts` configuration.

## Zsh Plugins

This setup includes the following Zsh plugins:

- **[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)**: Suggests commands as you type.
- **[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)**: Highlights syntax as you type commands in the terminal.
- **[zsh-fzf-history-search](https://github.com/joshskidmore/zsh-fzf-history-search)**: Fuzzy search through your Zsh history.

These plugins are automatically installed during the setup process.

## Customization

You can customize the following files:

- **~/.zshrc**: The main Zsh configuration file.
- **~/.vimrc**: Vim configuration file.
- **~/.gitignore_global**: A global Git ignore file for excluding files from version control.
- **~/.zshrc.local**: A file for machine-specific configurations (e.g., environment variables or aliases).
- **~/.hosts.local**: A file for machine-specific host configurations (e.g., IP-to-hostname mappings).

If you're using multiple systems (work, personal, etc.), the `~/.zshrc.local` and `~/.hosts.local` files allow you to specify custom settings for each machine.

## Managing Updates

To update your dotfiles on your machine, follow these steps:

1. **Pull the latest changes from the repository**:

    ```bash
    git pull origin main
    ```

2. **Re-run the `install.sh` script** to apply any changes:

    ```bash
    ./install.sh
    ```

## Troubleshooting

If you encounter any issues during the installation process:

- **Homebrew issues**: Ensure that your system is up-to-date. On macOS, you can run:

    ```bash
    softwareupdate --install --all
    ```

- **Zsh or Oh My Zsh issues**: If Zsh or Oh My Zsh isn't working properly, try reinstalling them:

    ```bash
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ```

- **Missing scripts**: If the `update-hosts.sh` script is missing, make sure it exists in the root of the repository.

## License

Feel free to fork, clone, and use these dotfiles for your own setups.
