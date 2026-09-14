# 1: router-status. Help is local metadata; sourcing this file runs no checks.
NH_ID=1
NH_NAME='router-status'
NH_SUMMARY='System time, uptime, resources, power and temperature.'
NH_WHEN='Start here after a reboot, severe slowdown or unexplained outage.'
NH_LOOK='Unexpected boot time, low memory/storage, read-only filesystems, thermal or power flags.'
NH_LIMIT='A clean current boot cannot explain a previous crash whose evidence was lost.'
nh_run() {
    nh_cmd date -u
    nh_cmd uptime
    nh_optional ubus call system board
    nh_cmd cat /proc/sys/kernel/random/boot_id
    nh_cmd cat /proc/meminfo
    nh_cmd df -h
    nh_cmd mount
    nh_cmd ps
    nh_optional vcgencmd get_throttled
    if [ "$NH_PLAN" = 1 ]; then nh_cmd cat '<available-thermal-zone>/temp'
    else
      found=0
      for zone in /sys/class/thermal/thermal_zone*; do
        [ -f "$zone/temp" ] || continue
        found=1; nh_cmd cat "$zone/type" "$zone/temp"
      done
      [ "$found" = 1 ] || nh_note '[temperature sensors unavailable]'
    fi
    nh_log_match logread 'ntp.*(sync|step|error|fail)|clock.*(step|change)|time.*sync'
}
