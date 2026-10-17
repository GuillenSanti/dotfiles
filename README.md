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
    - Install or upgrade everything in the `Brewfile` with `brew bundle`: the command-line tools (`gh`, `tmux`, `tmuxp`, `fzf`, `asdf`, `neovim`…), the fonts and apps such as **Ghostty**, **Rectangle** and **MeetingBar**. See [Homebrew packages](#homebrew-packages).
    - Install **Claude Code** and **opencode** with their own installers if they aren't installed, as on this machine, rather than from the Brewfile. Claude Code updates itself; opencode updates with `opencode upgrade`.
    - Install **Oh My Zsh** if it's not already installed.
    - Install and configure Zsh plugins such as `zsh-autosuggestions`, `zsh-syntax-highlighting`, and `zsh-fzf-history-search`.
    - Set up symbolic links for the following files:
      - `~/.zshrc` (Zsh configuration)
      - `~/.vimrc` (Vim configuration)
      - `~/.gitignore_global` (Global Git ignore file)
      - Custom Zsh theme `~/.oh-my-zsh/themes/santi.zsh-theme`
      - `~/.tmux.conf` and the status bar scripts in `~/.tmux/`
      - opencode plugin `~/.config/opencode/plugins/attention.js`
      - `cafe-on`, `cafe-off` and `cafe-status` in `~/.local/bin`
      - Global agent rules `opencode/AGENTS.md`, as `~/.config/opencode/AGENTS.md`, `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`
      - Claude Code status line `~/.claude/statusline.py`
      - Ghostty configuration `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`
    - Clone the [deck](https://github.com/GuillenSanti/deck) into `deck/` (or update it) and run its `install.sh`, which links its commands into `~/.tmux/`.
    - Merge the Claude Code hooks from `claude/hooks.json` into `~/.claude/settings.json`, and point its `statusLine` at `~/.claude/statusline.py` (the rest of the file is kept).
    - Create the `~/.zshrc.local` file (if not already created) for machine-specific configurations.
    - Create the `~/.hosts.local` file (if not already created) for machine-specific hosts configurations.
    - Execute the `update-hosts.sh` script to update your hosts file.
    - Check every commit to this repo with `gitleaks` (`core.hooksPath` to `.githooks`), see [Keeping it public](#keeping-it-public).
    - Run `private/install.sh` last, when there's a `private/` folder (a private repo of your own, cloned there), so its links win over the ones above.

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

4. **Configure Rectangle settings**:

    If you're using the **Rectangle** app for window management, you can import the provided `RectangleConfig.json` file into the app to use the predefined settings.

## Zsh Plugins

This setup includes the following Zsh plugins:

- **[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)**: Suggests commands as you type.
- **[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)**: Highlights syntax as you type commands in the terminal.
- **[zsh-fzf-history-search](https://github.com/joshskidmore/zsh-fzf-history-search)**: Fuzzy search through your Zsh history.

These plugins are automatically installed during the setup process.

## tmux attention indicator

When something needs you in a window you're not looking at, the tmux status bar shows an icon next to that window's name: a bell when it finished, a question mark when it's asking for permission or input. Visiting the window clears it.

- **Claude Code**: hooks in `claude/hooks.json`.
- **opencode**: plugin in `opencode/plugins/attention.js`.
- **zsh**: a command finishes while you're on another window (`.zshrc`).
- **Anything else**: any terminal bell (e.g. `make test; printf '\a'`).

All of them call `~/.tmux/attention.sh done|ask`. After installing, restart running opencode sessions and `source ~/.zshrc` in open shells.

## Keeping the Mac awake (`cafe-on`)

`cafe-on`, `cafe-off` and `cafe-status` (`tmux/cafe.py`, linked in `~/.local/bin` so agents' shells find them without `.zshrc`) keep the Mac awake while agents work, without one agent's `cafe-off` letting the Mac sleep under another that's still working:

- **From an agent** (Claude Code, opencode or Codex, found by walking up its process tree): `cafe-on` starts that agent's own `caffeinate -dims` and `cafe-off` stops only that one. macOS sleeps only once no caffeinate is left, so another agent's keeps it awake. An agent's caffeinate is tied to it (`-w`), so it also ends when the agent does, even without `cafe-off`.
- **From your own shell**: `cafe-on` and `cafe-off` switch the persistent one, as before (the launchd job `com.santiago.caffeinate`), until `cafe-off`.
- `cafe-off --all` turns everything off, agents' included (say, before leaving on battery).
- `cafe-status` lists what keeps it awake: the persistent one, and each agent's tmux window and since when. `~/.cache/cafe` keeps a file per agent.
- The tmux status bar shows the coffee icon while any of them is on: alone for your persistent one, `☕ 2` for two agents, `☕ +2` for yours and two agents. `cafe-on` and `cafe-off` redraw it at once.

## Home dashboard (deck)

The tmux home dashboard, in window 0, is a repo of its own: [deck](https://github.com/GuillenSanti/deck). `install.sh` clones it into `deck/` (or updates it) and runs its `install.sh`, which links `~/.tmux/dash.py` and its other commands. What it relies on stays here: the attention indicator above (agents asking or done), the `prefix R` binding that reviews a PR, OSC 8 hyperlinks in `.tmux.conf`, and the tmuxp layout that opens it in window 0.

## Keeping it public

Whatever only makes sense on one machine or at one job goes in `private/`, a private repo of its own cloned there (git ignores it here): the deck's Slots card, the real tmuxp layout (`tmux/main.yaml` is a plain one), a `.zshrc.local` template, and the words that mustn't leave it. `private/install.sh` links its parts into place, and `install.sh` runs it last.

`gitleaks` keeps the rest clean. `.githooks/pre-commit` stops a commit that adds a secret, a path into a home folder or one of those words outside `private/` (with `private/gitleaks.toml`, which adds the words to `.gitleaks.toml`, when it's there), and the `gitleaks` workflow scans the files with `.gitleaks.toml` on every push. A line that only looks like a secret says `gitleaks:allow`.

## Global agent rules

`opencode/AGENTS.md` holds the rules every coding agent follows in any project: git and PR workflow, commit messages, keeping the Mac awake with `cafe-on`/`cafe-off`, scope, comments and security. opencode reads it as `~/.config/opencode/AGENTS.md`, Claude Code as `~/.claude/CLAUDE.md` and Codex as `~/.codex/AGENTS.md`, all linked to the same file, so editing it changes all three. When a project's own instructions say something different, the project wins. Changes apply to new sessions.

## Claude Code status line

`claude/statusline.py` draws Claude Code's status line in the dashboard's style, under the prompt (here with made-up numbers):

![The Claude Code status line](docs/statusline.png)

- **Left**: the model, its effort level, a purple *ultracode* tag only while ultracode is on, and the 5-hour and weekly limits (green, yellow from 50%, red from 80%) with when they reset.
- **Right**, at the pane's edge: how much of the context window the session uses, and its tokens. The width comes from tmux (`TMUX_PANE`), else from the terminal.
- **Ultracode** isn't in the JSON Claude Code passes to the status line, so it's read from the session's transcript: the last `ultra_effort_enter`/`ultra_effort_exit` marker Claude Code writes on each prompt, or `/effort`'s own "Ultracode on/off" output, found with `rg` (transcripts reach hundreds of MB). The `ultracode` keyword in a single prompt doesn't count: it's for that turn only.

## Ghostty

`ghostty/config.ghostty` is linked to `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`, where Ghostty reads it on macOS. It leaves as little as possible around the terminal while keeping the window buttons:

- **Title bar**: the `tabs` style puts the tabs in the title bar, next to the window buttons, so there's a single bar and the window can still be dragged by it. No title and no proxy icon.
- **Padding**: none above or below, and 4 points at the sides. `window-padding-balance` is off, so the space left over from the cell grid goes to the right and bottom edges instead of above the first line, which starts right under the tab bar.
- **Look**: Dracula on a pure black background, JetBrains Mono, and the X-ray icon.

After editing, reload it with ⌘⇧,. A change of title bar style only applies to new windows.

## Customization

You can customize the following files:

- **~/.zshrc**: The main Zsh configuration file.
- **~/.vimrc**: Vim configuration file.
- **~/.gitignore_global**: A global Git ignore file for excluding files from version control.
- **~/.zshrc.local**: A file for machine-specific configurations (e.g., environment variables or aliases).
- **~/.hosts.local**: A file for machine-specific host configurations (e.g., IP-to-hostname mappings).

If you're using multiple systems (work, personal, etc.), the `~/.zshrc.local` and `~/.hosts.local` files allow you to specify custom settings for each machine.

## Homebrew packages

`Brewfile` lists every Homebrew package and app to install, grouped by what it's for. `install.sh` runs `brew bundle` on it, which installs what's missing and upgrades what's outdated. To add one, add its `brew` or `cask` line and run:

```bash
brew bundle --file=~/dotfiles/Brewfile
```

- **What's missing:** `brew bundle check --file=~/dotfiles/Brewfile --no-upgrade` says whether everything in it is installed.
- **What's not in it:** `brew bundle cleanup --file=~/dotfiles/Brewfile` lists what's installed but not in the Brewfile, so you can add it. With `--force` it uninstalls it instead.
- **An app already installed outside Homebrew:** its `cask` line fails because the app is already in `/Applications`. `brew install --cask --adopt <cask>` hands it over to Homebrew.

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
