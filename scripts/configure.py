#!/usr/bin/env python3
"""Apply configuration without downloading packages or replacing personal files silently."""

import datetime
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
HOME = Path.home()
BACKUP = HOME / '.local/state/dotfiles/backups' / datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')


def backup(path):
    relative = path.relative_to(HOME) if HOME in path.parents else Path('external') / str(path).lstrip('/')
    target = BACKUP / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    number = 1
    original = target
    while target.exists() or target.is_symlink():
        target = original.with_name(original.name + f'.{number}')
        number += 1
    if path.is_symlink():
        target.symlink_to(os.readlink(path))
    else:
        shutil.copy2(path, target)
    print(f'Backup: {target}')


def link(source, destination):
    if not source.exists():
        raise FileNotFoundError(source)
    if destination.is_symlink() and destination.resolve() == source.resolve():
        return
    if destination.exists() or destination.is_symlink():
        if destination.is_dir() and not destination.is_symlink():
            raise IsADirectoryError(f'Refusing to replace directory: {destination}')
        backup(destination)
        destination.unlink()
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.symlink_to(source)
    print(f'Linked: {destination}')


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    text = json.dumps(data, indent=2, ensure_ascii=False) + '\n'
    if path.exists():
        if path.read_text() == text:
            return
        backup(path)
    with tempfile.NamedTemporaryFile(mode='w', dir=path.parent, delete=False) as f:
        f.write(text)
    os.replace(f.name, path)


def configure():
    settings_path = HOME / '.claude/settings.json'
    settings = json.loads(settings_path.read_text()) if settings_path.exists() else {}
    hooks = json.loads((ROOT / 'claude/hooks.json').read_text())['hooks']
    for event, entries in hooks.items():
        current = settings.setdefault('hooks', {}).setdefault(event, [])
        current.extend(entry for entry in entries if entry not in current)
    settings['statusLine'] = {'type': 'command', 'command': '/usr/bin/python3 ~/.claude/statusline.py'}

    links = {
        'zsh/zshrc': '.zshrc', 'vim/vimrc': '.vimrc', 'git/gitignore_global': '.gitignore_global',
        'tmux/tmux.conf': '.tmux.conf', 'tmux/main.yaml': '.tmuxp/main.yaml',
        'tmux/status/battery.sh': '.tmux/battery.sh', 'tmux/status/caffeinate.sh': '.tmux/caffeinate.sh',
        'tmux/attention.sh': '.tmux/attention.sh',
        'opencode/plugins/attention.js': '.config/opencode/plugins/attention.js',
        'claude/statusline.py': '.claude/statusline.py',
        'ghostty/config.ghostty': 'Library/Application Support/com.mitchellh.ghostty/config.ghostty',
    }
    for source, destination in links.items():
        link(ROOT / source, HOME / destination)
    custom = Path(os.environ.get('ZSH_CUSTOM', str(HOME / '.oh-my-zsh/custom')))
    link(ROOT / 'zsh/santi.zsh-theme', custom / 'themes/santi.zsh-theme')
    for destination in ('.config/opencode/AGENTS.md', '.claude/CLAUDE.md', '.codex/AGENTS.md'):
        link(ROOT / 'agents/AGENTS.md', HOME / destination)
    for command in ('cafe-on', 'cafe-off', 'cafe-status'):
        link(ROOT / 'bin/cafe.py', HOME / '.local/bin' / command)

    # Preserve local overrides at their existing location, including old checkout symlinks.
    for name, source_name in (('.zshrc.local', '.zshrc.local'), ('.hosts.local', 'hosts.local')):
        path = HOME / name
        if path.exists():
            continue
        source = ROOT / source_name
        if not source.exists():
            example = 'zshrc.local.example' if name == '.zshrc.local' else 'hosts.local.example'
            source.write_text((ROOT / 'examples' / example).read_text())
        link(source, path)
    write_json(settings_path, settings)

    gitconfig = HOME / '.gitconfig'
    shared = str(ROOT / 'git/gitconfig')
    includes = subprocess.run(['git', 'config', '--global', '--get-all', 'include.path'],
                              capture_output=True, text=True, check=False).stdout.splitlines()
    if shared not in includes:
        if gitconfig.exists():
            backup(gitconfig)
        legacy = str(ROOT / '.gitconfig')
        if legacy in includes:
            subprocess.run(['git', 'config', '--global', '--fixed-value', '--replace-all',
                            'include.path', shared, legacy], check=True)
        else:
            subprocess.run(['git', 'config', '--global', '--add', 'include.path', shared], check=True)
    subprocess.run(['git', '-C', str(ROOT), 'config', 'core.hooksPath', '.githooks'], check=True)

    pinentry = shutil.which('pinentry-mac')
    agent_config = HOME / '.gnupg/gpg-agent.conf'
    existing = agent_config.read_text() if agent_config.exists() else ''
    configured = any(line.split()[:1] == ['pinentry-program'] for line in existing.splitlines())
    if pinentry and not configured:
        agent_config.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        if agent_config.exists():
            backup(agent_config)
        agent_config.write_text(existing.rstrip() + '\npinentry-program ' + str(Path(pinentry).resolve()) + '\n')
        agent_config.chmod(0o600)
        if shutil.which('gpgconf'):
            subprocess.run(['gpgconf', '--reload', 'gpg-agent'], check=True)
        print('GPG: select Save in Keychain at the next password prompt.')

    # Link deck commands here too, so changed targets are backed up consistently.
    if (ROOT / 'deck/dash.py').exists():
        for name in ('dash.py', 'agents-history.py', 'pr_review.py', 'branch_diff.py'):
            link(ROOT / 'deck' / name, HOME / '.tmux' / name)
        subprocess.run(['git', '-C', str(ROOT / 'deck'), 'config', 'core.hooksPath', '.githooks'], check=True)
    else:
        print('Deck not installed; use ./install.sh --dependencies to download it.')
    private = ROOT / 'private/install.sh'
    if private.exists():
        for name in ('.config/deck/cards/slots', '.tmuxp/main.yaml'):
            path = HOME / name
            if path.is_symlink():
                backup(path)
            elif path.exists():
                raise FileExistsError(f'Move this private configuration aside first: {path}')
        subprocess.run(['zsh', str(private)], check=True)
    print('Configuration applied. Restart shells and agent sessions to load it.')


if __name__ == '__main__':
    configure()
