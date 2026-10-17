import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


class InstallTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.repo = self.base / 'dotfiles'
        shutil.copytree(Path(__file__).resolve().parents[1], self.repo,
                        ignore=shutil.ignore_patterns('.git', 'deck', 'private', '__pycache__'))
        subprocess.run(['git', 'init', '-q', str(self.repo)], check=True)
        self.home = self.base / 'home'
        self.home.mkdir()
        self.tools = self.base / 'tools'
        self.tools.mkdir()
        self.tool('python3', f'exec "{sys.executable}" "$@"')
        self.env = dict(os.environ, HOME=str(self.home), PATH=f'{self.tools}:/usr/bin:/bin',
                        XDG_CONFIG_HOME=str(self.home / '.config'), GIT_CONFIG_NOSYSTEM='1',
                        LC_ALL='C')
        for name in ('ZSH_CUSTOM', 'GIT_CONFIG_GLOBAL', 'GIT_CONFIG_COUNT', 'TMUX', 'TMUX_PANE'):
            self.env.pop(name, None)

    def tool(self, name, code):
        path = self.tools / name
        path.write_text('#!/bin/sh\n' + code + '\n')
        path.chmod(0o755)

    def install(self):
        return subprocess.run(['zsh', str(self.repo / 'install.sh')], env=self.env,
                              cwd=self.base, capture_output=True, text=True, check=True)

    def test_preserves_settings_and_repeated_install_is_stable(self):
        (self.home / '.zshrc').write_text('original shell\n')
        (self.home / '.zshrc.local').write_text('export LOCAL_VALUE=kept\n')
        (self.home / '.gitconfig').write_text('[user]\n name = Example\n email = example@example.invalid\n')
        settings = self.home / '.claude/settings.json'
        settings.parent.mkdir()
        settings.write_text(json.dumps({'permissions': {'allow': ['Read']}}))
        old = self.base / 'old-cafe.py'
        old.write_text('old command')
        command = self.home / '.local/bin/cafe-on'
        command.parent.mkdir(parents=True)
        command.symlink_to(old)
        self.install()
        self.assertEqual(command.resolve(), self.repo / 'tmux/cafe.py')
        self.assertEqual((self.home / '.zshrc.local').read_text(), 'export LOCAL_VALUE=kept\n')
        backups = self.home / '.local/state/dotfiles/backups'
        self.assertTrue(any(p.read_text() == 'original shell\n' for p in backups.glob('*/.zshrc')))
        self.assertEqual(json.loads(settings.read_text())['permissions'], {'allow': ['Read']})
        before = settings.read_bytes()
        self.install()
        self.assertEqual(before, settings.read_bytes())
        value = subprocess.check_output(['git', 'config', '--global', 'user.name'], env=self.env, text=True)
        self.assertEqual(value.strip(), 'Example')
        includes = subprocess.check_output(['git', 'config', '--global', '--get-all', 'include.path'],
                                           env=self.env, text=True).splitlines()
        self.assertEqual(includes, [str(self.repo / '.gitconfig')])

    def test_local_files_and_nested_repositories_are_ignored(self):
        paths = ['.zshrc.local', 'hosts.local', 'deck/probe', 'private/probe']
        result = subprocess.run(['git', '-C', str(self.repo), 'check-ignore', '--no-index', *paths],
                                capture_output=True, text=True, check=True)
        self.assertEqual(set(result.stdout.splitlines()), set(paths))

    def test_invalid_claude_settings_fail_before_replacing_shell(self):
        settings = self.home / '.claude/settings.json'
        settings.parent.mkdir()
        settings.write_text('{invalid')
        (self.home / '.zshrc').write_text('original')
        with self.assertRaises(subprocess.CalledProcessError):
            self.install()
        self.assertEqual((self.home / '.zshrc').read_text(), 'original')

    def test_hosts_download_failure_and_invalid_data_never_reach_sudo(self):
        marker = self.base / 'sudo-called'
        self.tool('sudo', f'touch "{marker}"; exit 1')
        for command in ('exit 22', 'for last; do :; done; printf "<html>error</html>" > "$last"'):
            self.tool('curl', command)
            result = subprocess.run(['bash', str(self.repo / 'update-hosts.sh')], env=self.env,
                                    input='yes\n', capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(marker.exists())

    def test_keychain_program_uses_real_app_path_and_preserves_existing_choice(self):
        app = self.base / 'pinentry-mac.app/Contents/MacOS/pinentry-mac'
        app.parent.mkdir(parents=True)
        app.write_text('#!/bin/sh\nexit 0\n')
        app.chmod(0o755)
        (self.tools / 'pinentry-mac').symlink_to(app)
        self.tool('gpgconf', 'exit 0')
        self.install()
        config = self.home / '.gnupg/gpg-agent.conf'
        self.assertIn('pinentry-program ' + str(app), config.read_text())
        config.write_text('pinentry-program /custom/pinentry\n')
        self.install()
        self.assertEqual(config.read_text(), 'pinentry-program /custom/pinentry\n')

    def test_private_layout_and_existing_local_symlink_survive_repeated_install(self):
        local = self.base / 'old-local'
        local.write_text('export LOCAL_VALUE=old\n')
        (self.home / '.zshrc.local').symlink_to(local)
        private = self.repo / 'private'
        private.mkdir()
        (private / 'main.yaml').write_text('session_name: private\n')
        (private / 'install.sh').write_text(
            '#!/bin/zsh\nprivate_dir=${0:A:h}\n'
            'ln -sfn "$private_dir/main.yaml" "$HOME/.tmuxp/main.yaml"\n')
        self.install()
        self.install()
        self.assertEqual((self.home / '.tmuxp/main.yaml').resolve(), private / 'main.yaml')
        self.assertEqual((self.home / '.zshrc.local').resolve(), local)


if __name__ == '__main__':
    unittest.main()
