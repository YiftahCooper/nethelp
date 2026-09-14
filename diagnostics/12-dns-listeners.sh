# 12: dns-listeners. Help is local metadata; sourcing this file runs no checks.
NH_ID=12
NH_NAME='dns-listeners'
NH_SUMMARY='TCP and UDP listeners plus local DNS processes.'
NH_WHEN='The router is reachable but DNS queries time out.'
NH_LOOK='Listening DNS addresses/ports and AdGuardHome/dnsmasq process presence.'
NH_LIMIT='A listener can be running while upstream DNS is broken.'
nh_run() {
    if [ "$NH_PLAN" = 1 ] || command -v ss >/dev/null 2>&1; then nh_cmd ss -lnutp
    else nh_cmd netstat -lnutp; fi
    nh_cmd pidof AdGuardHome dnsmasq
}
