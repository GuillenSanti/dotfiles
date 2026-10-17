import importlib.util
import io
from pathlib import Path
import tempfile
import subprocess
import sys
import unittest
from contextlib import redirect_stdout
from types import SimpleNamespace
from unittest.mock import patch


class CafeTests(unittest.TestCase):
    def setUp(self):
        spec = importlib.util.spec_from_file_location('cafe', Path(__file__).resolve().parents[1] / 'bin/cafe.py')
        self.cafe = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.cafe)
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.cafe.HOLDS = str(Path(temp.name) / 'holds')
        Path(self.cafe.HOLDS).mkdir()

    def test_status_polling_during_on_keeps_the_new_agent_hold(self):
        cafe = self.cafe
        process = SimpleNamespace(pid=202, terminate=lambda: None)

        def poll_status():
            cafe.holds()
            return '1:work'

        with patch.object(cafe, 'agent', return_value=101), \
                patch.object(cafe, 'window', side_effect=poll_status), \
                patch.object(cafe, 'alive_caffeinate', return_value=True), \
                patch.object(cafe.subprocess, 'Popen', return_value=process), redirect_stdout(io.StringIO()):
            cafe.on()
            holds = cafe.holds()
        self.assertEqual([(h[0], h[1], h[2]) for h in holds], [(101, 202, '1:work')])

    def test_another_reader_removing_a_stale_hold_is_harmless(self):
        path = Path(self.cafe.HOLDS) / '101'
        path.write_text('stale')
        remove = self.cafe.os.remove

        def other_reader_removed(name):
            remove(name)
            raise FileNotFoundError(name)

        with patch.object(self.cafe.os, 'remove', side_effect=other_reader_removed):
            self.assertEqual(self.cafe.holds(), [])

    def test_exiting_caffeinate_does_not_break_off(self):
        cafe = self.cafe
        path = Path(cafe.HOLDS) / '101'
        path.write_text('202\t1:work\t1.0\n')
        with patch.object(cafe, 'agent', return_value=101), \
                patch.object(cafe, 'alive_caffeinate', return_value=True), \
                patch.object(cafe, 'persistent', return_value=False), \
                patch.object(cafe.os, 'kill', side_effect=ProcessLookupError), \
                patch.object(cafe.sys, 'argv', ['cafe-off']), redirect_stdout(io.StringIO()):
            cafe.off()
        self.assertFalse(path.exists())

    def test_failed_state_publication_stops_the_new_caffeinate(self):
        cafe = self.cafe
        terminated = []
        process = SimpleNamespace(pid=202, terminate=lambda: terminated.append(True))
        with patch.object(cafe, 'agent', return_value=101), \
                patch.object(cafe, 'window', return_value='1:work'), \
                patch.object(cafe.subprocess, 'Popen', return_value=process), \
                patch.object(cafe.os, 'replace', side_effect=OSError('publication failed')):
            with self.assertRaises(OSError):
                cafe.on()
        self.assertEqual(terminated, [True])
        self.assertEqual(list(Path(cafe.HOLDS).parent.glob('.cafe-*')), [])

    def test_cli_serializes_simultaneous_commands(self):
        root = str(Path(self.cafe.HOLDS).parent)
        source = str(Path(__file__).resolve().parents[1] / 'bin/cafe.py')
        program = '''
import importlib.util
from pathlib import Path
import sys
import time
spec = importlib.util.spec_from_file_location('cafe', sys.argv[1])
cafe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cafe)
root = Path(sys.argv[2])
cafe.HOLDS = str(root / 'holds')
identity = sys.argv[3]
(root / ('ready-' + identity)).touch()
deadline = time.monotonic() + 5
while len(list(root.glob('ready-*'))) != 2:
    if time.monotonic() > deadline:
        raise TimeoutError('second command did not start')
    time.sleep(0.01)
def exclusive_action():
    with (root / 'active').open('x'):
        time.sleep(0.2)
    (root / 'active').unlink()
cafe.on = exclusive_action
cafe.refresh = lambda: None
sys.argv = ['cafe-on']
cafe.main()
'''
        processes = [subprocess.Popen([sys.executable, '-c', program, source, root, identity],
                                      stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                     for identity in ('a', 'b')]
        for process in processes:
            _, error = process.communicate(timeout=10)
            self.assertEqual(process.returncode, 0, error)


if __name__ == '__main__':
    unittest.main()
