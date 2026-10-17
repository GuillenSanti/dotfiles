#!/bin/zsh
set -euo pipefail

dotfiles_dir=${0:A:h}
action=${1:---config}

usage() {
    print 'Usage: ./install.sh [--config|--dependencies|--update|--hosts|--all]'
    print 'Default: --config. Existing files are backed up before replacement.'
}

sync_repo() {
    local url=$1 destination=$2 update=$3
    if [[ -d "$destination/.git" ]]; then
        if [[ "$update" == yes ]]; then
            git -C "$destination" pull --ff-only
        fi
    elif [[ -e "$destination" ]]; then
        print -u2 "Not a Git checkout: $destination. Move it aside before installing."
        return 1
    else
        git clone --depth 1 "$url" "$destination"
    fi
}

dependencies() {
    local update=$1
    if ! command -v brew >/dev/null; then
        print -u2 'Install Homebrew first: https://brew.sh'
        return 1
    fi
    if [[ "$update" == yes ]]; then
        brew update
        brew bundle --file="$dotfiles_dir/Brewfile"
    else
        HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --no-upgrade --file="$dotfiles_dir/Brewfile"
    fi
    sync_repo https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" "$update"
    local custom=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
    sync_repo https://github.com/zsh-users/zsh-autosuggestions.git "$custom/plugins/zsh-autosuggestions" "$update"
    sync_repo https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom/plugins/zsh-syntax-highlighting" "$update"
    sync_repo https://github.com/joshskidmore/zsh-fzf-history-search.git "$custom/plugins/zsh-fzf-history-search" "$update"
    sync_repo https://github.com/GuillenSanti/deck.git "$dotfiles_dir/deck" "$update"
    if ! command -v claude >/dev/null && [[ ! -x "$HOME/.local/bin/claude" ]]; then
        curl -fsSL https://claude.ai/install.sh | bash
    fi
    if ! command -v opencode >/dev/null && [[ ! -x "$HOME/.opencode/bin/opencode" ]]; then
        curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path
    fi
}

configure() {
    python3 "$dotfiles_dir/scripts/configure.py"
}

case "$action" in
    --config) configure ;;
    --dependencies) dependencies no ;;
    --update) dependencies yes ;;
    --hosts) bash "$dotfiles_dir/hosts/update-hosts.sh" ;;
    --all) dependencies no; configure ;;
    --help|-h) usage ;;
    *) usage >&2; exit 2 ;;
esac
