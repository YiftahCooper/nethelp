# 19: conntrack. Help is local metadata; sourcing this file runs no checks.
NH_ID=19
NH_NAME='conntrack'
NH_SUMMARY='Connection-tracking occupancy and error statistics.'
NH_WHEN='New connections fail, especially under load.'
NH_LOOK='Count versus maximum, insert failures and drops; --entries --client IP narrows flows.'
NH_LIMIT='An isolated cumulative counter or many normal connections is not proof of exhaustion.'
nh_run() {
    nh_cmd cat /proc/sys/net/netfilter/nf_conntrack_count /proc/sys/net/netfilter/nf_conntrack_max
    nh_cmd conntrack -S
    if [ "$NH_ENTRIES" = 1 ]; then
      if [ -n "$NH_CLIENT" ]; then nh_cmd conntrack -L -s "$NH_CLIENT"
      else nh_note '[--entries requires --client IP to avoid a full browsing-flow dump]'; NH_BROKEN=1; fi
    fi
}
