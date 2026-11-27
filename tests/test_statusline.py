import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

STATUSLINE = Path(__file__).resolve().parents[1] / 'claude/statusline.py'
LIMITS = {
    'five_hour': {'used_percentage': 42.5, 'resets_at': 1795000000},
    'seven_day': {'used_percentage': 17, 'resets_at': 1795400000},
}


class StatuslineTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.home = Path(temp.name)
        (self.home / '.claude').mkdir()
        self.saved = self.home / '.claude/rate-limits.json'

    def draw(self, session):
        subprocess.run([sys.executable, str(STATUSLINE)], input=json.dumps(session), text=True,
                       capture_output=True, check=True, env={**os.environ, 'HOME': str(self.home)})

    def test_leaves_the_usage_limits_for_agents(self):
        self.draw({'rate_limits': LIMITS})
        saved = json.loads(self.saved.read_text())
        self.assertEqual({name: saved[name] for name in LIMITS}, LIMITS)
        self.assertIsInstance(saved['updated_at'], int)
        self.assertEqual([p.name for p in self.saved.parent.iterdir()], ['rate-limits.json'])

    def test_a_session_without_limits_keeps_the_last_ones(self):
        self.draw({'rate_limits': LIMITS})
        self.draw({'model': {'display_name': 'Opus'}})
        self.assertEqual(json.loads(self.saved.read_text())['five_hour'], LIMITS['five_hour'])


if __name__ == '__main__':
    unittest.main()
