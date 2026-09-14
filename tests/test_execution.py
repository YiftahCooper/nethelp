"""Execution tests use fake external DNS programs, never a real resolver."""
import os
from pathlib import Path
import subprocess
import tempfile
import time
import signal
import unittest
from test_nethelp import ROOT, SHELL, run

def shell(code, *args, input=None, env=None):
    prefix = [SHELL, 'ash'] if 'busybox' in Path(SHELL).name else [SHELL]
    return subprocess.run([*prefix, '-c', code, 'test', *args], text=True,
                          input=input, capture_output=True, timeout=15,
                          env={**os.environ, **(env or {})})

class ExecutionTests(unittest.TestCase):
    def test_stale_traffic_totals_remain_visible_with_stopped_daemon(self):
        with tempfile.TemporaryDirectory() as d:
            code = '''
. "$1/lib/common.sh"
. "$1/diagnostics/28-traffic-history.sh"
NH_PLAN=0 NH_TMP="$2" NH_BROKEN=0
nh_wan() { NH_DEV=test0; }
nh_optional() { printf 'daemon not running\\n'; }
nh_cmd() { :; }
nh_capture() {
 NH_CAPTURE_RC=0
 case "$1" in
  vnstat) NH_DATA='{"interfaces":[{"name":"test0","created":{"timestamp":500},"updated":{"timestamp":1000},"traffic":{"total":{"rx":10000,"tx":300}}}]}' ;;
  jsonfilter) NH_DATA=$(printf 'test0\\n500\\n1000\\n10000\\n300\\n');;
  date) NH_DATA=2000;;
  awk) NH_DATA='SaveInterval 5';;
  *) exit 99;;
 esac
}
nh_run
'''
            r = shell(code, ROOT.as_posix(), Path(d).as_posix())
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertIn('status=STALE', r.stdout)
            self.assertIn('rx_bytes=10000', r.stdout)
            self.assertIn('tx_bytes=300', r.stdout)

    def test_counter_delta_is_calculated_and_counter_reset_not_negative(self):
        with tempfile.TemporaryDirectory() as d:
            directory = Path(d)
            (directory / 'sample-a').write_text('time 100\nboot test\nifindex 8\nrx_bytes 1000\ntx_errors 7\n', newline='\n')
            (directory / 'sample-b').write_text('time 105\nboot test\nifindex 8\nrx_bytes 1600\ntx_errors 2\n', newline='\n')
            code = '''
. "$1/lib/common.sh"
. "$1/diagnostics/21-counter-delta.sh"
NH_PLAN=0 NH_TMP="$2" NH_INTERVAL=5
nh_wan() { NH_DEV=test0; }
nh_sample_counters() {
 case "$2" in */before) cp "$NH_TMP/sample-a" "$2";; */after) cp "$NH_TMP/sample-b" "$2";; esac
}
nh_cmd() { if [ "$1" != sleep ]; then "$@"; fi; }
nh_run
'''
            r = shell(code, ROOT.as_posix(), directory.as_posix())
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertIn('elapsed_seconds=5', r.stdout)
            self.assertIn('rx_bytes_delta=600', r.stdout)
            self.assertIn('tx_errors_delta=unavailable (counter reset)', r.stdout)

    def test_cancellation_stops_the_active_command(self):
        if os.name == 'nt':
            self.skipTest('Unix signal/process-group acceptance requires a Unix host')
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / 'drill'
            marker = Path(d) / 'completed'
            p.write_text('#!/bin/sh\nsleep 4\nprintf finished > "$NETHELP_TEST_MARKER"\n')
            p.chmod(0o755)
            env = {**os.environ, 'PATH': d + os.pathsep + os.environ.get('PATH', ''),
                   'NETHELP_TEST_MARKER': str(marker)}
            proc = subprocess.Popen([SHELL, str(ROOT / 'bin/nethelp'), '13'],
                                    stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
            time.sleep(0.5)
            proc.send_signal(signal.SIGTERM)
            proc.communicate(timeout=5)
            time.sleep(4)
            self.assertFalse(marker.exists(), 'Cancelled probe was left running')

    def test_filter_keeps_addresses_but_removes_actual_secret_fields(self):
        sample = ('address=192.0.2.7 mac=02:00:00:00:00:07\n'
                  'password=not-a-real-password\n'
                  'Authorization: Bearer synthetic-test-token\n'
                  'token=synthetic-bare-token\n'
                  'https://user:synthetic@example.invalid/path\n'
                  '-----BEGIN PRIVATE KEY-----\nsynthetic-body\n-----END PRIVATE KEY-----\n'
                  'ordinary diagnostic output\n')
        r = shell('. "$1/lib/common.sh"; nh_filter', ROOT.as_posix(), input=sample)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('192.0.2.7', r.stdout)
        self.assertIn('02:00:00:00:00:07', r.stdout)
        self.assertIn('ordinary diagnostic output', r.stdout)
        for secret in ['not-a-real-password', 'synthetic-test-token', 'synthetic-bare-token', 'user:synthetic', 'synthetic-body']:
            self.assertNotIn(secret, r.stdout)

    def test_command_timeout_retains_output_and_marks_incomplete(self):
        with tempfile.TemporaryDirectory() as d:
            code = '''
. "$1/lib/common.sh"
NH_PLAN=0 NH_TIMEOUT=1 NH_TMP="$2" NH_BROKEN=0 NH_DEADLINE=
nh_cmd sh -c 'echo before-timeout; sleep 5'
printf 'broken=%s\\n' "$NH_BROKEN"
'''
            r = shell(code, ROOT.as_posix(), Path(d).as_posix())
            self.assertIn('before-timeout', r.stdout)
            self.assertIn('time limit reached', r.stdout)
            self.assertIn('broken=1', r.stdout)

    def test_all_retained_matching_logs_survive_beyond_old_caps(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / 'events'
            p.write_text(''.join(f'DNS error event-{i}\n' for i in range(1200)), newline='\n')
            code = '''
. "$1/lib/common.sh"
NH_PLAN=0 NH_TIMEOUT=10 NH_TMP="$2" NH_BROKEN=0 NH_DEADLINE=
nh_cmd cat "$3"
'''
            r = shell(code, ROOT.as_posix(), Path(d).as_posix(), p.as_posix())
            self.assertIn('event-0\n', r.stdout)
            self.assertIn('event-1199\n', r.stdout)
            self.assertEqual(sum(x.startswith('DNS error') for x in r.stdout.splitlines()), 1200)

    def test_parallel_dns_output_grouped_and_transport_arguments_correct(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / 'drill'
            p.write_text('#!/bin/sh\nprintf "fixture-drill args: %s\\n" "$*"\nprintf "fixture-answer\\n"\n', newline='\n')
            p.chmod(0o755)
            # Only items whose external program is this named fixture are executed.
            env = {'PATH': str(Path(d)) + os.pathsep + os.environ.get('PATH', '')}
            r = run('--parallel', '13', '31', env=env)
            self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
            first = r.stdout.index('=== 13 adguard-query ===')
            second = r.stdout.index('=== 31 dns-transport ===')
            self.assertLess(first, second)
            self.assertEqual(r.stdout.count('fixture-answer'), 3)
            self.assertIn('fixture-drill args: -4 -p 53 @127.0.0.1 example.com A', r.stdout)
            self.assertIn('fixture-drill args: -t -4 -p 53 @127.0.0.1 example.com A', r.stdout)
            # Viewing the commands entry must not leave the menu in preview mode.
            interactive = run('--interactive', input='27\n13\nq\n', env=env)
            self.assertEqual(interactive.returncode, 0, interactive.stderr)
            self.assertEqual(interactive.stdout.count('fixture-answer'), 1)

if __name__ == '__main__':
    unittest.main()
