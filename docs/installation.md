# Installation and recovery

`install.sh` selects an action. `scripts/configure.py` manages links, backups, Git preferences and agent settings using Python's standard library. These are installation helpers; runtime tools do not depend on them.

| Action | Changes |
|---|---|
| `--config` (default) | Links configuration, merges Claude settings, enables hooks and configures pinentry when needed. No network or package installation. |
| `--dependencies` | Installs missing Homebrew packages without upgrading existing ones, clones missing plugins and deck, and installs missing Claude/opencode CLIs. |
| `--update` | Updates Homebrew packages, Oh My Zsh, plugins and deck. CLI-specific agent upgrades stay with their own updaters. |
| `--all` | Runs dependencies, then configuration. |
| `--hosts` | Downloads and validates the blocklist, asks for confirmation and backs up `/etc/hosts` before replacing it with sudo. |

The script resolves its own location, so it can be invoked from any working directory. Repeating configuration does not duplicate hooks or Git includes. A changed link is repaired, while the previous link is backed up. Existing directories that would be replaced cause an error.

## Personal settings

Keep your identity and signing key in your own Git configuration. The shared Git file is added through `include.path` and contains preferences only. Local values for common preferences can override it when placed after the include in `~/.gitconfig`.

Keep shell overrides in `~/.zshrc.local`; they load after the shared defaults. Keep local host entries in `~/.hosts.local`. Existing files and resolving symlinks are preserved, so do not remove an old checkout until local overrides pointing into it have been copied to a permanent location.

Python and Git must already be available for configuration. Homebrew is needed only for dependency installation and upgrades. Intel and Apple Silicon paths are detected at shell startup. Missing optional tools do not prevent starting a shell.

`pinentry-mac` can store the GPG passphrase in the macOS Keychain. The installer only supplies its path when no program was already configured; it does not read, store or change the passphrase itself. Select **Save in Keychain** in the native prompt. Existing GPG configuration is preserved.

## Restore a previous file

Backups are grouped by installation time in `~/.local/state/dotfiles/backups/`, with paths matching their home locations. The installer prints the paths it saves. Backups can contain personal configuration; keep them local.

To restore one, inspect the selected backup, remove only the replacement symlink at the destination, then copy the backup back with `cp -P` (preserves symlinks). For Claude settings, copy the saved `settings.json` back instead. Git configuration is also saved before adding an include for the first time. No backup folder is deleted automatically.

The private installer runs last and can override the tmuxp layout and Slots card. Existing links for these are saved first. This repo does not change the private installer's implementation.

Hosts backups are separate, beside the system file as `/etc/hosts.dotfiles-<time>-<pid>`. Restore the selected one with sudo if necessary. A failed or malformed download never replaces the system file.

## Verify before applying

Run `python3 -m unittest discover -s tests -v`. The tests use temporary checkouts and home directories, check repeated installation and preservation of settings, and mock network/system writes for hosts failures. They do not install packages or change your real home.

## Installed paths

| Source | Installed location |
|---|---|
| `zsh/zshrc` | `~/.zshrc` |
| `zsh/santi.zsh-theme` | Oh My Zsh's custom themes directory |
| `git/gitconfig` | Included by `~/.gitconfig`; identity stays personal |
| `git/gitignore_global` | `~/.gitignore_global` |
| `vim/vimrc` | `~/.vimrc` |
| `tmux/tmux.conf` | `~/.tmux.conf` |
| `tmux/main.yaml` | `~/.tmuxp/main.yaml`; private layout can override it |
| `tmux/status/*.sh`, `tmux/attention.sh` | Same filenames under `~/.tmux/` |
| `bin/cafe.py` | `~/.local/bin/cafe-on`, `cafe-off`, `cafe-status` |
| `agents/AGENTS.md` | `~/.codex/AGENTS.md`, `~/.claude/CLAUDE.md`, `~/.config/opencode/AGENTS.md` |
| `agents/demo-video-overlay.cjs` | Used directly by demo scripts; no installation link |
| `claude/hooks.json` | Merged into `~/.claude/settings.json` |
| `claude/statusline.py` | `~/.claude/statusline.py` |
| `opencode/plugins/attention.js` | `~/.config/opencode/plugins/attention.js` |
| `ghostty/config.ghostty` | Ghostty's Application Support configuration |
| `rectangle/RectangleConfig.json` | Import manually in Rectangle |
| `examples/*` | Used only when creating missing local override files |
| `hosts/hosts` | Input to `hosts/update-hosts.sh`; never installed implicitly |

## Upgrade from the flat layout

After pulling this reorganization, run `./install.sh --config` before starting new shells or agents. It repairs links to moved source files, saves previous targets and replaces this checkout's old Git include when present. Runtime command names and home locations stay the same. Existing local overrides and the private checkout are kept.

Do not delete an older checkout while `~/.zshrc.local` or `~/.hosts.local` still points into it. Move those personal files to a permanent location first. The private installer continues to run last and supplies the same layout and Slots card locations.
