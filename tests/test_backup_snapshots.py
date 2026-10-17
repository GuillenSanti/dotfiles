import unittest

import test_install


class BackupSnapshotTests(unittest.TestCase):
    def setUp(self):
        self.fixture = test_install.InstallTests()
        self.fixture.setUp()
        self.addCleanup(self.fixture.doCleanups)

    def test_git_backup_keeps_old_content_and_the_original_link(self):
        case = self.fixture
        original = case.base / 'personal-gitconfig'
        before = '[user]\n name = Example\n'
        original.write_text(before)
        (case.home / '.gitconfig').symlink_to(original)
        case.install()
        saved = next((case.home / '.local/state/dotfiles/backups').glob('*/.gitconfig'))
        self.assertTrue(saved.is_symlink())
        self.assertEqual(saved.resolve(), original)
        snapshot = saved.with_name(saved.name + '.contents')
        self.assertEqual(snapshot.read_text(), before)
        self.assertEqual(snapshot.stat().st_mode & 0o777, 0o600)
        self.assertNotEqual(original.read_text(), before)

    def test_gpg_backup_keeps_old_content_before_updating_its_target(self):
        case = self.fixture
        original = case.base / 'personal-agent.conf'
        original.write_text('default-cache-ttl 600\n')
        config = case.home / '.gnupg/gpg-agent.conf'
        config.parent.mkdir()
        config.symlink_to(original)
        case.tool('pinentry-mac', 'exit 0')
        case.tool('gpgconf', 'exit 0')
        case.install()
        saved = next((case.home / '.local/state/dotfiles/backups').glob('*/.gnupg/gpg-agent.conf.contents'))
        self.assertEqual(saved.read_text(), 'default-cache-ttl 600\n')
        self.assertIn('pinentry-program ', original.read_text())


if __name__ == '__main__':
    unittest.main()
