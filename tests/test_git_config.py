import subprocess
import unittest

import test_install


class GitConfigTests(unittest.TestCase):
    def setUp(self):
        self.fixture = test_install.InstallTests()
        self.fixture.setUp()
        self.addCleanup(self.fixture.doCleanups)

    def test_existing_shared_config_link_does_not_include_itself(self):
        case = self.fixture
        shared = case.repo / 'git/gitconfig'
        before = shared.read_bytes()
        (case.home / '.gitconfig').symlink_to(shared)
        case.install()
        case.install()
        self.assertEqual(shared.read_bytes(), before)
        editor = subprocess.check_output(['git', 'config', '--global', 'core.editor'],
                                         env=case.env, text=True)
        self.assertEqual(editor.strip(), 'vim')

    def assert_shared_config_stays_usable(self, case):
        shared = case.repo / 'git/gitconfig'
        before = shared.read_bytes()
        case.install()
        case.install()
        self.assertEqual(shared.read_bytes(), before)
        result = subprocess.check_output(['git', 'config', '--global', 'core.editor'],
                                         env=case.env, cwd=case.base, text=True)
        self.assertEqual(result.strip(), 'vim')

    def test_xdg_shared_config_link_does_not_include_itself(self):
        case = self.fixture
        config = case.home / '.config/git/config'
        config.parent.mkdir(parents=True)
        config.symlink_to(case.repo / 'git/gitconfig')
        self.assert_shared_config_stays_usable(case)
        self.assertFalse((case.home / '.gitconfig').exists())

    def test_custom_xdg_home_shared_config_is_preserved(self):
        case = self.fixture
        directory = case.base / 'preferences'
        case.env['XDG_CONFIG_HOME'] = str(directory)
        config = directory / 'git/config'
        config.parent.mkdir(parents=True)
        config.symlink_to(case.repo / 'git/gitconfig')
        self.assert_shared_config_stays_usable(case)

    def test_default_xdg_location_works_without_an_environment_override(self):
        case = self.fixture
        case.env.pop('XDG_CONFIG_HOME')
        config = case.home / '.config/git/config'
        config.parent.mkdir(parents=True)
        config.symlink_to(case.repo / 'git/gitconfig')
        self.assert_shared_config_stays_usable(case)

    def test_explicit_shared_global_config_does_not_include_itself(self):
        case = self.fixture
        case.env['GIT_CONFIG_GLOBAL'] = str(case.repo / 'git/gitconfig')
        self.assert_shared_config_stays_usable(case)
        self.assertFalse((case.home / '.gitconfig').exists())

    def test_relative_global_override_is_resolved_from_the_calling_directory(self):
        case = self.fixture
        case.env['GIT_CONFIG_GLOBAL'] = 'dotfiles/git/gitconfig'
        self.assert_shared_config_stays_usable(case)

    def test_personal_xdg_config_is_backed_up_before_modification(self):
        case = self.fixture
        config = case.home / '.config/git/config'
        config.parent.mkdir(parents=True)
        before = '[user]\n name = Example\n'
        config.write_text(before)
        case.install()
        saved = next((case.home / '.local/state/dotfiles/backups').glob('*/.config/git/config'))
        self.assertEqual(saved.read_text(), before)
        self.assertFalse((case.home / '.gitconfig').exists())
        name = subprocess.check_output(['git', 'config', '--global', 'user.name'], env=case.env, text=True)
        self.assertEqual(name.strip(), 'Example')

    def test_explicit_global_config_takes_priority_and_is_backed_up(self):
        case = self.fixture
        config = case.base / 'custom.gitconfig'
        before = '[user]\n name = Explicit\n'
        config.write_text(before)
        fallback = case.home / '.gitconfig'
        fallback.write_text('[user]\n name = Fallback\n')
        case.env['GIT_CONFIG_GLOBAL'] = str(config)
        case.install()
        backups = list((case.home / '.local/state/dotfiles/backups').rglob(config.name))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), before)
        self.assertEqual(fallback.read_text(), '[user]\n name = Fallback\n')
        name = subprocess.check_output(['git', 'config', '--global', 'user.name'], env=case.env, text=True)
        self.assertEqual(name.strip(), 'Explicit')

    def test_home_config_takes_priority_when_both_global_files_exist(self):
        case = self.fixture
        xdg = case.home / '.config/git/config'
        xdg.parent.mkdir(parents=True)
        xdg.write_text('[user]\n name = XDG\n')
        (case.home / '.gitconfig').write_text('[user]\n name = Home\n')
        case.install()
        self.assertEqual(xdg.read_text(), '[user]\n name = XDG\n')
        name = subprocess.check_output(['git', 'config', '--global', 'user.name'], env=case.env, text=True)
        self.assertEqual(name.strip(), 'Home')

    def test_disabled_global_config_does_not_get_written(self):
        case = self.fixture
        case.env['GIT_CONFIG_GLOBAL'] = '/dev/null'
        case.install()
        self.assertFalse((case.home / '.gitconfig').exists())

    def test_empty_override_fails_before_replacing_personal_files(self):
        case = self.fixture
        case.env['GIT_CONFIG_GLOBAL'] = ''
        shell = case.home / '.zshrc'
        shell.write_text('original')
        with self.assertRaises(subprocess.CalledProcessError):
            case.install()
        self.assertEqual(shell.read_text(), 'original')


if __name__ == '__main__':
    unittest.main()
