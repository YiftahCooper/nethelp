"""Exercise the real installer only inside disposable prefixes."""
from pathlib import Path
import shutil
import tempfile
import unittest
from test_nethelp import ROOT, SHELL
from test_execution import shell


class InstallTests(unittest.TestCase):
    def setUp(self):
        scratch = ROOT.parent / '.tmp'
        scratch.mkdir(exist_ok=True)
        self.tmp = tempfile.TemporaryDirectory(dir=scratch)
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.source = self.root / 'source'
        shutil.copytree(ROOT, self.source, ignore=shutil.ignore_patterns('__pycache__'))
        # Most cases model a Git checkout; archive manifest validation is separate.
        (self.source / 'SHA256SUMS').unlink(missing_ok=True)
        self.prefix = self.root / 'installed'
        (self.prefix / 'bin').mkdir(parents=True)
        self.entry = self.prefix / 'bin/nethelp'
        self.old = '#!/bin/sh\nprintf "old-nethelp\\n"\n'
        self.entry.write_text(self.old, newline='\n')
        (self.prefix / 'lib/nethelp').mkdir(parents=True)
        (self.prefix / 'lib/nethelp/old.sh').write_text('old module\n')
        self.config = self.root / 'nethelp.conf'
        self.config.write_text('wan=private-wan\n')

    def install(self):
        self.assertTrue((self.source / 'install.sh').is_file(), 'installer not implemented')
        prefix = self.prefix.as_posix()
        if len(prefix) > 2 and prefix[1] == ':' and 'busybox' not in Path(SHELL).name:
            prefix = '/' + prefix[0].lower() + prefix[2:]
        return shell('sh "$1/install.sh" --prefix "$2"',
                     self.source.as_posix(), prefix)

    def test_replacement_and_rollback_preserve_old_modules_and_private_config(self):
        r = self.install()
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn('installed=', r.stdout)
        active = shell('sh "$1" help 7', self.entry.as_posix())
        self.assertEqual(active.returncode, 0, active.stderr)
        self.assertIn('What it checks:', active.stdout)
        self.assertEqual(self.config.read_text(), 'wan=private-wan\n')
        self.assertEqual((self.prefix / 'lib/nethelp/old.sh').read_text(), 'old module\n')
        rollback = next((self.prefix / 'lib/nethelp-releases').glob('*/rollback.sh'))
        r = shell('sh "$1"', rollback.as_posix())
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertEqual(self.entry.read_text(), self.old)

    def test_missing_module_leaves_old_entry_unchanged(self):
        (self.source / 'diagnostics/07-public-ping.sh').unlink()
        r = self.install()
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('Missing or symlinked source file:', r.stderr)
        self.assertEqual(self.entry.read_text(), self.old)

    def test_archive_checksum_mismatch_leaves_old_entry_unchanged(self):
        (self.source / 'SHA256SUMS').write_text('0' * 64 + '  bin/nethelp\n', newline='\n')
        r = self.install()
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('checksum', r.stderr.lower())
        self.assertEqual(self.entry.read_text(), self.old)

    def test_broken_shared_runner_leaves_old_entry_unchanged(self):
        with (self.source / 'lib/common.sh').open('a', newline='\n') as f:
            f.write('\nnh_cmd() { NH_BROKEN=1; }\n')
        r = self.install()
        self.assertNotEqual(r.returncode, 0)
        self.assertEqual(self.entry.read_text(), self.old)
        self.assertTrue(list((self.prefix / 'lib/nethelp-releases').glob('*/runner-check.txt')))

    def test_failed_active_help_automatically_restores_old_launcher(self):
        entry = self.source / 'bin/nethelp'
        text = entry.read_text()
        text = text.replace('nh_main "$@"', '''
if [ -f "$NH_ROOT/help-seen" ]; then exit 71; fi
touch "$NH_ROOT/help-seen"
nh_main "$@"''')
        entry.write_text(text, newline='\n')
        r = self.install()
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('Previous command restored.', r.stderr)
        self.assertEqual(self.entry.read_text(), self.old)

    def test_old_rollback_cannot_clobber_newer_install(self):
        r = self.install()
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        rollback = next((self.prefix / 'lib/nethelp-releases').glob('*/rollback.sh'))
        r = self.install()
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        current = self.entry.read_bytes()
        r = shell('sh "$1"', rollback.as_posix())
        self.assertNotEqual(r.returncode, 0)
        self.assertEqual(self.entry.read_bytes(), current)

    def test_fresh_install_rollback_removes_only_launcher(self):
        self.entry.unlink()
        r = self.install()
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        rollback = next((self.prefix / 'lib/nethelp-releases').glob('*/rollback.sh'))
        r = shell('sh "$1"', rollback.as_posix())
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertFalse(self.entry.exists())
        self.assertTrue(self.config.exists())
