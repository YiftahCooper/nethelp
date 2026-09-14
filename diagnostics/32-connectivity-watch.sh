# 32: connectivity-watch. Help is local metadata; sourcing this file runs no checks.
NH_ID=32
NH_NAME='connectivity-watch'
NH_SUMMARY='A short, finite timestamped reachability watch.'
NH_WHEN='Catch an intermittent link, route or ping failure while it happens.'
NH_LOOK='Time-correlated snapshots; use --seconds and --interval to choose the observation window.'
NH_LIMIT='A short clean sample does not prove long-term stability or rule out DNS/application faults.'
nh_run() {
    if [ "$NH_PLAN" = 1 ]; then
      nh_cmd date -u; nh_wan; nh_cmd ip "-$NH_FAMILY" route get "$NH_TARGET"; nh_ping "$NH_TARGET"
      nh_note 'Repeated within --seconds, with --interval spacing; no background service.'
      return
    fi
    if [ ! -r /proc/uptime ]; then nh_note '[monotonic uptime unavailable; watch unsupported]'; NH_BROKEN=1; return; fi
    read -r elapsed ignored < /proc/uptime
    NH_DEADLINE=$((${elapsed%%.*} + NH_SECONDS))
    NH_COUNT=1
    while :; do
      read -r elapsed ignored < /proc/uptime
      remaining=$((NH_DEADLINE-${elapsed%%.*}))
      [ "$remaining" -gt 0 ] || break
      [ "$remaining" -ge "$NH_TIMEOUT" ] || NH_TIMEOUT=$remaining
      nh_cmd date -u
      nh_wan
      nh_cmd ip "-$NH_FAMILY" route get "$NH_TARGET"
      nh_ping "$NH_TARGET"
      nh_cmd sleep "$NH_INTERVAL"
    done
}
