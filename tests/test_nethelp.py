"""Small offline regression suite; never contacts a router or the Internet."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
ENTRY = Path(os.environ.get('NETHELP_ENTRY', ROOT / 'bin/nethelp'))
SHELL = os.environ.get('NETHELP_TEST_SHELL') or shutil.which('sh')
if not SHELL and os.name == 'nt':
    SHELL = r'C:\Program Files\Git\bin\bash.exe'
if os.name == 'nt':
    os.environ.setdefault('NETHELP_TIMEOUT_BIN', 'C:/Program Files/Git/usr/bin/timeout.exe')
    os.environ['PATH'] = r'C:\Program Files\Git\usr\bin' + os.pathsep + os.environ.get('PATH', '')

def run(*args, input=None, env=None):
    prefix = [SHELL, 'ash'] if 'busybox' in Path(SHELL).name else [SHELL]
    return subprocess.run([*prefix, ENTRY.as_posix(), *args], input=input,
                          text=True, capture_output=True, timeout=15,
                          env={**os.environ, 'TMPDIR': Path(tempfile.gettempdir()).as_posix(), **(env or {})})

class InterfaceTests(unittest.TestCase):
    def test_help_is_offline_and_equivalent_in_both_positions(self):
        outputs = [run(*args) for args in [('help', '7'), ('-h', '7'), ('7', '-h')]]
        for r in outputs:
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertIn('What it checks:', r.stdout)
            self.assertIn('Does not prove:', r.stdout)
            self.assertNotIn('$ timeout', r.stdout)
        self.assertEqual(outputs[0].stdout, outputs[1].stdout)
        self.assertEqual(outputs[1].stdout, outputs[2].stdout)

    def test_all_selection_syntax_runs_all_requested_items_in_order(self):
        for args in [('1', '2'), ('1,2',), ('1,', '2'), ('router-status', 'interfaces')]:
            r = run('--commands', *args)
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertIn('=== 1 router-status ===', r.stdout)
            self.assertIn('=== 2 interfaces ===', r.stdout)
            self.assertLess(r.stdout.index('=== 1 '), r.stdout.index('=== 2 '))

    def test_invalid_selection_runs_nothing(self):
        r = run('--commands', '1', 'not-a-diagnostic')
        self.assertEqual(r.returncode, 2)
        self.assertNotIn('=== 1 ', r.stdout)

    def test_menu_not_reprinted_after_output(self):
        r = run('--interactive', input='help 7\nhelp 8\nq\n')
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(r.stdout.count('Read-only outage diagnostics'), 1)
        self.assertIn('Next checks', r.stdout)
        self.assertIn('What it checks:', r.stdout)

    def test_no_tty_no_selection_does_not_wait(self):
        r = run(input='')
        self.assertEqual(r.returncode, 0)
        self.assertIn('Usage:', r.stdout)

    def test_all_help_and_command_plans_are_available_without_dependencies(self):
        for item in range(1, 34):
            r = run('help', str(item))
            self.assertEqual(r.returncode, 0, (item, r.stderr))
            self.assertIn('When to use:', r.stdout)
        r = run('--commands', *map(str, range(1, 34)))
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertNotIn('command not found', r.stderr)

    def test_config_is_data_not_shell_and_cli_wins(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / 'config'
            marker = Path(d) / 'EXECUTED'
            p.write_text('target=$(touch ' + marker.as_posix() + ')\n', encoding='utf8')
            r = run('--config', p.as_posix(), '--commands', '7')
            self.assertEqual(r.returncode, 2)
            self.assertFalse(marker.exists())
            p.write_text('target=203.0.113.8\n', encoding='utf8')
            r = run('--config', p.as_posix(), '--target', '192.0.2.7', '--commands', '7')
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertIn('192.0.2.7', r.stdout)
            self.assertNotIn('203.0.113.8', r.stdout)

    def test_unbounded_and_unsafe_inputs_rejected(self):
        for args in [('--count', '0'), ('--count', '999999'), ('--interval', '0'),
                     ('--seconds', '999999'), ('--target', '-bad'), ('--family', '7')]:
            r = run('--commands', '7', *args)
            self.assertEqual(r.returncode, 2, (args, r.stdout, r.stderr))

    def test_report_saves_selected_checks_and_refuses_overwrite(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / 'report.txt'
            r = run('--commands', '--output', p.as_posix(), '7', '13')
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertTrue(p.exists(), r.stdout)
            text = p.read_text()
            self.assertIn('=== 7 public-ping ===', text)
            self.assertIn('=== 13 adguard-query ===', text)
            self.assertIn('mode=command-preview', text)
            again = run('--commands', '--output', p.as_posix(), '1')
            self.assertNotEqual(again.returncode, 0)
            self.assertEqual(text, p.read_text())

    def test_credentials_rejected_before_command_echo(self):
        r = run('--commands', '--url', 'https://user:secret@example.com/', '9')
        self.assertEqual(r.returncode, 2)
        self.assertNotIn('user:secret', r.stdout + r.stderr)

if __name__ == '__main__':
    unittest.main()
