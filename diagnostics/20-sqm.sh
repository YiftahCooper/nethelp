# 20: sqm. Help is local metadata; sourcing this file runs no checks.
NH_ID=20
NH_NAME='sqm'
NH_SUMMARY='Configured SQM instances and all active queueing disciplines.'
NH_WHEN='Latency rises during transfers, or bandwidth shaping looks wrong.'
NH_LOOK='The configured device, qdisc/class backlog, drops, overlimits and IFB ingress shaping.'
NH_LIMIT='AQM drops and shaping overlimits can be normal; they are not NIC receive errors.'
nh_run() {
    nh_optional uci show sqm
    nh_cmd tc -s qdisc show
    if [ "$NH_PLAN" = 1 ]; then nh_cmd tc -s class show dev '<active-qdisc-device>'
    else
      nh_capture tc qdisc show
      devices=$(printf '%s\n' "$NH_DATA" | awk '{for(i=1;i<NF;i++)if($i=="dev")print $(i+1)}' | sort -u)
      for dev in $devices; do nh_cmd tc -s class show dev "$dev"; done
    fi
}
