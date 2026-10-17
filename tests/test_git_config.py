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


if __name__ == '__main__':
    unittest.main()
