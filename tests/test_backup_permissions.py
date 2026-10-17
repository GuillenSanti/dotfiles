import os
import unittest

import test_install


class BackupPermissionsTests(unittest.TestCase):
    def setUp(self):
        self.fixture = test_install.InstallTests()
        self.fixture.setUp()
        self.addCleanup(self.fixture.doCleanups)

    def test_backups_are_private_even_with_a_permissive_umask(self):
        case = self.fixture
        settings = case.home / '.claude/settings.json'
        settings.parent.mkdir(mode=0o700)
        settings.write_text('{"env":{"EXAMPLE":"private setting"}}')
        settings.chmod(0o644)
        backups = case.home / '.local/state/dotfiles/backups'
        backups.mkdir(parents=True, mode=0o755)
        old = os.umask(0o022)
        try:
            case.install()
        finally:
            os.umask(old)
        saved = next(backups.glob('*/.claude/settings.json'))
        for folder in (backups, saved.parent.parent, saved.parent):
            self.assertEqual(folder.stat().st_mode & 0o777, 0o700)
        self.assertEqual(saved.read_text(), '{"env":{"EXAMPLE":"private setting"}}')


if __name__ == '__main__':
    unittest.main()
