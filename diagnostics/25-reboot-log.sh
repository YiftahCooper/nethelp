# 25: reboot-log. Help is local metadata; sourcing this file runs no checks.
NH_ID=25
NH_NAME='reboot-log'
NH_SUMMARY='Current boot identity and retained crash/power evidence.'
NH_WHEN='The router rebooted or froze unexpectedly.'
NH_LOOK='Boot time, power flags, panic/OOM/storage messages and available pstore records.'
NH_LIMIT='A NETDEV WATCHDOG is not by itself a system reboot. Lost previous-boot logs stay unknown.'
nh_run() {
    nh_cmd date -u
    nh_cmd uptime
    nh_cmd cat /proc/sys/kernel/random/boot_id
    nh_optional vcgencmd get_throttled
    nh_log_match logread 'under.?voltage|throttl|watchdog|panic|oom|out of memory|EXT4-fs.*error|I/O error'
    nh_log_match dmesg 'under.?voltage|throttl|watchdog|panic|oom|out of memory|EXT4-fs.*error|I/O error'
    if [ "$NH_PLAN" = 1 ]; then nh_cmd cat '/sys/fs/pstore/<available-record>'
    else
      found=0
      for f in /sys/fs/pstore/*; do [ -f "$f" ] || continue; found=1; nh_cmd cat "$f"; done
      [ "$found" = 1 ] || nh_note '[no readable pstore record found; previous crash status unknown]'
    fi
}
