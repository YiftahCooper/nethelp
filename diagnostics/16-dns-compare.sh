# 16: dns-compare. Help is local metadata; sourcing this file runs no checks.
NH_ID=16
NH_NAME='dns-compare'
NH_SUMMARY='The same DNS question through system, local, ISP and public paths.'
NH_WHEN='Determine whether DNS failure is local, upstream-specific or widespread.'
NH_LOOK='Consistent question and type, RCODE differences, response time and timeout.'
NH_LIMIT='Firewall interception can redirect external DNS. Different cached answers are not automatically faults.'
nh_run() {
    nh_cmd nslookup "$NH_DOMAIN"
    nh_dns "$NH_RESOLVER" "$NH_DNS_PORT"
    [ -z "$NH_SECONDARY" ] || nh_dns "$NH_SECONDARY" "$NH_SECONDARY_PORT"
    nh_note 'Public comparison destination (may be intercepted locally):'
    nh_dns "$NH_TARGET" 53
    nh_wan || return
    if [ "$NH_PLAN" = 1 ]; then nh_dns '<ISP-advertised-DNS>' 53
    elif [ -f "$NH_TMP/wan.json" ]; then
      nh_capture jsonfilter -i "$NH_TMP/wan.json" -e '@["dns-server"][*]'
      for resolver in $NH_DATA; do nh_dns "$resolver" 53; done
    fi
}
