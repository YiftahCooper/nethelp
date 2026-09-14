# 5: wan-errors. Help is local metadata; sourcing this file runs no checks.
NH_ID=5
NH_NAME='wan-errors'
NH_SUMMARY='WAN counters, receive processing and CPU steering state.'
NH_WHEN='Investigate packet loss or overload, especially under load.'
NH_LOOK='Driver and kernel errors, missed packets and softnet drops; use 21 for changes over time.'
NH_LIMIT='Cumulative counters do not prove errors are happening now.'
nh_run() {
    nh_wan || return
    nh_cmd ip -s link show dev "$NH_DEV"
    nh_cmd ethtool -S "$NH_PHY"
    nh_cmd cat /proc/net/softnet_stat
    nh_cmd cat /proc/interrupts
    nh_optional uci -q get network.globals.packet_steering
    if [ "$NH_PLAN" = 1 ]; then nh_cmd cat '/sys/class/net/<device>/queues/rx-*/rps_cpus'
    else
      for f in /sys/class/net/"$NH_PHY"/queues/rx-*/rps_cpus; do [ ! -f "$f" ] || nh_cmd cat "$f"; done
    fi
}
