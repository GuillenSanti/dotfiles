import os
from pathlib import Path
import subprocess
import tempfile
import unittest


class SecretHookTests(unittest.TestCase):
    def test_missing_scanner_blocks_the_commit(self):
        hook = Path(__file__).resolve().parents[1] / '.githooks/pre-commit'
        with tempfile.TemporaryDirectory() as tools:
            result = subprocess.run(['/bin/sh', str(hook)], env=dict(os.environ, PATH=tools),
                                    capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('gitleaks', result.stderr)

    def test_scanner_failure_is_returned_to_git(self):
        root = Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory() as tools:
            scanner = Path(tools) / 'gitleaks'
            scanner.write_text('#!/bin/sh\nexit 23\n')
            scanner.chmod(0o755)
            result = subprocess.run(['/bin/sh', str(root / '.githooks/pre-commit')], cwd=root,
                                    env=dict(os.environ, PATH=tools), capture_output=True, text=True)
        self.assertEqual(result.returncode, 23)


if __name__ == '__main__':
    unittest.main()
